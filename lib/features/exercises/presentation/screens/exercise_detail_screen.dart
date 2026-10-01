import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercise_detail_cubit.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercise_detail_state.dart';
import 'package:forge_gym/features/exercises/presentation/widgets/exercise_video.dart';
import 'package:forge_gym/features/exercises/presentation/widgets/safety_disclaimer.dart';
import 'package:go_router/go_router.dart';

/// Full exercise guidance: demo video (or thumbnail fallback), target
/// muscles, written steps, mistakes, tips, and recommended volume.
/// The cubit is provided by the route with the exercise id.
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExerciseDetailCubit>().loadById(widget.exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: BlocBuilder<ExerciseDetailCubit, ExerciseDetailState>(
        builder: (context, state) {
          switch (state.status) {
            case ExerciseDetailStatus.initial:
            case ExerciseDetailStatus.loading:
              return const AppLoadingView(message: 'Loading exercise…');
            case ExerciseDetailStatus.error:
              return AppErrorView(
                message: 'Could not load this exercise.',
                onRetry: () => context.read<ExerciseDetailCubit>().loadById(
                  widget.exerciseId,
                ),
              );
            case ExerciseDetailStatus.notFound:
              return const AppEmptyView(
                title: 'Exercise not found',
                message: 'This exercise may have been removed.',
                icon: Icons.search_off_outlined,
              );
            case ExerciseDetailStatus.loaded:
              return _DetailBody(exercise: state.exercise!);
          }
        },
      ),
      bottomNavigationBar:
          BlocBuilder<ExerciseDetailCubit, ExerciseDetailState>(
            builder: (context, state) {
              final exercise = state.exercise;
              if (state.status != ExerciseDetailStatus.loaded ||
                  exercise == null) {
                return const SizedBox.shrink();
              }
              return _LogBar(exercise: exercise);
            },
          ),
    );
  }
}

/// Sticky footer: log one set right here, or go and start a full plan.
/// Pure UI — validation of the typed values happens here, persistence
/// and messaging live in [ExerciseDetailCubit].
class _LogBar extends StatelessWidget {
  const _LogBar({required this.exercise});

  final Exercise exercise;

