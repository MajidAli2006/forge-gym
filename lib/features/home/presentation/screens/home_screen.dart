import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/core/utils/formatters.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/challenges/presentation/widgets/challenge_card.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/presentation/screens/video_library_screen.dart';
import 'package:forge_gym/features/home/domain/entities/announcement.dart';
import 'package:forge_gym/features/home/presentation/cubit/home_cubit.dart';
import 'package:forge_gym/features/home/presentation/cubit/home_state.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:go_router/go_router.dart';

/// Training dashboard: today's session, quick actions, weekly stats,
/// challenges, recommended plans, demo videos, and gym announcements.
///
/// The screen only provides the [HomeCubit]; [_HomeView] renders state.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..load(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forge Gym')),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return switch (state.status) {
            HomeStatus.initial ||
            HomeStatus.loading => AppSkeletonList.dashboard(),
            HomeStatus.error => AppErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: () => context.read<HomeCubit>().load(),
            ),
            HomeStatus.loaded => _Dashboard(state: state),
          };
        },
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    var reveal = 0;
    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xxxl,
        ),
        children: <Widget>[
          AppReveal(
            index: reveal++,
            child: _Hero(state: state),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppReveal(index: reveal++, child: const _QuickActions()),
          if (state.weeklySummary != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            AppReveal(
              index: reveal++,
              child: _ThisWeek(state: state),
            ),
          ],
          if (state.challenges.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            AppReveal(
              index: reveal++,
              child: _Challenges(state: state),
            ),
          ],
          if (state.recommended.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            AppReveal(
              index: reveal++,
              child: _Recommended(state: state),
            ),
          ],
          if (state.featuredExercises.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            AppReveal(
              index: reveal++,
              child: _Videos(exercises: state.featuredExercises),
            ),
          ],
          if (state.recentExercises.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            AppReveal(
              index: reveal++,
              child: _RecentlyUsed(exercises: state.recentExercises),
            ),
          ],
          if (state.announcements.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            AppReveal(
              index: reveal++,
              child: _Announcements(announcements: state.announcements),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.state});

  final HomeState state;

  static String greetingFor(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final today = state.todayWorkout;
    final cover = today != null ? state.workoutCovers[today.id] : null;
    final resumable = state.hasResumableWorkout;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Semantics(
        label: resumable
            ? 'Continue your in-progress workout'
            : today != null
            ? "Today's workout: ${today.name}"
            : 'Browse workouts',
        explicitChildNodes: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.emberLight.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: cover != null
                      ? Image.asset(
                          cover,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.3),
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        )
                      : const SizedBox.shrink(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          AppColors.emberDark.withValues(
                            alpha: cover != null ? 0.72 : 1,
                          ),
                          AppColors.emberLight.withValues(
                            alpha: cover != null ? 0.86 : 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${greetingFor(DateTime.now())}, ${state.userName}',
                        style: AppTextStyles.headline.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        resumable
                            ? 'You have a session in progress.'
                            : 'Ready to train today?',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (resumable)
                        _HeroAction(
                          caption: 'IN PROGRESS',
                          title: 'Continue workout',
                          meta: 'Pick up where you left off',
                          buttonLabel: 'Resume',
                          icon: Icons.play_arrow_rounded,
                          onTap: () => context.go(AppRoutes.resumeWorkout),
                        )
                      else if (today != null)
                        _HeroAction(
                          caption: "TODAY'S WORKOUT",
                          title: today.name,
                          meta:
                              '${today.durationMinutes} min • '
                              '${today.difficulty.label} • '
                              '${today.exerciseCount} exercises',
                          buttonLabel: 'Start workout',
                          icon: Icons.play_arrow_rounded,
                          onTap: () =>
                              context.go(AppRoutes.workoutDetail(today.id)),
                        )
                      else
                        _HeroAction(
                          caption: 'GET STARTED',
                          title: 'Pick a plan',
                          meta: 'Eight plans from beginner to advanced',
                          buttonLabel: 'Browse workouts',
                          icon: Icons.fitness_center_rounded,
                          onTap: () => context.go(AppRoutes.workouts),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.caption,
    required this.title,
    required this.meta,
    required this.buttonLabel,
    required this.icon,
    required this.onTap,
  });

  final String caption;
  final String title;
  final String meta;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            caption,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTextStyles.title.copyWith(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            meta,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.emberLight,
                minimumSize: const Size(64, 48),
              ),
              icon: Icon(icon),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: <Widget>[
          _QuickAction(
            icon: Icons.fitness_center_rounded,
            label: 'Workouts',
            tint: scheme.primary,
            onTap: () => context.go(AppRoutes.workouts),
          ),
          const SizedBox(width: AppSpacing.sm),
          _QuickAction(
            icon: Icons.list_alt_rounded,
            label: 'Exercises',
            tint: scheme.tertiary,
            onTap: () => context.go(AppRoutes.exercises),
          ),
          const SizedBox(width: AppSpacing.sm),
          _QuickAction(
            icon: Icons.play_circle_fill_rounded,
            label: 'Videos',
            tint: const Color(0xFF7C3AED),
            onTap: () => context.go(AppRoutes.videoLibrary),
          ),
          const SizedBox(width: AppSpacing.sm),
          _QuickAction(
            icon: Icons.emoji_events_rounded,
            label: 'Challenges',
            tint: AppColors.warning,
            onTap: () => context.go(AppRoutes.challenges),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppPressable(
        onTap: onTap,
        child: AppCard(
          semanticLabel: label,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: tint),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// This week
// ---------------------------------------------------------------------------

class _ThisWeek extends StatelessWidget {
  const _ThisWeek({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.weeklySummary!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: 'This week',
          actionLabel: 'Details',
          onAction: () => context.go(AppRoutes.progress),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: <Widget>[
              Expanded(
                child: AppStatTile(
                  icon: Icons.fitness_center_rounded,
                  value: summary.workoutsThisWeek.toDouble(),
                  label: 'Workouts',
                  format: (v) => '${v.round()}',
                  semanticLabel:
                      '${summary.workoutsThisWeek} workouts this week',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppStatTile(
                  icon: Icons.local_fire_department_rounded,
                  value: summary.currentStreakDays.toDouble(),
                  label: 'Day streak',
                  format: (v) => '${v.round()}',
                  tint: AppColors.warning,
                  semanticLabel: '${summary.currentStreakDays} day streak',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppStatTile(
                  icon: Icons.timer_outlined,
                  value: summary.totalMinutes.toDouble(),
                  label: 'Minutes',
                  format: (v) => '${v.round()}',
                  tint: Theme.of(context).colorScheme.tertiary,
                  semanticLabel: '${summary.totalMinutes} minutes trained',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Challenges
// ---------------------------------------------------------------------------

class _Challenges extends StatelessWidget {
  const _Challenges({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final hasActive = state.challenges.any((c) => c.isActive);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: hasActive ? 'Your challenges' : 'Challenges',
          actionLabel: 'See all',
          onAction: () => context.go(AppRoutes.challenges),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: state.challenges.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) => SizedBox(
              width: 280,
              child: ChallengeCard(
                progress: state.challenges[index],
                compact: true,
                onTap: () => context.go(AppRoutes.challenges),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recommended workouts
// ---------------------------------------------------------------------------

class _Recommended extends StatelessWidget {
  const _Recommended({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: 'Recommended plans',
          actionLabel: 'See all',
          onAction: () => context.go(AppRoutes.workouts),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: state.recommended.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) => _WorkoutPoster(
              workout: state.recommended[index],
              cover: state.workoutCovers[state.recommended[index].id],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutPoster extends StatelessWidget {
  const _WorkoutPoster({required this.workout, this.cover});

  final Workout workout;
  final String? cover;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: () => context.go(AppRoutes.workoutDetail(workout.id)),
      child: Semantics(
        label: 'Workout: ${workout.name}, ${workout.difficulty.label}',
        button: true,
        child: SizedBox(
          width: 236,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (cover != null)
                  Image.asset(
                    cover!,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.3),
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  )
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          AppColors.emberDark,
                          AppColors.emberLight,
                        ],
                      ),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[Colors.transparent, Colors.black87],
                      stops: <double>[0.3, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      workout.difficulty.label,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        workout.name,
                        style: AppTextStyles.subtitle.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${workout.durationMinutes} min • '
                        '${workout.exerciseCount} exercises',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Videos
// ---------------------------------------------------------------------------

class _Videos extends StatelessWidget {
  const _Videos({required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: 'Learn perfect form',
          actionLabel: 'All videos',
          onAction: () => context.go(AppRoutes.videoLibrary),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: exercises.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) => SizedBox(
              width: 136,
              child: VideoTile(
                exercise: exercises[index],
                onTap: () =>
                    context.go(AppRoutes.exerciseDetail(exercises[index].id)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recently used
// ---------------------------------------------------------------------------

class _RecentlyUsed extends StatelessWidget {
  const _RecentlyUsed({required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: 'Recently used'),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: <Widget>[
              for (final exercise in exercises) ...<Widget>[
                AppChip(
                  label: exercise.name,
                  onSelected: (_) =>
                      context.go(AppRoutes.exerciseDetail(exercise.id)),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Announcements
// ---------------------------------------------------------------------------

class _Announcements extends StatelessWidget {
  const _Announcements({required this.announcements});

  final List<Announcement> announcements;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: 'From the gym'),
        const SizedBox(height: AppSpacing.sm),
        for (final announcement in announcements)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppCard(
              semanticLabel: 'Announcement: ${announcement.title}',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.campaign_outlined,
                      size: 22,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                announcement.title,
                                style: AppTextStyles.subtitle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              Formatters.relativeDate(announcement.date),
                              style: AppTextStyles.caption.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          announcement.body,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
