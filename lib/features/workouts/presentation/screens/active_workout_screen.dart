import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/core/utils/formatters.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:forge_gym/features/exercises/presentation/widgets/exercise_video.dart';
import 'package:forge_gym/features/workouts/domain/entities/active_workout.dart';
import 'package:forge_gym/features/workouts/domain/entities/completed_workout.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_session_cubit.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/workout_session_state.dart';
import 'package:go_router/go_router.dart';

/// Live workout session screen.
///
/// Flow: restore a persisted session when possible, otherwise start the
/// requested workout. Completing a set starts the rest timer; when the
/// timer ends the session advances automatically. Everything is persisted
/// on every change, so the session survives app termination.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late final WorkoutSessionCubit _cubit;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<WorkoutSessionCubit>();
    // Ticks the elapsed-time display once per second.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _cubit.initialize().then((_) {
      final session = _cubit.state.session;
      if (!mounted) return;
      if (session == null || session.workoutId != widget.workoutId) {
        _cubit.startWorkout(widget.workoutId);
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<WorkoutSessionCubit, WorkoutSessionState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            context.read<WorkoutSessionCubit>().clearError();
          }
        },
        builder: (context, state) {
          return switch (state.status) {
            WorkoutSessionStatus.initial ||
            WorkoutSessionStatus.loading => Scaffold(
              appBar: AppBar(),
              body: const AppLoadingView(message: 'Preparing your workout…'),
            ),
            WorkoutSessionStatus.finished => _SummaryView(
              completed: state.lastCompleted,
            ),
            WorkoutSessionStatus.active => _ActiveView(state: state),
          };
        },
      ),
    );
  }
}

/// The in-progress session UI.
class _ActiveView extends StatelessWidget {
  const _ActiveView({required this.state});

  final WorkoutSessionState state;

