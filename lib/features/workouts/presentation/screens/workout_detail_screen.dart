import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/workouts/domain/entities/workout.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_detail_cubit.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_detail_state.dart';
import 'package:go_router/go_router.dart';

/// Workout plan detail: description, meta, exercise list, start button.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WorkoutDetailCubit>()..loadById(workoutId),
      child: BlocConsumer<WorkoutDetailCubit, WorkoutDetailState>(
        listenWhen: (previous, current) =>
            current.status == WorkoutDetailStatus.deleted ||
            (current.errorMessage != null &&
                current.status == WorkoutDetailStatus.loaded),
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar();
          if (state.status == WorkoutDetailStatus.deleted) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Routine deleted.')),
            );
            context.go(AppRoutes.workouts);
          } else if (state.errorMessage != null) {
            messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          return switch (state.status) {
            WorkoutDetailStatus.initial ||
            WorkoutDetailStatus.loading ||
            WorkoutDetailStatus.deleted => Scaffold(
              appBar: AppBar(),
              body: const AppLoadingView(message: 'Loading workout…'),
            ),
            WorkoutDetailStatus.error => Scaffold(
              appBar: AppBar(),
              body: AppErrorView(
                message: state.errorMessage ?? 'Something went wrong.',
                onRetry: () =>
                    context.read<WorkoutDetailCubit>().loadById(workoutId),
              ),
            ),
            WorkoutDetailStatus.loaded => _DetailBody(
              workout: state.workout!,
              coverAsset: state.coverAsset,
            ),
          };
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.workout, this.coverAsset});

  final Workout workout;
  final String? coverAsset;

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<WorkoutDetailCubit>();
    final confirmed = await showAppConfirmSheet(
      context,
      title: 'Delete this routine?',
      message:
          '“${workout.name}” will be removed from your routines. Workouts '
          'you already completed with it stay in your history.',
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed ?? false) await cubit.deleteRoutine();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        actions: <Widget>[
          if (workout.isCustom) ...<Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit routine',
              onPressed: () => context.go(AppRoutes.editRoutine(workout.id)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete routine',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[AppColors.emberDark, AppColors.emberLight],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (coverAsset != null)
                    Hero(
                      tag: 'workout-cover-${workout.id}',
                      child: Image.asset(
                        coverAsset!,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.3),
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    )
                  else
                    const Icon(
                      Icons.fitness_center,
                      size: 72,
                      color: Colors.white54,
                      semanticLabel: 'Workout illustration',
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.transparent, Colors.black54],
                        stops: <double>[0.4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: Text(
                      workout.description,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      AppChip(label: workout.difficulty.label),
                      AppChip(label: '${workout.durationMinutes} min'),
                      AppChip(
                        label:
                            '${workout.exerciseCount} exercise${workout.exerciseCount == 1 ? '' : 's'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Targets: ${workout.targetMuscles.map((m) => m.label).join(', ')}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppSectionHeader(
              title: 'Exercises',
              trailing: Text(
                'Tap a row for demo & tips',
                style: AppTextStyles.caption.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...workout.exercises.map((item) => _ExerciseRow(item: item)),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppButton(
            label: 'Start workout',
            icon: Icons.play_arrow,
            onPressed: () => context.go(AppRoutes.activeWorkout(workout.id)),
          ),
        ),
      ),
    );
  }
}

/// One exercise row: name resolved from the library, plus the prescription.
class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.item});

  final WorkoutExercise item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<Exercise?>(
      future: getIt<ExerciseRepository>().getExerciseById(item.exerciseId),
      builder: (context, snapshot) {
        final exercise = snapshot.data;
        final name = exercise?.name ?? item.exerciseId;
        final tracking = exercise?.tracking ?? TrackingType.weightedReps;
        return ListTile(
          onTap: exercise == null
              ? null
              : () => context.go(AppRoutes.exerciseDetail(exercise.id)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 52,
              height: 52,
              child: exercise == null
                  ? ColoredBox(
                      color: scheme.primaryContainer,
                      child: Icon(
                        Icons.fitness_center,
                        color: scheme.onPrimaryContainer,
                      ),
                    )
                  : Image.asset(
                      exercise.thumbnailAsset,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: scheme.primaryContainer,
                        child: Icon(
                          Icons.fitness_center,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
            ),
          ),
          title: Text(name, style: AppTextStyles.body),
          subtitle: Text(
            '${item.sets} sets × ${tracking.countLabel(item.reps)}'
            ' • Rest ${item.restSeconds}s',
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${item.order + 1}',
                style: AppTextStyles.title.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                semanticsLabel: 'Exercise ${item.order + 1}',
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.info_outline_rounded,
                color: scheme.onSurfaceVariant,
                semanticLabel: 'Exercise demo and tips',
              ),
            ],
          ),
        );
      },
    );
  }
}
