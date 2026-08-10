import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_role.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_bottom_nav.dart';
import '../screens/customer/explore_screen.dart';
import '../screens/customer/reservations_screen.dart';
import '../screens/pg_owner/pg_dashboard_screen.dart';
import '../screens/pg_owner/qr_scanner_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/shared/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final userState = ref.watch(userProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          int currentIndex = 0;

          final location = state.uri.toString();
          if (location.startsWith('/reservations') || location.startsWith('/scan-qr')) {
            currentIndex = 1;
          } else if (location.startsWith('/profile')) {
            currentIndex = 2;
          }

          return Scaffold(
            body: child,
            bottomNavigationBar: CustomBottomNav(
              currentIndex: currentIndex,
              onTap: (index) {
                switch (userState.currentRole) {
                  case UserRole.customer:
                    if (index == 0) context.go('/');
                    if (index == 1) context.go('/reservations');
                    if (index == 2) context.go('/profile');
                    break;
                  case UserRole.pgOwner:
                    if (index == 0) context.go('/');
                    if (index == 1) context.go('/scan-qr');
                    if (index == 2) context.go('/profile');
                    break;
                  case UserRole.admin:
                    if (index == 0) context.go('/');
                    if (index == 1) context.go('/admin-manage');
                    if (index == 2) context.go('/profile');
                    break;
                }
              },
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              switch (userState.currentRole) {
                case UserRole.customer:
                  return const ExploreScreen();
                case UserRole.pgOwner:
                  return const PgDashboardScreen();
                case UserRole.admin:
                  return const AdminDashboardScreen();
              }
            },
          ),
          GoRoute(
            path: '/reservations',
            builder: (context, state) => const CustomerReservationsScreen(),
          ),
          GoRoute(
            path: '/scan-qr',
            builder: (context, state) => const QrScannerScreen(),
          ),
          GoRoute(
            path: '/admin-manage',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
