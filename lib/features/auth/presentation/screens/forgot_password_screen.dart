import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/auth/presentation/auth_route_paths.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_state.dart';
import 'package:forge_gym/features/auth/presentation/validators/auth_validators.dart';
import 'package:forge_gym/features/auth/presentation/widgets/auth_hero.dart';
import 'package:go_router/go_router.dart';

/// Password reset: enter email, get a confirmation.
/// Mock: no email is actually sent.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().sendPasswordReset(email: _emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const AuthHero(
        title: 'Reset your password',
        subtitle: 'We\u2019ll email you a link to choose a new one.',
        imageAsset: 'assets/exercises/lat-pulldown/thumb.jpg',
        backTo: AuthRoutePaths.login,
      ),
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state.status == AuthStatus.loading;
            if (state.passwordResetSent) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppCard(
                      child: Column(
                        children: [
                          Icon(
                            Icons.mark_email_read_outlined,
                            size: 56,
                            color: scheme.primary,
                            semanticLabel: 'Email sent',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Check your inbox',
                            style: AppTextStyles.title,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'If an account exists for ${_emailController.text.trim()}, '
                            'a reset link is on its way.',
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Back to sign in',
                      onPressed: () => context.go(AuthRoutePaths.login),
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.email],
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: AuthValidators.validateEmail,
                      onChanged: (_) => context.read<AuthCubit>().clearError(),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        state.errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: scheme.error,
                        ),
                        semanticsLabel: 'Reset error: ${state.errorMessage}',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Send reset link',
                      onPressed: isLoading ? null : _submit,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AuthRoutePaths.login),
                        child: const Text('Back to sign in'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
