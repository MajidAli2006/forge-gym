import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';

/// First screen. Kicks off session restore, then the router's auth gate
/// moves on to onboarding, login, or home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Post-frame so the cubit read doesn't run during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthCubit>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary, scheme.primaryContainer],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: scheme.onPrimary,
                  semanticLabel: 'Forge Gym logo',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'FORGE GYM',
                style: AppTextStyles.display.copyWith(
                  color: scheme.onPrimary,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Train with purpose',
                style: AppTextStyles.subtitle.copyWith(
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: AppSpacing.xl * 2),
              AppLoader(size: 56, color: scheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
