import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/domain/entities/user.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_state.dart';
import 'package:forge_gym/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:forge_gym/features/profile/presentation/cubit/profile_state.dart';
import 'package:forge_gym/features/profile/presentation/screens/profile_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileCubit extends Mock implements ProfileCubit {}

class MockAuthCubit extends Mock implements AuthCubit {}

const _user = User(
  id: 'u1',
  name: 'Majid',
  email: 'majid@example.com',
  fitnessLevel: FitnessLevel.intermediate,
);

void main() {
  late MockProfileCubit profileCubit;
  late MockAuthCubit authCubit;

  setUp(() {
    profileCubit = MockProfileCubit();
    authCubit = MockAuthCubit();
    when(
      () => profileCubit.state,
    ).thenReturn(const ProfileState(status: ProfileStatus.loaded, user: _user));
    when(
      () => profileCubit.stream,
    ).thenAnswer((_) => const Stream<ProfileState>.empty());
    when(() => profileCubit.load()).thenAnswer((_) async {});
    when(() => profileCubit.close()).thenAnswer((_) async {});
    when(
      () => authCubit.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.signOut()).thenAnswer((_) async {});
    getIt.registerFactory<ProfileCubit>(() => profileCubit);
    addTearDown(() => getIt.unregister<ProfileCubit>());
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows user identity and sign out button', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Majid'), findsOneWidget);
    expect(find.text('majid@example.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    // Version label degrades to the bare app name when no build info exists.
    expect(find.text('Forge Gym'), findsWidgets);
  });

  testWidgets('tapping sign out delegates to AuthCubit', (tester) async {
    await pumpScreen(tester);

    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    // A confirmation sheet guards the action.
    expect(find.text('Sign out?'), findsOneWidget);
    verifyNever(() => authCubit.signOut());

    await tester.tap(find.text('Yes, sign out'));
    await tester.pumpAndSettle();

    verify(() => authCubit.signOut()).called(1);
  });

  testWidgets('shows error view with retry when load fails', (tester) async {
    when(() => profileCubit.state).thenReturn(
      const ProfileState(
        status: ProfileStatus.error,
        errorMessage: 'Could not load your profile.',
      ),
    );

    await pumpScreen(tester);

    expect(find.text('Could not load your profile.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
