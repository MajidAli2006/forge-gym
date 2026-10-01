import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_gym/app/bootstrap/app_environment.dart';
import 'package:forge_gym/app/dependency_injection/injection.dart';
import 'package:forge_gym/app/routing/app_router.dart';
import 'package:forge_gym/design_system/design_system.dart';
import 'package:forge_gym/features/auth/presentation/cubit/auth_cubit.dart';

/// Root widget. Theming and routing are resolved here; everything else
/// lives in features.
///
/// [AuthCubit] is provided above the router as a singleton: the auth
/// screens and the router's auth gate share the same session instance.
class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: MaterialApp.router(
        title: getIt<EnvConfig>().appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: getIt<AppRouter>().router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
