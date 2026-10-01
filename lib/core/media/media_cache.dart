import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// On-demand media store.
///
/// Demo clips are not shipped inside the APK (they would add well over
/// 100 MB). Each clip is downloaded from the environment's media host the
/// first time it is needed and kept in the app's support directory, so the
/// second open is instant and works offline.
///
/// Paths are relative, e.g. `exercises/plank/demo.mp4`, and map 1:1 to
/// `<baseUrl>/<path>` remotely and `<support dir>/media/<path>` locally.
/// Turns a relative media path into a downloadable URL.
typedef MediaUrlResolver = Future<String> Function(String path);

class MediaCache {
  MediaCache({
    required Dio dio,
    required String baseUrl,
    Directory? root,
    MediaUrlResolver? urlResolver,
  }) : _dio = dio,
       _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _root = root,
       _resolveUrl = urlResolver;

  final Dio _dio;
  final String _baseUrl;
  final MediaUrlResolver? _resolveUrl;

  Future<String> _urlFor(String path) =>
      _resolveUrl?.call(path) ?? Future.value('$_baseUrl/$path');

  /// Storage root; resolved from the app support directory unless injected
  /// (tests).
  Directory? _root;
  final Map<String, Future<File>> _inFlight = <String, Future<File>>{};
  final Map<String, ValueNotifier<double>> _progress =
      <String, ValueNotifier<double>>{};

  Future<Directory> _dir() async {
    var root = _root;
    if (root == null) {
      final support = await getApplicationSupportDirectory();
      root = Directory('${support.path}/media');
      _root = root;
    }
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<File> _fileFor(String path) async =>
      File('${(await _dir()).path}/$path');

  /// The cached file for [path], or null when it has not been downloaded.
  Future<File?> cached(String path) async {
    final file = await _fileFor(path);
    if (!await file.exists()) return null;
    return await file.length() > 0 ? file : null;
  }

  /// 0..1 download progress for [path]; stays at 1 once cached.
  ValueListenable<double> progressOf(String path) =>
      _progress.putIfAbsent(path, () => ValueNotifier<double>(0));

  /// Returns the local file, downloading it first when needed. Concurrent
  /// callers for the same path share a single download.
  Future<File> fetch(String path) {
    return _inFlight.putIfAbsent(path, () {
      final download = _download(path);
      // Block body on purpose: `whenComplete` waits for any Future its
      // callback returns, and `Map.remove` returns the in-flight Future
      // itself — an arrow body here would make a failed download wait on
      // itself forever.
      return download.whenComplete(() {
        _inFlight.remove(path);
      });
    });
  }

  /// A download that receives no bytes for this long is abandoned so the
  /// UI can offer a retry. Dio's connect timeout does not cover a hanging
  /// DNS lookup or a server that accepts the socket and then stalls.
  static const Duration stallTimeout = Duration(seconds: 20);

  Future<File> _download(String path) async {
    final existing = await cached(path);
    final notifier = _progress.putIfAbsent(
      path,
      () => ValueNotifier<double>(0),
    );
    if (existing != null) {
      notifier.value = 1;
      return existing;
    }
    final file = await _fileFor(path);
    await file.parent.create(recursive: true);
    // Download to a temp name so a half-finished file is never mistaken
    // for a complete clip after a crash or lost connection.
    final partial = File('${file.path}.part');
    notifier.value = 0;

    final cancel = CancelToken();
    Timer? watchdog;
    void resetWatchdog() {
      watchdog?.cancel();
      watchdog = Timer(stallTimeout, () {
        if (!cancel.isCancelled) {
          cancel.cancel('No data received for ${stallTimeout.inSeconds}s');
        }
      });
    }

    resetWatchdog();
    try {
      final url = await _urlFor(path);
      debugPrint('[MediaCache] downloading $url');
      await _dio.download(
        url,
        partial.path,
        cancelToken: cancel,
        onReceiveProgress: (received, total) {
          resetWatchdog();
          if (total > 0) notifier.value = received / total;
        },
      );
      await partial.rename(file.path);
      notifier.value = 1;
      return file;
    } catch (error) {
      debugPrint('[MediaCache] download failed for $path: $error');
      if (await partial.exists()) await partial.delete();
      notifier.value = 0;
      rethrow;
    } finally {
      watchdog?.cancel();
    }
  }

  /// Removes one cached clip (and any partial download) so the next fetch
  /// downloads it again. Used when a cached file turns out unplayable.
  Future<void> evict(String path) async {
    final file = await _fileFor(path);
    for (final candidate in <File>[file, File('${file.path}.part')]) {
      if (await candidate.exists()) await candidate.delete();
    }
    _progress[path]?.value = 0;
  }

  /// Total bytes held on the device.
  Future<int> sizeBytes() async {
    final root = await _dir();
    var total = 0;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Deletes every downloaded clip (they re-download on next open).
  Future<void> clear() async {
    final root = await _dir();
    if (await root.exists()) await root.delete(recursive: true);
    for (final notifier in _progress.values) {
      notifier.value = 0;
    }
  }
}

/// Dio instance tuned for large file downloads (no JSON headers, long
/// receive timeout).
Dio createMediaDio() => Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 5),
  ),
);
