import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_layout.dart';
import '../../features/dashboard/screens/pg_detail_screen.dart';
import '../../models/user_role.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin_root');
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final loc = state.matchedLocation;

      // Priority 1: App is loading session
      if (status == AuthStatus.uninitialized) {
        return null; // Stay where we are
      }

      // Priority 2: Unauthenticated state
      if (status == AuthStatus.unauthenticated || status == AuthStatus.error) {
        if (loc == '/login') return null;
        return '/login';
      }

      // Priority 3: Authenticated state
      if (status == AuthStatus.authenticated) {
        final user = authState.user;
        if (user == null || user.role != UserRole.admin) {
          return '/login';
        }

        // If trying to access login, send to dashboard
        if (loc == '/login') {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const AdminDashboardLayout(initialTab: 0),
      ),
      GoRoute(
        path: '/pg-verification',
        builder: (context, state) => const AdminDashboardLayout(initialTab: 1),
      ),
      GoRoute(
        path: '/pg-verification/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PgDetailScreen(pgId: id);
        },
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const AdminDashboardLayout(initialTab: 2),
      ),
      GoRoute(
        path: '/food-listings',
        builder: (context, state) => const AdminDashboardLayout(initialTab: 3),
      ),
      GoRoute(
        path: '/reservations',
        builder: (context, state) => const AdminDashboardLayout(initialTab: 4),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const AdminDashboardLayout(initialTab: 5),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AdminDashboardLayout(initialTab: 6),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const AdminDashboardLayout(initialTab: 7),
      ),
    ],
  );
});
