import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_gym/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:forge_gym/features/auth/domain/usecases/auth_usecases.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_state.dart';
import 'package:forge_gym/features/auth/presentation/screens/login_screen.dart';

import 'test_helpers.dart';

void main() {
  late AuthCubit cubit;

  setUp(() {
    final repository = MockAuthRepository(FakeAuthLocalDataSource());
    cubit = AuthCubit(
      repository: repository,
      signInUseCase: SignInUseCase(repository),
      signUpUseCase: SignUpUseCase(repository),
      signOutUseCase: SignOutUseCase(repository),
      sendPasswordResetUseCase: SendPasswordResetUseCase(repository),
      updateProfileUseCase: UpdateProfileUseCase(repository),
      completeOnboardingUseCase: CompleteOnboardingUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signs in with demo credentials', (tester) async {
    await pumpLogin(tester);

    // Fill via the "Fill demo credentials" shortcut.
    await tester.tap(find.text('Fill demo credentials'));
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pump(); // loading state
    expect(cubit.state.status, AuthStatus.loading);

    await tester.pump(const Duration(milliseconds: 700)); // mock latency
    await tester.pumpAndSettle();

    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.user?.email, 'demo@forgegym.app');
  });

  testWidgets('shows inline validation errors for bad input', (tester) async {
    await pumpLogin(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'not-an-email');
    await tester.enterText(fields.at(1), '123');
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    // Form validators reject before the cubit is ever called.
    expect(cubit.state.status, isNot(AuthStatus.loading));
    expect(find.textContaining('doesn\u2019t look right'), findsOneWidget);
  });
}
