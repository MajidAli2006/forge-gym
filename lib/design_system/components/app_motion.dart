import 'package:flutter/material.dart';

/// Motion primitives shared by every screen.
///
/// Keep durations short (≤ 400 ms) and curves gentle so the app feels
/// responsive rather than showy. All animations respect the platform's
/// "reduce motion" accessibility setting by collapsing to a plain build.

/// Fades and slides [child] into place once, optionally after [delay].
///
/// Use with an incrementing [AppReveal.index] to stagger a column of
/// sections: each item starts [stagger] later than the previous one.
class AppReveal extends StatefulWidget {
  const AppReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 380),
    this.offset = 18,
  });

  final Widget child;
  final int index;
  final Duration stagger;
  final Duration duration;

  /// Vertical travel in logical pixels.
  final double offset;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delay = widget.stagger * widget.index;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Animates a number from its previous value to [value] and renders it
/// through [format]. Re-animates whenever [value] changes.
class AppCountUp extends StatelessWidget {
  const AppCountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.semanticLabel,
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final Duration duration;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: reduceMotion ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => Text(
        format(animated),
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        semanticsLabel: semanticLabel ?? format(value),
      ),
    );
  }
}

/// Scales [child] down slightly while pressed — a tactile affordance for
/// tappable cards and tiles. Wrap the tappable widget, not its contents.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // A Listener only observes pointer events and never enters the gesture
    // arena, so the press effect can't interfere with a parent scrollable
    // (a tap-down recogniser here was fighting list flings on devices).
    // Taps go through a plain GestureDetector, or the child's own InkWell
    // when [onTap] is null.
    Widget child = AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    );
    if (widget.onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: child,
      );
    }
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      // Scrolling away cancels the press look.
      onPointerMove: (event) {
        if (_pressed && event.delta.distance > 4) _set(false);
      },
      child: child,
    );
  }
}
