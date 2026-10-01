import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/auth/domain/entities/fitness_level.dart';
import 'package:forge_gym/features/auth/presentation/auth_route_paths.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_state.dart';
import 'package:forge_gym/features/auth/presentation/validators/auth_validators.dart';
import 'package:forge_gym/features/auth/presentation/widgets/auth_hero.dart';
import 'package:go_router/go_router.dart';

/// New member registration: name, email, password, training level.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  FitnessLevel _fitnessLevel = FitnessLevel.beginner;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        fitnessLevel: _fitnessLevel,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AuthHero(
        title: 'Create your account',
        subtitle: 'Start training in under a minute.',
        imageAsset: 'assets/exercises/squat-barbell/thumb.jpg',
        backTo: AuthRoutePaths.login,
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
                        controller: _nameController,
                        label: 'Full name',
                        hint: 'Alex Morgan',
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: AuthValidators.validateName,
                        onChanged: (_) =>
                            context.read<AuthCubit>().clearError(),
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                        hint: 'At least 6 characters',
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
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
                      const SizedBox(height: AppSpacing.lg),
                      const AppSectionHeader(
                        title: 'Training level',
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'We\u2019ll tailor recommendations to this.',
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: FitnessLevel.values
                            .map(
                              (level) => AppChip(
                                label: level.label,
                                selected: _fitnessLevel == level,
                                onSelected: (_) =>
                                    setState(() => _fitnessLevel = level),
                              ),
                            )
                            .toList(),
                      ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          semanticsLabel:
                              'Registration error: ${state.errorMessage}',
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'Create account',
                        onPressed: isLoading ? null : _submit,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account?',
                            style: AppTextStyles.bodySmall,
                          ),
                          TextButton(
                            onPressed: () => context.go(AuthRoutePaths.login),
                            child: const Text('Sign in'),
                          ),
                        ],
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
