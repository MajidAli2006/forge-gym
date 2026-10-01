import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:go_router/go_router.dart';

/// Full-bleed photo header for the auth screens, used in place of a plain
/// app bar. Carries the wordmark, a title/subtitle, and an optional back
/// arrow (which pops, or falls back to [backTo]).
class AuthHero extends StatelessWidget implements PreferredSizeWidget {
  const AuthHero({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageAsset = 'assets/exercises/bench-press-barbell/thumb.jpg',
    this.backTo,
    this.height = 232,
  });

  final String title;
  final String subtitle;
  final String imageAsset;

  /// Route to go to when the back arrow is tapped and nothing can be
  /// popped. Null hides the arrow.
  final String? backTo;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: height + topInset,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.3),
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: AppColors.ink800),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x66000000), Color(0xCC0C0D10)],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.emberDark,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'FORGE GYM',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  style: AppTextStyles.display.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (backTo != null)
            Positioned(
              top: topInset + AppSpacing.xs,
              left: AppSpacing.xs,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(backTo!);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
