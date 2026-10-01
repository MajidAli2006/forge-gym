import 'package:forge_gym/features/challenges/data/datasources/challenge_local_datasource.dart';
import 'package:forge_gym/features/challenges/data/models/challenge_dto.dart';
import 'package:forge_gym/features/exercises/data/datasources/exercise_local_datasource.dart';
import 'package:forge_gym/features/exercises/data/models/exercise_dto.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/home/data/datasources/announcement_local_datasource.dart';
import 'package:forge_gym/features/home/data/models/announcement_dto.dart';
import 'package:forge_gym/features/workouts/data/datasources/workout_local_datasource.dart';
import 'package:forge_gym/features/workouts/data/models/workout_dto.dart';

/// In-memory fakes for the asset-backed local data sources.
///
/// Widget tests run in `flutter_tester`, where `rootBundle` asset loading
/// does not resolve (the channel never answers), so any screen that loads
/// the bundled mock JSON would spin its loading indicator forever and
/// `pumpAndSettle` would time out. The data-source abstractions exist
/// precisely for this substitution, so integration-style widget tests swap
/// the asset implementations for these fakes. Image assets referenced by the
/// DTOs simply don't resolve in tests; the widgets render without them.
class FakeExerciseLocalDataSource implements ExerciseLocalDataSource {
  @override
  Future<List<ExerciseDto>> loadExercises() async {
    return const [
      ExerciseDto(
        id: 'push-up',
        name: 'Push Up',
        description: 'Bodyweight press.',
        instructions: ['Lower your chest', 'Press back up'],
        primaryMuscles: ['chest'],
        secondaryMuscles: ['triceps'],
        equipment: 'bodyweight',
        difficulty: 'beginner',
        thumbnailAsset: 'assets/exercises/push-up/thumb.jpg',
        commonMistakes: ['Sagging hips'],
        tips: ['Stay tight'],
        defaultSets: 3,
        defaultReps: 15,
        defaultRestSeconds: 60,
      ),
      ExerciseDto(
        id: 'goblet-squat',
        name: 'Goblet Squat',
        description: 'Dumbbell squat.',
        instructions: ['Hold the dumbbell at your chest', 'Squat down'],
        primaryMuscles: ['legs'],
        secondaryMuscles: ['glutes'],
        equipment: 'dumbbell',
        difficulty: 'beginner',
        thumbnailAsset: 'assets/exercises/goblet-squat/thumb.jpg',
        commonMistakes: ['Knees caving in'],
        tips: ['Keep chest up'],
        defaultSets: 3,
        defaultReps: 12,
        defaultRestSeconds: 90,
      ),
    ];
  }
}

class FakeWorkoutLocalDataSource implements WorkoutLocalDataSource {
  @override
  Future<List<WorkoutDto>> loadWorkouts() async {
    return const [
      WorkoutDto(
        id: 'full-body-a',
        name: 'Full Body A',
        description: 'Test workout plan.',
        difficulty: Difficulty.beginner,
        durationMinutes: 45,
        targetMuscles: [MuscleGroup.fullBody],
        exercises: [
          WorkoutExerciseDto(
            exerciseId: 'push-up',
            sets: 3,
            reps: 15,
            restSeconds: 60,
            order: 0,
          ),
        ],
      ),
    ];
  }
}

class FakeAnnouncementLocalDataSource implements AnnouncementLocalDataSource {
  @override
  Future<List<AnnouncementDto>> loadAnnouncements() async {
    return [
      AnnouncementDto(
        id: 'a1',
        title: 'Welcome',
        body: 'Test announcement.',
        date: DateTime(2026, 9, 30),
      ),
    ];
  }
}

class FakeChallengeLocalDataSource implements ChallengeLocalDataSource {
  @override
  Future<List<ChallengeDto>> loadChallenges() async {
    return const [
      ChallengeDto(
        id: 'first-steps',
        title: 'First Steps',
        tagline: 'Finish 3 workouts in 2 weeks',
        description: 'Test challenge.',
        icon: 'flag',
        metric: 'workouts',
        target: 3,
        durationDays: 14,
        difficulty: 'beginner',
      ),
    ];
  }
}
