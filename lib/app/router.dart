import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../state/app_state.dart';

String? redirectFor(AppState app, String location) {
  if (!app.isLoaded) return null;
  final isLogin = location == '/login';
  if (!app.signedIn && !isLogin) return '/login';
  if (app.signedIn && isLogin) return '/home';
  return null;
}

GoRouter buildRouter({
  required AppState app,
  required Widget login,
  required Widget home,
}) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      return redirectFor(app, state.matchedLocation);
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => login),
      GoRoute(path: '/home', builder: (_, __) => home),
    ],
  );
}
