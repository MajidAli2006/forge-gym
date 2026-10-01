import 'package:flutter/material.dart';
import 'package:forge_gym/design_system/spacing/app_spacing.dart';
import 'package:forge_gym/design_system/theme/app_colors.dart';

/// Rounded hero card: an optional photo under the brand gradient, with the
/// ember glow shadow. Used at the top of dashboards (progress, profile) so
/// the whole app shares one hero language with Home and the auth screens.
class AppPhotoHero extends StatelessWidget {
  const AppPhotoHero({
    super.key,
    required this.child,
    this.imageAsset,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.colors = const <Color>[AppColors.emberDark, AppColors.emberLight],
    this.imageAlignment = const Alignment(0, -0.3),
  });

  final Widget child;
  final String? imageAsset;
  final EdgeInsetsGeometry padding;
  final List<Color> colors;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    final image = imageAsset;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.last.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: <Widget>[
            if (image != null)
              Positioned.fill(
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  alignment: imageAlignment,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      colors.first.withValues(alpha: image != null ? 0.74 : 1),
                      colors.last.withValues(alpha: image != null ? 0.88 : 1),
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
