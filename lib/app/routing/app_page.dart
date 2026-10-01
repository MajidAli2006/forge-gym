import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Route transitions shared by the router.
///
/// - [AppPage.slideUp]: detail screens rise in with a fade (feels like
///   opening something).
/// - [AppPage.fade]: auth/utility screens cross-fade.
///
/// Both honour the platform's reduced-motion setting by shortening to a
/// plain fade.
abstract final class AppPage {
  static CustomTransitionPage<void> slideUp(
    GoRouterState state,
    Widget child,
  ) => CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      return FadeTransition(
        opacity: curved,
        child: reduceMotion
            ? child
            : SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
      );
    },
  );

  static CustomTransitionPage<void> fade(GoRouterState state, Widget child) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        name: state.name,
        child: child,
        transitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            ),
      );
}
