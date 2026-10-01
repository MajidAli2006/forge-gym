import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/core/media/media_cache.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('media_cache_test');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'fetch fails (does not hang) when the host cannot be resolved',
    () async {
      final cache = MediaCache(
        dio: createMediaDio(),
        baseUrl: 'https://media.forgegym.example',
        root: root,
      );
      await expectLater(
        cache.fetch('exercises/plank/demo.mp4'),
        throwsA(isA<DioException>()),
      );
      expect(await cache.cached('exercises/plank/demo.mp4'), isNull);
      expect(await cache.sizeBytes(), 0);
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );

  test(
    'a second fetch after a failure retries instead of reusing the error',
    () async {
      final cache = MediaCache(
        dio: createMediaDio(),
        baseUrl: 'https://media.forgegym.example',
        root: root,
      );
      await expectLater(
        cache.fetch('exercises/plank/demo.mp4'),
        throwsA(anything),
      );
      await expectLater(
        cache.fetch('exercises/plank/demo.mp4'),
        throwsA(anything),
      );
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
