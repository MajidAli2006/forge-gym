import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workouts_cubit.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workouts_state.dart';
import 'package:forge_gym/features/workouts/presentation/widgets/workout_card.dart';
import 'package:go_router/go_router.dart';

/// Workout catalogue: the member's own routines first, then the gym's plans.
class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WorkoutsCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Workouts')),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'new-routine',
          onPressed: () => context.go(AppRoutes.newRoutine),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New routine'),
        ),
        body: BlocBuilder<WorkoutsCubit, WorkoutsState>(
          builder: (context, state) {
            return switch (state.status) {
              WorkoutsStatus.initial ||
              WorkoutsStatus.loading => AppSkeletonList.cards(),
              WorkoutsStatus.error => AppErrorView(
                message: state.errorMessage ?? 'Something went wrong.',
                onRetry: () => context.read<WorkoutsCubit>().load(),
              ),
              WorkoutsStatus.loaded => _Catalogue(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _Catalogue extends StatelessWidget {
  const _Catalogue({required this.state});

  final WorkoutsState state;

  @override
  Widget build(BuildContext context) {
    final routines = state.routines;
    final plans = state.plans;
    var index = 0;
    Widget card(Workout workout) {
      final i = index++;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppReveal(
          index: i,
          stagger: const Duration(milliseconds: 50),
          child: WorkoutCard(
            workout: workout,
            coverAsset: state.covers[workout.id],
            onTap: () => context.go(AppRoutes.workoutDetail(workout.id)),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        96,
      ),
      children: <Widget>[
        AppSectionHeader(
          title: 'My routines',
          padding: EdgeInsets.zero,
          trailing: routines.isEmpty
              ? null
              : Text(
                  '${routines.length}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (routines.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: _RoutinesEmpty(),
          )
        else
          ...routines.map(card),
        const SizedBox(height: AppSpacing.md),
        const AppSectionHeader(title: 'Gym plans', padding: EdgeInsets.zero),
        const SizedBox(height: AppSpacing.md),
        if (plans.isEmpty)
          const AppEmptyView(
            icon: Icons.fitness_center_outlined,
            title: 'No plans yet',
            message: 'Workout plans will appear here.',
          )
        else
          ...plans.map(card),
      ],
    );
  }
}

/// Invitation to build the first routine ("your diary").
class _RoutinesEmpty extends StatelessWidget {
  const _RoutinesEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () => context.go(AppRoutes.newRoutine),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.edit_note_rounded, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Build your own routine',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 2),
                Text(
                  'Pick exercises, set your sets, reps and rest, then train '
                  'it like any plan. Progress is tracked the same way.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
