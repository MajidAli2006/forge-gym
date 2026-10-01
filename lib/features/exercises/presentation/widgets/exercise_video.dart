import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart' show ValueListenable, debugPrint;
import 'package:flutter/material.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/core/media/media_cache.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';

/// Demo clip for an exercise, fetched on demand.
///
/// Shows the thumbnail immediately, downloads the clip in the background
/// the first time (with progress), then plays it from the device cache.
/// Offline members still get the thumbnail and the written steps.
class ExerciseVideo extends StatefulWidget {
  const ExerciseVideo({
    super.key,
    required this.exercise,
    this.autoDownload = true,
    this.maxHeight = 320,
  });

  final Exercise exercise;

  /// Start downloading as soon as the widget appears (default). Pass false
  /// to require a tap — useful in lists where clips shouldn't all fetch.
  final bool autoDownload;
  final double maxHeight;

  @override
  State<ExerciseVideo> createState() => _ExerciseVideoState();
}

enum _Phase { checking, idle, downloading, ready, failed }

class _ExerciseVideoState extends State<ExerciseVideo> {
  late final MediaCache _cache = getIt<MediaCache>();
  _Phase _phase = _Phase.checking;
  File? _file;

  /// One automatic re-download is allowed when a cached clip fails to
  /// play (truncated or corrupt file); after that the retry UI takes over.
  bool _healed = false;

  String? get _path => widget.exercise.videoAsset;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final path = _path;
    if (path == null) {
      setState(() => _phase = _Phase.idle);
      return;
    }
    final cached = await _cache.cached(path);
    if (!mounted) return;
    if (cached != null) {
      setState(() {
        _file = cached;
        _phase = _Phase.ready;
      });
      return;
    }
    if (widget.autoDownload) {
      await _download();
    } else {
      setState(() => _phase = _Phase.idle);
    }
  }

  Future<void> _download() async {
    final path = _path;
    if (path == null) return;
    setState(() => _phase = _Phase.downloading);
    try {
      final file = await _cache.fetch(path);
      if (!mounted) return;
      setState(() {
        _file = file;
        _phase = _Phase.ready;
      });
    } catch (error) {
      debugPrint('[ExerciseVideo] download failed for $path: $error');
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  Future<void> _onPlaybackError(Object error) async {
    final path = _path;
    if (path == null || !mounted) return;
    debugPrint('[ExerciseVideo] cached clip unplayable ($error); evicting');
    await _cache.evict(path);
    if (!mounted) return;
    if (_healed) {
      setState(() {
        _file = null;
        _phase = _Phase.failed;
      });
      return;
    }
    _healed = true;
    setState(() => _file = null);
    await _download();
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (_phase == _Phase.ready && file != null) {
      return AppVideoPlayer(
        key: ValueKey<String>(file.path),
        filePath: file.path,
        posterAssetPath: widget.exercise.thumbnailAsset,
        maxHeight: widget.maxHeight,
        semanticLabel: '${widget.exercise.name} demonstration video',
        onError: _onPlaybackError,
      );
    }
    return _Poster(
      exercise: widget.exercise,
      maxHeight: widget.maxHeight,
      child: switch (_phase) {
        _Phase.checking => const SizedBox.shrink(),
        _Phase.downloading => _DownloadProgress(
          listenable: _cache.progressOf(_path!),
        ),
        _Phase.failed => _Retry(onRetry: _download),
        _Phase.idle when _path != null => _DownloadButton(onTap: _download),
        _Phase.idle || _Phase.ready => const SizedBox.shrink(),
      },
    );
  }
}

/// Thumbnail in the same letterboxed frame the player uses, so the switch
/// from poster to video doesn't jump.
class _Poster extends StatelessWidget {
  const _Poster({
    required this.exercise,
    required this.maxHeight,
    required this.child,
  });

  final Exercise exercise;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${exercise.name} photo',
      child: Container(
        height: maxHeight,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Image.asset(
                exercise.thumbnailAsset,
                fit: BoxFit.cover,
                color: Colors.black54,
                colorBlendMode: BlendMode.darken,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Hero(
                  tag: 'exercise-thumb-${exercise.id}',
                  child: Image.asset(
                    exercise.thumbnailAsset,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.fitness_center,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.25)),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.listenable});

  final ValueListenable<double> listenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: listenable,
      builder: (context, value, _) {
        final determinate = value > 0 && value < 1;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox.square(
              dimension: 56,
              child: CircularProgressIndicator(
                value: determinate ? value : null,
                strokeWidth: 4,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              determinate
                  ? 'Downloading demo · ${(value * 100).round()}%'
                  : 'Downloading demo…',
              style: AppTextStyles.subtitle.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Saved on your phone after the first time.',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 36),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Couldn\'t download the demo',
            style: AppTextStyles.subtitle.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Check your connection and try again. The written steps below '
            'work offline.',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            size: AppButtonSize.medium,
            expanded: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Download demo',
      icon: Icons.download_rounded,
      size: AppButtonSize.medium,
      expanded: false,
      onPressed: onTap,
    );
  }
}
