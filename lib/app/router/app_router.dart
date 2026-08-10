import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/search_screen.dart';
import '../../features/customer/screens/reservations_screen.dart';
import '../../features/customer/screens/customer_profile_screen.dart';
import '../../features/customer/screens/food_detail_screen.dart';
import '../../features/customer/widgets/customer_bottom_nav.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/customer/home',
    routes: [
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
