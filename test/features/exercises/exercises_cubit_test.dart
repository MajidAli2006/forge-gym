import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/usecases/get_exercise_by_id_usecase.dart';
import 'package:forge_gym/features/exercises/domain/usecases/get_exercises_usecase.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercise_detail_cubit.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercise_detail_state.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercises_cubit.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercises_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetExercisesUseCase extends Mock implements GetExercisesUseCase {}

class _MockGetExerciseByIdUseCase extends Mock
    implements GetExerciseByIdUseCase {}

const _exercise = Exercise(
  id: 'push-up',
  name: 'Push Up',
  description: 'Bodyweight press.',
  instructions: ['Lower', 'Press'],
  primaryMuscles: [MuscleGroup.chest],
  secondaryMuscles: [MuscleGroup.triceps],
  equipment: Equipment.bodyweight,
  difficulty: Difficulty.beginner,
  thumbnailAsset: 'assets/exercises/push-up/thumb.jpg',
  commonMistakes: ['Sagging hips'],
  tips: ['Stay tight'],
  defaultSets: 3,
  defaultReps: 15,
  defaultRestSeconds: 60,
);

void main() {
  group('ExercisesCubit', () {
    late _MockGetExercisesUseCase useCase;

    setUp(() {
      useCase = _MockGetExercisesUseCase();
      when(
        () => useCase.call(
          query: any(named: 'query'),
          muscle: any(named: 'muscle'),
          equipment: any(named: 'equipment'),
          difficulty: any(named: 'difficulty'),
        ),
      ).thenAnswer((_) async => [_exercise]);
    });

    blocTest<ExercisesCubit, ExercisesState>(
      'load emits loading then loaded with exercises',
      build: () => ExercisesCubit(useCase),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ExercisesState(status: ExercisesStatus.loading),
        const ExercisesState(
          status: ExercisesStatus.loaded,
          exercises: [_exercise],
        ),
      ],
    );

    blocTest<ExercisesCubit, ExercisesState>(
      'load emits error when the use case throws',
      build: () {
        when(
          () => useCase.call(
            query: any(named: 'query'),
            muscle: any(named: 'muscle'),
            equipment: any(named: 'equipment'),
            difficulty: any(named: 'difficulty'),
          ),
        ).thenThrow(Exception('boom'));
        return ExercisesCubit(useCase);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const ExercisesState(status: ExercisesStatus.loading),
        predicate<ExercisesState>(
          (s) =>
              s.status == ExercisesStatus.error &&
              s.errorMessage != null &&
              s.errorMessage!.isNotEmpty,
        ),
      ],
    );

    blocTest<ExercisesCubit, ExercisesState>(
      'setMuscle stores the filter and re-queries',
      build: () => ExercisesCubit(useCase),
      act: (cubit) => cubit.setMuscle(MuscleGroup.chest),
      expect: () => [
        predicate<ExercisesState>((s) => s.muscle == MuscleGroup.chest),
        predicate<ExercisesState>(
          (s) =>
              s.muscle == MuscleGroup.chest &&
              s.status == ExercisesStatus.loaded &&
              s.exercises.length == 1,
        ),
      ],
      verify: (_) {
        verify(
          () => useCase.call(
            query: any(named: 'query'),
            muscle: MuscleGroup.chest,
            equipment: any(named: 'equipment'),
            difficulty: any(named: 'difficulty'),
          ),
        ).called(1);
      },
    );

    blocTest<ExercisesCubit, ExercisesState>(
      'clearFilters resets every filter',
      build: () => ExercisesCubit(useCase),
      seed: () => const ExercisesState(
        status: ExercisesStatus.loaded,
        query: 'push',
        muscle: MuscleGroup.chest,
        equipment: Equipment.bodyweight,
        difficulty: Difficulty.beginner,
      ),
      act: (cubit) => cubit.clearFilters(),
      expect: () => [
        predicate<ExercisesState>(
          (s) =>
              !s.hasActiveFilters &&
              s.query.isEmpty &&
              s.muscle == null &&
              s.equipment == null &&
              s.difficulty == null,
        ),
        predicate<ExercisesState>(
          (s) => !s.hasActiveFilters && s.status == ExercisesStatus.loaded,
        ),
      ],
    );

    test('hasActiveFilters reflects query and selections', () {
      expect(const ExercisesState().hasActiveFilters, isFalse);
      expect(const ExercisesState(query: 'x').hasActiveFilters, isTrue);
      expect(
        const ExercisesState(muscle: MuscleGroup.back).hasActiveFilters,
        isTrue,
      );
    });
  });

  group('ExerciseDetailCubit', () {
    late _MockGetExerciseByIdUseCase useCase;

    setUp(() {
      useCase = _MockGetExerciseByIdUseCase();
    });

    blocTest<ExerciseDetailCubit, ExerciseDetailState>(
      'loadById emits loading then loaded',
      build: () {
        when(() => useCase.call('push-up')).thenAnswer((_) async => _exercise);
        return ExerciseDetailCubit(useCase);
      },
      act: (cubit) => cubit.loadById('push-up'),
      expect: () => [
        const ExerciseDetailState(status: ExerciseDetailStatus.loading),
        const ExerciseDetailState(
          status: ExerciseDetailStatus.loaded,
          exercise: _exercise,
        ),
      ],
    );

    blocTest<ExerciseDetailCubit, ExerciseDetailState>(
      'loadById emits notFound for unknown ids',
      build: () {
        when(() => useCase.call('nope')).thenAnswer((_) async => null);
        return ExerciseDetailCubit(useCase);
      },
      act: (cubit) => cubit.loadById('nope'),
      expect: () => [
        const ExerciseDetailState(status: ExerciseDetailStatus.loading),
        const ExerciseDetailState(status: ExerciseDetailStatus.notFound),
      ],
    );
  });
}
