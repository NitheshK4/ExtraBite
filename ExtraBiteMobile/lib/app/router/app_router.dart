import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/owner/screens/owner_dashboard_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/search_screen.dart';
import '../../features/customer/screens/reservations_screen.dart';
import '../../features/customer/screens/customer_profile_screen.dart';
import '../../features/customer/screens/food_detail_screen.dart';
import '../../features/customer/widgets/customer_bottom_nav.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/auth/role-selection',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final status = authState.status;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isOwnerRoute = state.matchedLocation.startsWith('/owner');

      // 1. Uninitialized or Role Selection -> Force Role Selection Screen
      if (status == AuthStatus.uninitialized || status == AuthStatus.selectingRole) {
        if (state.matchedLocation == '/auth/role-selection') return null;
        return '/auth/role-selection';
      }

      // 2. Unauthenticated, Authenticating, or Error -> Force Login Screen
      if (status == AuthStatus.unauthenticated ||
          status == AuthStatus.authenticating ||
          status == AuthStatus.error) {
        if (state.matchedLocation == '/auth/login') return null;
        return '/auth/login';
      }

      // 3. Authenticated -> Route based on role
      if (status == AuthStatus.authenticated) {
        final userRole = authState.user?.role;
        if (userRole == UserRole.owner) {
          // Owner routes
          if (isAuthRoute || !isOwnerRoute) {
            return '/owner/dashboard';
          }
        } else {
          // Personal User routes
          if (isAuthRoute || isOwnerRoute) {
            return '/customer/home';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/role-selection',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: RoleSelectionScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AuthScreen(),
        ),
      ),
      GoRoute(
        path: '/owner/dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OwnerDashboardScreen(),
        ),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) {
          return CustomerBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/customer/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CustomerHomeScreen(),
            ),
          ),
          GoRoute(
            path: '/customer/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/customer/reservations',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReservationsScreen(),
            ),
          ),
          GoRoute(
            path: '/customer/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CustomerProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/customer/food/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return FoodDetailScreen(foodId: id);
        },
      ),
    ],
  );
});
