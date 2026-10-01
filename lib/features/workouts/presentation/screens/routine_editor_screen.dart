import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/routine_editor_cubit.dart';
import 'package:forge_gym/features/workouts/presentation/cubit/routine_editor_state.dart';
import 'package:go_router/go_router.dart';

/// Create or edit a personal routine: name, notes, and an ordered list of
/// exercises with sets / reps (or seconds) / rest.
class RoutineEditorScreen extends StatelessWidget {
  const RoutineEditorScreen({super.key, this.routineId});

  final String? routineId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RoutineEditorCubit>()..start(routineId: routineId),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickExercise(BuildContext context) async {
    final cubit = context.read<RoutineEditorCubit>();
    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExercisePicker(cubit: cubit),
    );
    if (picked != null) cubit.addExercise(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<RoutineEditorCubit, RoutineEditorState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null ||
          current.status == RoutineEditorStatus.saved,
      listener: (context, state) {
        if (state.status == RoutineEditorStatus.saved && state.savedId != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Routine saved.')));
          context.go(AppRoutes.workoutDetail(state.savedId!));
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<RoutineEditorCubit>();
        if (state.status == RoutineEditorStatus.loading) {
          return Scaffold(
            appBar: AppBar(),
            body: const AppLoadingView(message: 'Loading routine…'),
          );
        }
        if (state.status == RoutineEditorStatus.error) {
          return Scaffold(
            appBar: AppBar(),
            body: AppErrorView(
              message: state.errorMessage ?? 'Something went wrong.',
              retryLabel: 'Back to workouts',
              onRetry: () => context.go(AppRoutes.workouts),
            ),
          );
        }
        if (!_seeded) {
          _seeded = true;
          _name.text = state.name;
          _notes.text = state.notes;
        }
        final saving = state.status == RoutineEditorStatus.saving;
        return Scaffold(
          appBar: AppBar(
            title: Text(state.isEditing ? 'Edit routine' : 'New routine'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              120,
            ),
            children: <Widget>[
              AppTextField(
                controller: _name,
                label: 'Routine name',
                hint: 'e.g. Monday push',
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                onChanged: cubit.setName,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _notes,
                label: 'Notes (optional)',
                hint: 'Goals, cues, how it should feel…',
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                onChanged: cubit.setNotes,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppSectionHeader(
                title: 'Exercises',
                padding: EdgeInsets.zero,
                trailing: Text(
                  state.items.isEmpty
                      ? 'None yet'
                      : '${state.items.length} added',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.items.isEmpty)
                AppCard(
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.playlist_add_rounded,
                        size: 40,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Build your routine',
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Pick exercises from the library and set your own '
                        'sets, reps and rest. Drag to reorder.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: state.items.length,
                  onReorder: cubit.move,
                  itemBuilder: (context, index) => Padding(
                    key: ValueKey<String>(state.items[index].exercise.id),
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ItemCard(
                      index: index,
                      item: state.items[index],
                      onRemove: () => cubit.removeAt(index),
                      onChanged: ({int? sets, int? reps, int? rest}) => cubit
                          .updateItem(
                            index,
                            sets: sets,
                            reps: reps,
                            restSeconds: rest,
                          ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Add exercise',
                icon: Icons.add_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: () => _pickExercise(context),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
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
              child: AppButton(
                label: state.isEditing ? 'Save changes' : 'Save routine',
                icon: Icons.check_rounded,
                isLoading: saving,
                onPressed: state.canSave && !saving ? cubit.save : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.index,
    required this.item,
    required this.onRemove,
    required this.onChanged,
  });

  final int index;
  final RoutineItem item;
  final VoidCallback onRemove;
  final void Function({int? sets, int? reps, int? rest}) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timed = item.exercise.tracking.isTimed;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: scheme.onSurfaceVariant,
                  semanticLabel: 'Drag to reorder',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.asset(
                  item.exercise.thumbnailAsset,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => Container(
                    width: 44,
                    height: 44,
                    color: scheme.surfaceContainerHigh,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  item.exercise.name,
                  style: AppTextStyles.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Remove ${item.exercise.name}',
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _Counter(
                  label: 'Sets',
                  value: item.sets,
                  step: 1,
                  min: 1,
                  max: 10,
                  onChanged: (v) => onChanged(sets: v),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Counter(
                  label: timed ? 'Seconds' : 'Reps',
                  value: item.reps,
                  step: timed ? 5 : 1,
                  min: 1,
                  max: 600,
                  onChanged: (v) => onChanged(reps: v),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _Counter(
                  label: 'Rest s',
                  value: item.restSeconds,
                  step: 15,
                  min: 0,
                  max: 600,
                  onChanged: (v) => onChanged(rest: v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.step,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int step;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            // Three counters share one row on a 360 dp phone (~90 dp
            // each), so the value flexes and the buttons stay compact.
            Row(
              children: <Widget>[
                _MiniButton(
                  icon: Icons.remove,
                  enabled: value - step >= min,
                  onTap: () => onChanged(value - step),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$value',
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                _MiniButton(
                  icon: Icons.add,
                  enabled: value + step <= max,
                  onTap: () => onChanged(value + step),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: SizedBox(
        width: 32,
        height: 36,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? scheme.primary : scheme.outline,
        ),
      ),
    );
  }
}

/// Searchable list of library exercises not yet in the routine.
class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker({required this.cubit});

  final RoutineEditorCubit cubit;

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  String _query = '';
  late Future<List<Exercise>> _future = widget.cubit.availableExercises();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSheet(
      icon: Icons.search_rounded,
      title: 'Add exercise',
      body: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.5,
        child: Column(
          children: <Widget>[
            AppTextField(
              label: 'Search',
              hint: 'e.g. squat, chest…',
              prefixIcon: const Icon(Icons.search),
              autofocus: true,
              onChanged: (value) => setState(() {
                _query = value;
                _future = widget.cubit.availableExercises(query: value);
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<List<Exercise>>(
                future: _future,
                builder: (context, snapshot) {
                  final items = snapshot.data;
                  if (items == null) {
                    return const Center(child: AppLoader(size: 48));
                  }
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? 'Every exercise is already in this routine.'
                            : 'No exercises match “$_query”.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: scheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final exercise = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.asset(
                            exercise.thumbnailAsset,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                            errorBuilder: (_, _, _) => Container(
                              width: 44,
                              height: 44,
                              color: scheme.surfaceContainerHigh,
                            ),
                          ),
                        ),
                        title: Text(exercise.name, style: AppTextStyles.body),
                        subtitle: Text(
                          '${exercise.primaryMuscles.map((m) => m.label).join(', ')}'
                          ' • ${exercise.difficulty.label}',
                          style: AppTextStyles.caption.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Icon(
                          Icons.add_circle_outline_rounded,
                          color: scheme.primary,
                        ),
                        onTap: () => Navigator.of(context).pop(exercise),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        AppButton(
          label: 'Done',
          variant: AppButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
