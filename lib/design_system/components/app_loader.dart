import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';
import 'package:forge_gym/design_system/theme/app_colors.dart';
import 'package:forge_gym/design_system/typography/app_text_styles.dart';

/// Branded loader: two counter-rotating ember arcs around a gently pulsing
/// dumbbell. Replaces the stock circular spinner everywhere. Collapses to a
/// static glyph when the OS asks for reduced motion.
class AppLoader extends StatefulWidget {
  const AppLoader({super.key, this.size = 72, this.message, this.color});

  final double size;
  final String? message;

  /// Arc/glyph colour; defaults to the theme primary. Pass white on
  /// gradient backgrounds such as the splash screen.
  final Color? color;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = widget.color ?? scheme.primary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) _controller.stop();
    return Semantics(
      label: widget.message ?? 'Loading',
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox.square(
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final pulse = 0.92 + 0.08 * math.sin(t * math.pi * 2);
                return CustomPaint(
                  painter: _ArcsPainter(
                    progress: t,
                    outer: tint,
                    inner: widget.color == null
                        ? AppColors.emberDark
                        : tint.withValues(alpha: 0.7),
                    track: tint.withValues(alpha: 0.18),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: pulse,
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: widget.size * 0.36,
                        color: tint,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.message != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.message!,
              style: AppTextStyles.bodySmall.copyWith(
                color: widget.color ?? scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ArcsPainter extends CustomPainter {
  const _ArcsPainter({
    required this.progress,
    required this.outer,
    required this.inner,
    required this.track,
  });

  final double progress;
  final Color outer;
  final Color inner;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outerRect = rect.deflate(size.width * 0.06);
    final innerRect = rect.deflate(size.width * 0.2);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07;
    canvas.drawArc(outerRect, 0, math.pi * 2, false, trackPaint);

    final outerPaint = Paint()
      ..color = outer
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;
    final innerPaint = Paint()
      ..color = inner.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    final outerStart = progress * math.pi * 2;
    final sweep = math.pi * 0.9 * (0.6 + 0.4 * math.sin(progress * math.pi));
    canvas.drawArc(outerRect, outerStart, sweep, false, outerPaint);
    canvas.drawArc(
      innerRect,
      -progress * math.pi * 2 + math.pi,
      math.pi * 0.6,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcsPainter old) => old.progress != progress;
}
