import 'package:flutter/material.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/app/routing/app_routes.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/repositories/exercise_repository.dart';
import 'package:go_router/go_router.dart';

/// Every exercise demo as a browsable grid, filterable by muscle group.
/// Tapping a tile opens the exercise, which streams (then caches) the clip.
class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  late final Future<List<Exercise>> _all = getIt<ExerciseRepository>()
      .getExercises();
  MuscleGroup? _muscle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Training videos')),
      body: FutureBuilder<List<Exercise>>(
        future: _all,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return AppSkeletonList.grid();
          }
          final all = snapshot.data!
              .where((e) => e.videoAsset != null)
              .toList();
          final items = _muscle == null
              ? all
              : all
                    .where(
                      (e) =>
                          e.primaryMuscles.contains(_muscle) ||
                          e.secondaryMuscles.contains(_muscle),
                    )
                    .toList();
          return Column(
            children: <Widget>[
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  children: <Widget>[
                    AppChip(
                      label: 'All',
                      selected: _muscle == null,
                      onSelected: (_) => setState(() => _muscle = null),
                    ),
                    for (final muscle in MuscleGroup.values) ...<Widget>[
                      const SizedBox(width: AppSpacing.xs),
                      AppChip(
                        label: muscle.label,
                        selected: _muscle == muscle,
                        onSelected: (_) => setState(
                          () => _muscle = _muscle == muscle ? null : muscle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const AppEmptyView(
                        title: 'No videos here yet',
                        message: 'Try another muscle group.',
                        icon: Icons.videocam_off_outlined,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.xxl,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 0.66,
                            ),
                        itemCount: items.length,
                        itemBuilder: (context, index) => AppReveal(
                          index: index % 6,
                          stagger: const Duration(milliseconds: 40),
                          child: VideoTile(
                            exercise: items[index],
                            onTap: () => context.go(
                              AppRoutes.exerciseDetail(items[index].id),
                            ),
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Each clip downloads once (about 3–5 MB) and is then saved '
                  'on your phone.',
                  style: AppTextStyles.caption.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Thumbnail tile with a play badge; shared by the library grid and the
/// Home "Learn perfect form" carousel.
class VideoTile extends StatelessWidget {
  const VideoTile({super.key, required this.exercise, this.onTap});

  final Exercise exercise;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPressable(
      onTap: onTap,
      child: Semantics(
        label: '${exercise.name} video, ${exercise.difficulty.label}',
        button: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Hero(
                tag: 'exercise-thumb-${exercise.id}',
                child: Image.asset(
                  exercise.thumbnailAsset,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => Container(
                    color: scheme.surfaceContainerHigh,
                    child: Icon(
                      Icons.fitness_center,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, Colors.black87],
                    stops: <double>[0.45, 1],
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
                    exercise.difficulty.label,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.emberLight,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Text(
                  exercise.name,
                  style: AppTextStyles.subtitle.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