  String _elapsed(DateTime startedAt) {
    final elapsed = DateTime.now().difference(startedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final session = state.session!;
    final exercise = session.currentExercise;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(session.workoutName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Discard workout',
            onPressed: () => _confirmDiscard(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Exercise ${session.currentExerciseIndex + 1}'
                    ' of ${session.exercises.length}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Semantics(
                  label: 'Elapsed workout time',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _elapsed(session.startedAt),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ExerciseDemo(exerciseId: exercise.exerciseId),
            const SizedBox(height: AppSpacing.md),
            Text(exercise.exerciseName, style: AppTextStyles.headline),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Set ${session.currentSetIndex + 1} of ${exercise.targetSets}'
              ' • Target ${exercise.tracking.countLabel(exercise.targetReps)}'
              '${exercise.tracking == TrackingType.bodyweightReps ? ' • Bodyweight' : ''}',
              style: AppTextStyles.body.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SetDots(exercise: exercise),
            if (exercise.completedSetCount > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _LoggedSets(exercise: exercise),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (state.isResting)
              _RestCard(
                restSecondsLeft: state.restSecondsLeft,
                totalSeconds: exercise.restSeconds,
                upNext: _upNext(session),
              )
            else if (exercise.tracking.isTimed)
              _HoldEditor(
                key: ValueKey(
                  'hold_${session.id}_${session.currentExerciseIndex}_${session.currentSetIndex}',
                ),
                exercise: exercise,
              )
            else
              _SetEditor(
                key: ValueKey(
                  '${session.id}_${session.currentExerciseIndex}_${session.currentSetIndex}',
                ),
                exercise: exercise,
                setIndex: session.currentSetIndex,
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: 'Previous',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.medium,
                    onPressed: session.currentExerciseIndex > 0
                        ? () => context
                              .read<WorkoutSessionCubit>()
                              .previousExercise()
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Next',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.medium,
                    onPressed:
                        session.currentExerciseIndex <
                            session.exercises.length - 1
                        ? () =>
                              context.read<WorkoutSessionCubit>().nextExercise()
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => _confirmFinish(context),
                child: const Text('Finish workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What the rest countdown leads into: the next set, the next exercise,
  /// or the finish line.
  static String _upNext(ActiveWorkout session) {
    final exercise = session.currentExercise;
    if (session.currentSetIndex + 1 < exercise.targetSets) {
      return 'Up next: set ${session.currentSetIndex + 2} of '
          '${exercise.targetSets}';
    }
    if (session.currentExerciseIndex + 1 < session.exercises.length) {
      return 'Up next: '
          '${session.exercises[session.currentExerciseIndex + 1].exerciseName}';
    }
    return 'Last set done — the workout finishes after this rest.';
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final cubit = context.read<WorkoutSessionCubit>();
    final discard = await showAppConfirmSheet(
      context,
      title: 'Discard workout?',
      message:
          'Your progress in this session will be lost. This cannot be undone.',
      confirmLabel: 'Discard workout',
      cancelLabel: 'Keep going',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (discard == true) {
      await cubit.discardWorkout();
      if (context.mounted) context.go(AppRoutes.workouts);
    }
  }

  Future<void> _confirmFinish(BuildContext context) async {
    final cubit = context.read<WorkoutSessionCubit>();
    if ((cubit.state.session?.completedSetCount ?? 0) == 0) {
      // Nothing to save: offer to end cleanly rather than write an empty
      // session into history.
      final end = await showAppConfirmSheet(
        context,
        title: 'Nothing logged yet',
        message:
            'Complete at least one set to save this workout to your history, '
            'or end the session without saving.',
        confirmLabel: 'End without saving',
        cancelLabel: 'Keep going',
        icon: Icons.hourglass_empty_rounded,
        destructive: true,
      );
      if (end == true) {
        await cubit.discardWorkout();
        if (context.mounted) context.go(AppRoutes.workouts);
      }
      return;
    }
    final finish = await showAppConfirmSheet(
      context,
      title: 'Finish workout?',
      message: 'Completed sets will be saved to your workout history.',
      confirmLabel: 'Finish workout',
      cancelLabel: 'Keep going',
      icon: Icons.flag_rounded,
    );
    if (finish == true) {
      await cubit.finishWorkout();
    }
  }
}

/// Demo video for the current exercise, falling back to an icon tile when
/// no video is bundled.
class _ExerciseDemo extends StatefulWidget {
  const _ExerciseDemo({required this.exerciseId});

  final String exerciseId;

  @override
  State<_ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<_ExerciseDemo> {
  late Future<Exercise?> _future;

  @override
  void initState() {
    super.initState();
    _future = getIt<ExerciseRepository>().getExerciseById(widget.exerciseId);
  }

  @override
  void didUpdateWidget(covariant _ExerciseDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseId != widget.exerciseId) {
      _future = getIt<ExerciseRepository>().getExerciseById(widget.exerciseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<Exercise?>(
      future: _future,
      builder: (context, snapshot) {
        final videoAsset = snapshot.data?.videoAsset;
        final name = snapshot.data?.name ?? 'Exercise';
        if (videoAsset == null) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              Icons.fitness_center,
              size: 64,
              color: scheme.onSurfaceVariant,
              semanticLabel: '$name demonstration unavailable',
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: ExerciseVideo(
            key: ValueKey(videoAsset),
            exercise: snapshot.data!,
          ),
        );
      },
    );
  }
}

/// Dots showing per-set completion for the current exercise.
class _SetDots extends StatelessWidget {
  const _SetDots({required this.exercise});

  final ActiveExercise exercise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label:
          '${exercise.completedSetCount} of ${exercise.targetSets} sets completed',
      child: Row(
        children: <Widget>[
          for (var i = 0; i < exercise.targetSets; i++)
            Container(
              width: 28,
              height: 8,
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.full),
                color: exercise.sets[i].completed
                    ? AppColors.success
                    : scheme.surfaceContainerHighest,
              ),
            ),
        ],
      ),
    );
  }
}

/// Completed sets for the current exercise, so members can see what they
/// have already logged (and that "Complete set" actually did something).
class _LoggedSets extends StatelessWidget {
  const _LoggedSets({required this.exercise});

  final ActiveExercise exercise;

  static String describe(ActiveSet set, TrackingType tracking) {
    if (tracking.isTimed) return '${set.reps} s';
    return set.weightKg > 0
        ? '${set.reps} × ${Formatters.kg(set.weightKg)}'
        : '${set.reps} reps';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (var i = 0; i < exercise.sets.length; i++)
          if (exercise.sets[i].completed)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Set ${i + 1} · '
                    '${describe(exercise.sets[i], exercise.tracking)}',
                    style: AppTextStyles.caption.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// Reps (+ optional load) editor with the big "Complete set" action.
///
/// Weighted moves show the load stepper; bodyweight moves hide it behind
/// "Add extra weight". Values prefill from the last completed set so a
/// steady lifter only taps "Complete set".
class _SetEditor extends StatefulWidget {
  const _SetEditor({super.key, required this.exercise, required this.setIndex});

  final ActiveExercise exercise;
  final int setIndex;

  @override
  State<_SetEditor> createState() => _SetEditorState();
}

class _SetEditorState extends State<_SetEditor> {
  late int _reps;
  late double _weightKg;
  late bool _showWeight;

  @override
  void initState() {
    super.initState();
    final previous = widget.exercise.lastCompletedSet;
    _reps = previous?.reps ?? widget.exercise.targetReps;
    _weightKg = previous?.weightKg ?? 0;
    _showWeight = widget.exercise.tracking.usesWeight || _weightKg > 0;
  }

  Future<void> _typeReps() async {
    final value = await showAppInputSheet(
      context,
      title: 'Reps done',
      label: 'Reps',
      hint: '${widget.exercise.targetReps}',
      initialValue: '$_reps',
      icon: Icons.repeat_rounded,
      keyboardType: TextInputType.number,
      validator: (text) {
        final parsed = int.tryParse(text);
        return parsed == null || parsed < 1 || parsed > 500
            ? 'Enter reps between 1 and 500.'
            : null;
      },
    );
    if (value != null && mounted) setState(() => _reps = int.parse(value));
  }

  Future<void> _typeWeight() async {
    final value = await showAppInputSheet(
      context,
      title: widget.exercise.tracking.usesWeight
          ? 'Weight used'
          : 'Extra weight',
      label: 'Weight',
      hint: 'e.g. 60',
      suffixText: 'kg',
      initialValue: _weightKg > 0 ? Formatters.number(_weightKg) : '',
      icon: Icons.fitness_center_rounded,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (text) {
        final parsed = double.tryParse(text.replaceAll(',', '.'));
        return parsed == null || parsed < 0 || parsed > 500
            ? 'Enter a weight between 0 and 500 kg.'
            : null;
      },
    );
    if (value != null && mounted) {
      setState(() => _weightKg = double.parse(value.replaceAll(',', '.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final usesWeight = widget.exercise.tracking.usesWeight;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _Stepper(
                  label: 'Reps done',
                  value: '$_reps',
                  hint: 'target ${widget.exercise.targetReps}',
                  onMinus: _reps > 1 ? () => setState(() => _reps--) : null,
                  onPlus: _reps < 500 ? () => setState(() => _reps++) : null,
                  onTapValue: _typeReps,
                ),
              ),
              if (_showWeight) ...<Widget>[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _Stepper(
                    label: usesWeight ? 'Weight (kg)' : 'Extra (kg)',
                    value: Formatters.number(_weightKg),
                    hint: 'tap to type',
                    onMinus: _weightKg > 0
                        ? () => setState(
                            () => _weightKg = (_weightKg - 2.5)
                                .clamp(0, 500)
                                .toDouble(),
                          )
                        : null,
                    onPlus: _weightKg < 500
                        ? () => setState(
                            () => _weightKg = (_weightKg + 2.5)
                                .clamp(0, 500)
                                .toDouble(),
                          )
                        : null,
                    onTapValue: _typeWeight,
                  ),
                ),
              ],
            ],
          ),
          if (!usesWeight)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _showWeight = !_showWeight;
                  if (!_showWeight) _weightKg = 0;
                }),
                icon: Icon(
                  _showWeight ? Icons.close_rounded : Icons.add_rounded,
                  size: 18,
                ),
                label: Text(
                  _showWeight ? 'Remove extra weight' : 'Add extra weight',
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Complete set',
            icon: Icons.check,
            onPressed: () => context.read<WorkoutSessionCubit>().completeSet(
              reps: _reps,
              weightKg: _weightKg,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Logs this set and starts your '
            '${widget.exercise.restSeconds}s rest.',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Countdown editor for timed holds (plank, side plank). Start the clock,
/// hold, and the set completes itself at zero; "Done early" logs the
/// seconds held so far.
class _HoldEditor extends StatefulWidget {
  const _HoldEditor({super.key, required this.exercise});

  final ActiveExercise exercise;

  @override
  State<_HoldEditor> createState() => _HoldEditorState();
}

class _HoldEditorState extends State<_HoldEditor> {
  late int _targetSeconds = widget.exercise.targetReps;
  int _elapsed = 0;
  Timer? _timer;

  bool get _running => _timer != null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed++);
        if (_elapsed >= _targetSeconds) _complete();
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _timer = null);
  }

  void _complete() {
    _timer?.cancel();
    _timer = null;
    final held = _elapsed > 0 ? _elapsed : _targetSeconds;
    context.read<WorkoutSessionCubit>().completeSet(reps: held, weightKg: 0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = (_targetSeconds - _elapsed).clamp(0, 9999);
    final progress = _targetSeconds == 0
        ? 0.0
        : (_elapsed / _targetSeconds).clamp(0.0, 1.0);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _running ? 'HOLD' : 'HOLD FOR',
            style: AppTextStyles.caption.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: '$remaining seconds remaining',
            liveRegion: _running,
            child: Text(
              '${remaining}s',
              style: AppTextStyles.display.copyWith(
                color: scheme.primary,
                fontSize: 48,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!_running && _elapsed == 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.remove),
                  tooltip: 'Decrease hold time',
                  onPressed: _targetSeconds > 5
                      ? () => setState(() => _targetSeconds -= 5)
                      : null,
                ),
                Text(
                  'Target ${_targetSeconds}s',
                  style: AppTextStyles.subtitle,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Increase hold time',
                  onPressed: _targetSeconds < 600
                      ? () => setState(() => _targetSeconds += 5)
                      : null,
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: _running
                      ? 'Pause'
                      : _elapsed == 0
                      ? 'Start hold'
                      : 'Resume',
                  icon: _running ? Icons.pause_rounded : Icons.play_arrow,
                  onPressed: _running ? _pause : _start,
                ),
              ),
              if (_elapsed > 0) ...<Widget>[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: 'Done early',
                    variant: AppButtonVariant.outline,
                    onPressed: _complete,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Large-touch-target stepper. Tapping the value opens a sheet to type an
/// exact number — faster than tapping "+" forty times for 100 kg.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.hint,
    this.onTapValue,
  });

  final String label;
  final String value;
  final String? hint;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final VoidCallback? onTapValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: <Widget>[
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          // Compact buttons + a flexible value box so two steppers fit side
          // by side on a 360 dp phone (48 + 64 + 48 per stepper overflowed).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.remove),
                tooltip: 'Decrease $label',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                onPressed: onMinus,
              ),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 64),
                  child: InkWell(
                    onTap: onTapValue,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                        horizontal: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.6,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: AppTextStyles.title,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Increase $label',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                onPressed: onPlus,
              ),
            ],
          ),
          if (hint != null)
            Text(
              hint!,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

/// Rest countdown overlay shown after each completed set.
class _RestCard extends StatelessWidget {
  const _RestCard({
    required this.restSecondsLeft,
    required this.totalSeconds,
    required this.upNext,
  });

  final int restSecondsLeft;
  final int totalSeconds;
  final String upNext;

  String _format(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        children: <Widget>[
          const Text('REST', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: 'Rest time remaining: $restSecondsLeft seconds',
            liveRegion: true,
            child: SizedBox.square(
              dimension: 148,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      end: totalSeconds <= 0
                          ? 0
                          : (restSecondsLeft / totalSeconds).clamp(0.0, 1.0),
                    ),
                    duration: const Duration(milliseconds: 900),
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary,
                    ),
                  ),
                  Center(
                    child: Text(
                      _format(restSecondsLeft),
                      style: AppTextStyles.display.copyWith(
                        color: scheme.primary,
                        fontSize: 30,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            upNext,
            style: AppTextStyles.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: AppButton(
                  label: '+15 sec',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.medium,
                  onPressed: () =>
                      context.read<WorkoutSessionCubit>().addRest15Seconds(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: 'Skip rest',
                  size: AppButtonSize.medium,
                  onPressed: () =>
                      context.read<WorkoutSessionCubit>().skipRest(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Post-workout summary with the headline numbers.
class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.completed});

  final CompletedWorkout? completed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final workout = completed;
    final exercises = workout?.exercises ?? const <CompletedExercise>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Workout complete')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: <Widget>[
          AppReveal(
            child: AppCelebration(
              child: AppPhotoHero(
                colors: const <Color>[Color(0xFF0E7C5B), Color(0xFF34D399)],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 30,
                        semanticLabel: 'Workout complete',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Session done',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      workout?.workoutName ?? 'Workout',
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Great work. Your stats, streak, challenges and history '
                      'are already up to date.',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppReveal(
            index: 1,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: AppStatTile(
                    icon: Icons.timer_outlined,
                    value: workout == null
                        ? 0
                        : ((workout.durationSeconds + 59) ~/ 60).toDouble(),
                    label: 'Minutes',
                    format: (v) => '${v.round()}',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppStatTile(
                    icon: Icons.repeat_rounded,
                    value: (workout?.totalSets ?? 0).toDouble(),
                    label: 'Sets',
                    format: (v) => '${v.round()}',
                    tint: scheme.tertiary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppStatTile(
                    icon: Icons.scale_outlined,
                    value: workout?.totalVolumeKg ?? 0,
                    label: 'kg lifted',
                    format: Formatters.grouped,
                    tint: scheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          if (exercises.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            const AppReveal(
              index: 2,
              child: AppSectionHeader(
                title: 'What you did',
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppReveal(
              index: 3,
              child: AppCard(
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < exercises.length; i++) ...<Widget>[
                      if (i > 0)
                        Divider(
                          height: AppSpacing.lg,
                          color: scheme.outlineVariant,
                        ),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              exercises[i].exerciseName,
                              style: AppTextStyles.subtitle,
                            ),
                          ),
                          Text(
                            _summary(exercises[i]),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppReveal(
            index: 4,
            child: Column(
              children: <Widget>[
                AppButton(
                  label: 'See my progress',
                  icon: Icons.show_chart_rounded,
                  onPressed: () => context.go(AppRoutes.progress),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Done',
                  variant: AppButtonVariant.text,
                  onPressed: () => context.go(AppRoutes.workouts),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _summary(CompletedExercise exercise) {
    final sets = exercise.sets.length;
    if (exercise.tracking.isTimed) {
      final seconds = exercise.sets.fold<int>(0, (sum, s) => sum + s.reps);
      return '$sets × hold · ${seconds}s';
    }
    final reps = exercise.sets.fold<int>(0, (sum, s) => sum + s.reps);
    final top = exercise.sets.fold<double>(
      0,
      (best, s) => s.weightKg > best ? s.weightKg : best,
    );
    return top > 0
        ? '$sets sets · $reps reps · ${Formatters.kg(top)}'
        : '$sets sets · $reps reps';
  }
}
