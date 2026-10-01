import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';

/// First-run carousel over full-bleed gym photography. Completing (or
/// skipping) it persists the onboarding flag; the router then moves to
/// login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages =
      <({String image, IconData icon, String title, String subtitle})>[
        (
          image: 'assets/exercises/squat-barbell/thumb.jpg',
          icon: Icons.fitness_center_rounded,
          title: 'Train with purpose',
          subtitle:
              'Structured plans for every level, from your first session to '
              'heavy compound lifts.',
        ),
        (
          image: 'assets/exercises/leg-press/thumb.jpg',
          icon: Icons.show_chart_rounded,
          title: 'Track every rep',
          subtitle:
              'Log sets, weights and holds in seconds. Streaks, volume and '
              'challenges update themselves.',
        ),
        (
          image: 'assets/exercises/plank/thumb.jpg',
          icon: Icons.play_circle_outline_rounded,
          title: 'Learn perfect form',
          subtitle:
              'A demo video and step-by-step cues for all 52 exercises, '
              'saved on your phone once watched.',
        ),
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => context.read<AuthCubit>().completeOnboarding();

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.ink900,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) => _Page(page: _pages[index]),
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: TextButton(
                        onPressed: isLast ? null : _finish,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.only(right: AppSpacing.xs),
                            width: _page == index ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _page == index
                                  ? AppColors.emberDark
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: isLast ? 'Get started' : 'Next',
                        icon: isLast ? Icons.bolt_rounded : null,
                        onPressed: () {
                          if (isLast) {
                            _finish();
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.page});

  final ({String image, IconData icon, String title, String subtitle}) page;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          page.image,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.2),
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.ink800),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x33000000),
                Color(0x66000000),
                Color(0xF20C0D10),
              ],
              stops: <double>[0, 0.45, 0.85],
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          bottom: 148,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.emberDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  page.icon,
                  color: Colors.white,
                  size: 28,
                  semanticLabel: page.title,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                page.title,
                style: AppTextStyles.display.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                page.subtitle,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
