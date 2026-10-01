import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercises_cubit.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercises_state.dart';
import 'package:forge_gym/features/exercises/presentation/widgets/exercise_card.dart';
import 'package:go_router/go_router.dart';

/// Exercise library: search + muscle / equipment / difficulty filters
/// above a lazily-built list. The cubit is provided by the route.
class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ExercisesCubit>().state.query,
    );
    context.read<ExercisesCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: BlocBuilder<ExercisesCubit, ExercisesState>(
        builder: (context, state) {
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: AppTextField(
                  controller: _searchController,
                  label: 'Search exercises',
                  hint: 'e.g. bench press, biceps…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: state.query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            context.read<ExercisesCubit>().setQuery('');
                          },
                        )
                      : null,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) =>
                      context.read<ExercisesCubit>().setQuery(value),
                ),
              ),
              _FilterRow(state: state),
              Expanded(child: _Body(state: state)),
            ],
          );
        },
      ),
    );
  }
}

/// Level is always visible as one row; muscle and equipment live in a
/// sheet so they never scroll out of sight, and whatever is applied shows
/// as removable chips under the search box.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state});

  final ExercisesState state;

  int get _sheetCount =>
      (state.muscle != null ? 1 : 0) + (state.equipment != null ? 1 : 0);

  Future<void> _openSheet(BuildContext context) async {
    final cubit = context.read<ExercisesCubit>();
    var muscle = state.muscle;
    var equipment = state.equipment;
    final apply = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => AppSheet(
          icon: Icons.tune_rounded,
          title: 'Filter exercises',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Muscle group', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  AppChip(
                    label: 'Any',
                    selected: muscle == null,
                    onSelected: (_) => setSheetState(() => muscle = null),
                  ),
                  for (final value in MuscleGroup.values)
                    AppChip(
                      label: value.label,
                      selected: muscle == value,
                      onSelected: (_) => setSheetState(
                        () => muscle = muscle == value ? null : value,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Equipment', style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  AppChip(
                    label: 'Any',
                    selected: equipment == null,
                    onSelected: (_) => setSheetState(() => equipment = null),
                  ),
                  for (final value in Equipment.values)
                    AppChip(
                      label: value.label,
                      selected: equipment == value,
                      onSelected: (_) => setSheetState(
                        () => equipment = equipment == value ? null : value,
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            AppButton(
              label: 'Show exercises',
              onPressed: () => Navigator.of(sheetContext).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Clear',
              variant: AppButtonVariant.text,
              onPressed: () {
                muscle = null;
                equipment = null;
                Navigator.of(sheetContext).pop(true);
              },
            ),
          ],
        ),
      ),
    );
    if (apply == true) {
      await cubit.setMuscle(muscle);
      await cubit.setEquipment(equipment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExercisesCubit>();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 48,
          child: Row(
            children: <Widget>[
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: AppSpacing.lg),
                  children: <Widget>[
                    AppChip(
                      label: 'All levels',
                      selected: state.difficulty == null,
                      onSelected: (_) => cubit.setDifficulty(null),
                    ),
                    for (final level in Difficulty.values) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      AppChip(
                        label: level.label,
                        selected: state.difficulty == level,
                        onSelected: (_) => cubit.setDifficulty(
                          state.difficulty == level ? null : level,
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),
              ),
              // Pinned outside the scrolling strip so it is always reachable,
              // whatever the screen width.
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.xs,
                  right: AppSpacing.lg,
                ),
                child: ActionChip(
                  avatar: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: _sheetCount > 0 ? scheme.onPrimary : scheme.primary,
                  ),
                  label: Text(
                    _sheetCount > 0 ? 'Filters · $_sheetCount' : 'Filters',
                  ),
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: _sheetCount > 0 ? scheme.onPrimary : scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: _sheetCount > 0
                      ? scheme.primary
                      : scheme.surfaceContainerLow,
                  side: BorderSide(
                    color: _sheetCount > 0
                        ? Colors.transparent
                        : scheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  onPressed: () => _openSheet(context),
                ),
              ),
            ],
          ),
        ),
        if (state.muscle != null || state.equipment != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              0,
            ),
            child: Wrap(
              spacing: AppSpacing.xs,
              children: <Widget>[
                if (state.muscle != null)
                  InputChip(
                    label: Text(state.muscle!.label),
                    onDeleted: () => cubit.setMuscle(null),
                    deleteButtonTooltipMessage: 'Remove muscle filter',
                  ),
                if (state.equipment != null)
                  InputChip(
                    label: Text(state.equipment!.label),
                    onDeleted: () => cubit.setEquipment(null),
                    deleteButtonTooltipMessage: 'Remove equipment filter',
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final ExercisesState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case ExercisesStatus.initial:
      case ExercisesStatus.loading:
        return AppSkeletonList.rows();
      case ExercisesStatus.error:
        return AppErrorView(
          message: state.errorMessage ?? 'Something went wrong.',
          onRetry: () => context.read<ExercisesCubit>().load(),
        );
      case ExercisesStatus.loaded:
        if (state.exercises.isEmpty) {
          final active = <String>[
            if (state.query.trim().isNotEmpty) '“${state.query.trim()}”',
            if (state.difficulty != null) state.difficulty!.label,
            if (state.muscle != null) state.muscle!.label,
            if (state.equipment != null) state.equipment!.label,
          ];
          return AppEmptyView(
            title: 'No exercises match',
            message: state.hasActiveFilters
                ? 'Nothing matches ${active.join(' + ')}. '
                      'Remove a filter to see more.'
                : 'The exercise library is empty.',
            icon: Icons.fitness_center_outlined,
            actionLabel: state.hasActiveFilters ? 'Clear filters' : null,
            onAction: state.hasActiveFilters
                ? () => context.read<ExercisesCubit>().clearFilters()
                : null,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          itemCount: state.exercises.length,
          itemBuilder: (context, index) {
            final exercise = state.exercises[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ExerciseCard(
                exercise: exercise,
                onTap: () => context.go(AppRoutes.exerciseDetail(exercise.id)),
              ),
            );
          },
        );
    }
  }
}
