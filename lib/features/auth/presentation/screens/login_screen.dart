import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/core/constants/backend_info.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/auth/presentation/auth_route_paths.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_state.dart';
import 'package:forge_gym/features/auth/presentation/validators/auth_validators.dart';
import 'package:forge_gym/features/auth/presentation/widgets/auth_hero.dart';
import 'package:go_router/go_router.dart';

/// Email + password sign in.
///
/// Mock: any valid-format email with a 6+ character password signs in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }
  }

  void _fillDemo() {
    _emailController.text = 'demo@forgegym.app';
    _passwordController.text = 'password123';
    context.read<AuthCubit>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AuthHero(
        title: 'Welcome back',
        subtitle: 'Sign in to continue your training.',
      ),
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state.status == AuthStatus.loading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: AuthValidators.validateEmail,
                        onChanged: (_) =>
                            context.read<AuthCubit>().clearError(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: AuthValidators.validatePassword,
                        onChanged: (_) =>
                            context.read<AuthCubit>().clearError(),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          semanticsLabel:
                              'Sign in error: ${state.errorMessage}',
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'Sign in',
                        onPressed: isLoading ? null : _submit,
                        isLoading: isLoading,
                      ),
                      // The demo shortcut only exists for the local mock;
                      // real accounts (Firebase) have no demo user.
                      if (!getIt.isRegistered<BackendInfo>() ||
                          getIt<BackendInfo>().usesMockAuth) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: 'Fill demo credentials',
                          variant: AppButtonVariant.text,
                          size: AppButtonSize.medium,
                          onPressed: isLoading ? null : _fillDemo,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'New here?',
                            style: AppTextStyles.bodySmall,
                          ),
                          TextButton(
                            onPressed: () =>
                                context.go(AuthRoutePaths.register),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              context.go(AuthRoutePaths.forgotPassword),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
