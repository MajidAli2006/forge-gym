import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/theme/app_colors.dart';

/// A one-shot confetti burst drawn behind [child]. Used on the
/// workout-complete screen. No package: ~70 particles on a CustomPainter,
/// skipped entirely under reduced motion.
class AppCelebration extends StatefulWidget {
  const AppCelebration({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final Duration duration;

  @override
  State<AppCelebration> createState() => _AppCelebrationState();
}

class _AppCelebrationState extends State<AppCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final List<_Particle> _particles = _seed(math.Random(7));

  static List<_Particle> _seed(math.Random random) {
    const colours = <Color>[
      AppColors.emberDark,
      AppColors.emberLight,
      AppColors.success,
      AppColors.warning,
      Color(0xFF7C3AED),
      Colors.white,
    ];
    return List<_Particle>.generate(70, (i) {
      final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.1;
      final speed = 0.55 + random.nextDouble() * 0.75;
      return _Particle(
        origin: Offset(0.2 + random.nextDouble() * 0.6, 0.55),
        velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
        colour: colours[i % colours.length],
        size: 5 + random.nextDouble() * 6,
        spin: (random.nextDouble() - 0.5) * 10,
        delay: random.nextDouble() * 0.15,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _ConfettiPainter(_particles, _controller.value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  const _Particle({
    required this.origin,
    required this.velocity,
    required this.colour,
    required this.size,
    required this.spin,
    required this.delay,
  });

  final Offset origin;
  final Offset velocity;
  final Color colour;
  final double size;
  final double spin;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final paint = Paint();
    for (final p in particles) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final gravity = 1.4 * local * local;
      final x = p.origin.dx * size.width + p.velocity.dx * local * size.width;
      final y =
          p.origin.dy * size.height +
          (p.velocity.dy * local + gravity) * size.height * 0.6;
      final fade = (1 - local).clamp(0.0, 1.0);
      paint.color = p.colour.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
