import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/exercises/domain/entities/exercise.dart';
import 'package:forge_gym/features/exercises/domain/usecases/get_exercise_by_id_usecase.dart';
import 'package:forge_gym/features/exercises/presentation/cubit/exercise_detail_cubit.dart';
import 'package:forge_gym/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:forge_gym/features/exercises/presentation/widgets/exercise_card.dart';
import 'package:forge_gym/features/exercises/presentation/widgets/safety_disclaimer.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetExerciseByIdUseCase extends Mock
    implements GetExerciseByIdUseCase {}

const _exercise = Exercise(
  id: 'push-up',
  name: 'Push Up',
  description: 'Bodyweight press.',
  instructions: ['Lower your chest', 'Press back up'],
  primaryMuscles: [MuscleGroup.chest],
  secondaryMuscles: [MuscleGroup.triceps],
  equipment: Equipment.bodyweight,
  difficulty: Difficulty.beginner,
  thumbnailAsset: 'assets/exercises/push-up/thumb.jpg',
  // No video asset: the detail screen must fall back to the thumbnail.
  commonMistakes: ['Sagging hips'],
  tips: ['Stay tight'],
  defaultSets: 3,
  defaultReps: 15,
  defaultRestSeconds: 60,
);

Widget _themed(Widget child) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('ExerciseCard', () {
    testWidgets('shows name, muscles, equipment, and difficulty', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _themed(ExerciseCard(exercise: _exercise, onTap: () => tapped = true)),
      );

      expect(find.text('Push Up'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Bodyweight'), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);

      await tester.tap(find.byType(ExerciseCard));
      expect(tapped, isTrue);
    });

    testWidgets('exposes an accessible label', (tester) async {
      // Semantics are disabled by default in widget tests; enable them so
      // the semantics tree (and bySemanticsLabel) is populated.
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_themed(const ExerciseCard(exercise: _exercise)));

      expect(
        find.bySemanticsLabel('Push Up. Beginner. Bodyweight.'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('ExerciseDetailScreen', () {
    late _MockGetExerciseByIdUseCase useCase;

    setUp(() {
      useCase = _MockGetExerciseByIdUseCase();
      when(() => useCase.call('push-up')).thenAnswer((_) async => _exercise);
    });

    Future<void> pumpDetail(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: BlocProvider(
            create: (_) => ExerciseDetailCubit(useCase),
            child: const ExerciseDetailScreen(exerciseId: 'push-up'),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders video fallback, sections, and safety disclaimer', (
      tester,
    ) async {
      await pumpDetail(tester);

      expect(find.text('Push Up'), findsWidgets);
      expect(find.text('Sets'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('How to perform'), findsOneWidget);
      // Written steps are numbered, not hidden behind the video.
      expect(find.text('Lower your chest'), findsOneWidget);
      // Lower sections sit below the fold in the test viewport; scroll them
      // into view before asserting, mirroring real user behaviour.
      await tester.scrollUntilVisible(find.text('Watch out for'), 400);
      expect(find.text('Sagging hips'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Coach\'s tips'), 400);
      expect(find.text('Stay tight'), findsOneWidget);
      // The standing safety note is always present.
      expect(find.byType(SafetyDisclaimer), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('general informational purposes'),
        400,
      );
      expect(
        find.textContaining('general informational purposes'),
        findsOneWidget,
      );
    });

    testWidgets('shows thumbnail fallback when no video asset', (tester) async {
      await pumpDetail(tester);

      // No AppVideoPlayer is built; the thumbnail image is shown instead.
      expect(find.byType(AppVideoPlayer), findsNothing);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
