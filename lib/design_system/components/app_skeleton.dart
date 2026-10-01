import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';

/// Shimmering placeholder blocks shown while a screen loads, so the layout
/// appears instantly and fills in rather than flashing a spinner. Pure
/// Flutter (no shimmer package): one animated gradient sweeps every
/// [AppSkeletonBox] under an [AppShimmer].
class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              scheme.surfaceContainerHighest,
              scheme.surfaceContainerHigh.withValues(alpha: 0.35),
              scheme.surfaceContainerHighest,
            ],
            stops: <double>[
              (t * 1.6 - 0.6).clamp(0.0, 1.0),
              (t * 1.6 - 0.3).clamp(0.0, 1.0),
              (t * 1.6).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// A rounded placeholder block. Size it like the content it stands in for.
class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Ready-made skeleton layouts matching the app's list screens.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList._(this._builder);

  final Widget Function(BuildContext) _builder;

  /// Tall cards with a cover image (workouts, challenges).
  factory AppSkeletonList.cards({int count = 3, double coverHeight = 150}) =>
      AppSkeletonList._(
        (context) => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, _) => _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppSkeletonBox(
                  height: coverHeight,
                  width: double.infinity,
                  radius: 0,
                ),
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppSkeletonBox(width: 180, height: 20),
                      SizedBox(height: AppSpacing.sm),
                      AppSkeletonBox(width: 120),
                      SizedBox(height: AppSpacing.xs),
                      AppSkeletonBox(width: 90, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  /// Rows with a thumbnail on the left (exercise library).
  factory AppSkeletonList.rows({int count = 5}) => AppSkeletonList._(
    (context) => ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, _) => const _Card(
        child: SizedBox(
          height: 132,
          child: Row(
            children: <Widget>[
              AppSkeletonBox(width: 118, height: 132, radius: 0),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppSkeletonBox(width: 160, height: 18),
                      SizedBox(height: AppSpacing.sm),
                      AppSkeletonBox(width: 90, height: 12),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: <Widget>[
                          AppSkeletonBox(
                            width: 72,
                            height: 22,
                            radius: AppRadius.full,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          AppSkeletonBox(
                            width: 84,
                            height: 22,
                            radius: AppRadius.full,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Hero block, a tile row, then section cards (home, progress, profile).
  factory AppSkeletonList.dashboard() => AppSkeletonList._(
    (context) => ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      children: const <Widget>[
        AppSkeletonBox(
          height: 200,
          width: double.infinity,
          radius: AppRadius.xl,
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(child: AppSkeletonBox(height: 120, radius: AppRadius.lg)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: AppSkeletonBox(height: 120, radius: AppRadius.lg)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: AppSkeletonBox(height: 120, radius: AppRadius.lg)),
          ],
        ),
        SizedBox(height: AppSpacing.xxl),
        AppSkeletonBox(width: 140, height: 22),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBox(
          height: 150,
          width: double.infinity,
          radius: AppRadius.lg,
        ),
        SizedBox(height: AppSpacing.xxl),
        AppSkeletonBox(width: 120, height: 22),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBox(
          height: 96,
          width: double.infinity,
          radius: AppRadius.lg,
        ),
      ],
    ),
  );

  /// Two-column poster grid (video library).
  factory AppSkeletonList.grid({int count = 6}) => AppSkeletonList._(
    (context) => GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.66,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const AppSkeletonBox(radius: AppRadius.lg),
    ),
  );

  @override
  Widget build(BuildContext context) =>
      AppShimmer(child: Builder(builder: _builder));
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }
}