  Future<void> _openLogSheet(BuildContext context) async {
    final cubit = context.read<ExerciseDetailCubit>();
    final timed = exercise.tracking.isTimed;
    final usesWeight = exercise.tracking.usesWeight;
    final countController = TextEditingController(
      text: '${exercise.defaultReps}',
    );
    final weightController = TextEditingController();
    String? countError;
    String? weightError;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => AppSheet(
          icon: Icons.add_task_rounded,
          title: 'Log a set',
          message: timed
              ? 'How long did you hold the ${exercise.name.toLowerCase()}?'
              : 'How many reps of ${exercise.name.toLowerCase()} did you do?',
          body: Column(
            children: <Widget>[
              AppTextField(
                controller: countController,
                label: timed ? 'Seconds held' : 'Reps',
                suffixText: timed ? 's' : null,
                errorText: countError,
                keyboardType: TextInputType.number,
                autofocus: true,
                textInputAction: usesWeight
                    ? TextInputAction.next
                    : TextInputAction.done,
                onChanged: (_) {
                  if (countError != null) {
                    setSheetState(() => countError = null);
                  }
                },
              ),
              if (usesWeight) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: weightController,
                  label: 'Weight',
                  hint: 'Optional, e.g. 20',
                  suffixText: 'kg',
                  errorText: weightError,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) {
                    if (weightError != null) {
                      setSheetState(() => weightError = null);
                    }
                  },
                ),
              ],
            ],
          ),
          actions: <Widget>[
            AppButton(
              label: 'Save set',
              icon: Icons.check_rounded,
              onPressed: () {
                final count = int.tryParse(countController.text.trim());
                // Weight is optional: a blank field means bodyweight / 0 kg.
                final weight = _parseWeight(weightController.text);
                var ok = true;
                if (count == null || count <= 0) {
                  countError = timed
                      ? 'Enter the seconds you held.'
                      : 'Enter the reps you did.';
                  ok = false;
                }
                if (usesWeight &&
                    (weight == null || weight < 0 || weight > 500)) {
                  weightError = 'Enter a weight between 0 and 500 kg.';
                  ok = false;
                }
                if (!ok) {
                  setSheetState(() {});
                  return;
                }
                Navigator.of(sheetContext).pop(true);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.of(sheetContext).pop(false),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await cubit.logSet(
      count: int.parse(countController.text.trim()),
      weightKg: usesWeight ? (_parseWeight(weightController.text) ?? 0) : 0,
    );
  }

  /// Blank → 0 kg; otherwise a number (comma or dot decimal) or null when
  /// the text isn't numeric.
  static double? _parseWeight(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return 0;
    return double.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<ExerciseDetailCubit, ExerciseDetailState>(
      listenWhen: (previous, current) =>
          current.logMessage != null || current.logError != null,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
        if (state.logMessage != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.logMessage!),
              action: SnackBarAction(
                label: 'View',
                onPressed: () => context.go(AppRoutes.progress),
              ),
            ),
          );
        } else if (state.logError != null) {
          messenger.showSnackBar(SnackBar(content: Text(state.logError!)));
        }
      },
      builder: (context, state) {
        final canLog = context.read<ExerciseDetailCubit>().canLogSets;
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: <Widget>[
                if (canLog) ...<Widget>[
                  Expanded(
                    child: AppButton(
                      label: 'Log a set',
                      icon: Icons.add_task_rounded,
                      size: AppButtonSize.medium,
                      isLoading: state.isLogging,
                      onPressed: state.isLogging
                          ? null
                          : () => _openLogSheet(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: AppButton(
                    label: 'Plans',
                    icon: Icons.fitness_center_rounded,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.medium,
                    onPressed: () => context.go(AppRoutes.workouts),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final videoAsset = exercise.videoAsset;
    var reveal = 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: <Widget>[
        if (videoAsset != null)
          ExerciseVideo(exercise: exercise)
        else
          Image.asset(
            exercise.thumbnailAsset,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: '${exercise.name} photo',
            errorBuilder: (context, _, _) => Container(
              height: 220,
              color: scheme.surfaceContainerHigh,
              child: Icon(
                Icons.fitness_center,
                size: 64,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppReveal(
                index: reveal++,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(exercise.name, style: AppTextStyles.headline),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        _Pill(
                          icon: Icons.signal_cellular_alt_rounded,
                          label: exercise.difficulty.label,
                          colour: scheme.primary,
                        ),
                        _Pill(
                          icon: Icons.fitness_center_rounded,
                          label: exercise.equipment.label,
                          colour: scheme.tertiary,
                        ),
                        for (final muscle in exercise.primaryMuscles)
                          _Pill(
                            icon: Icons.accessibility_new_rounded,
                            label: muscle.label,
                            colour: scheme.secondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      exercise.description,
                      style: AppTextStyles.body.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppReveal(
                index: reveal++,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: AppStatTile(
                        icon: Icons.repeat_rounded,
                        value: exercise.defaultSets.toDouble(),
                        label: 'Sets',
                        format: (v) => '${v.round()}',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppStatTile(
                        icon: exercise.tracking.isTimed
                            ? Icons.timer_rounded
                            : Icons.numbers_rounded,
                        value: exercise.defaultReps.toDouble(),
                        label: exercise.tracking.isTimed ? 'Sec hold' : 'Reps',
                        format: (v) => '${v.round()}',
                        tint: scheme.tertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppStatTile(
                        icon: Icons.hourglass_bottom_rounded,
                        value: exercise.defaultRestSeconds.toDouble(),
                        label: 'Sec rest',
                        format: (v) => '${v.round()}',
                        tint: scheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (exercise.secondaryMuscles.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                AppReveal(
                  index: reveal++,
                  child: Text(
                    'Also works: '
                    '${exercise.secondaryMuscles.map((m) => m.label).join(', ')}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppReveal(
                index: reveal++,
                child: const AppSectionHeader(
                  title: 'How to perform',
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < exercise.instructions.length; i++)
                AppReveal(
                  index: reveal++,
                  stagger: const Duration(milliseconds: 40),
                  child: _StepCard(
                    number: i + 1,
                    text: exercise.instructions[i],
                    isLast: i == exercise.instructions.length - 1,
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              AppReveal(
                index: reveal++,
                child: _AdviceCard(
                  title: 'Watch out for',
                  icon: Icons.warning_amber_rounded,
                  colour: AppColors.warning,
                  items: exercise.commonMistakes,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppReveal(
                index: reveal++,
                child: _AdviceCard(
                  title: 'Coach\'s tips',
                  icon: Icons.lightbulb_outline_rounded,
                  colour: AppColors.success,
                  items: exercise.tips,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SafetyDisclaimer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.colour});

  final IconData icon;
  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: colour),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: colour,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One numbered instruction with a connector line to the next step.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.text,
    required this.isLast,
  });

  final int number;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 32,
            child: Column(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        AppColors.emberDark,
                        AppColors.emberLight,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: AppTextStyles.subtitle.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 5,
                bottom: isLast ? 0 : AppSpacing.lg,
              ),
              child: Text(text, style: AppTextStyles.body),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.title,
    required this.icon,
    required this.colour,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color colour;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 20, color: colour),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(title, style: AppTextStyles.subtitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colour,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
