import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/customer_auth_screen.dart';
import '../../features/auth/screens/owner_auth_screen.dart';
import '../../features/auth/screens/email_confirmation_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/account_status_screen.dart';
import '../../features/auth/screens/owner_pending_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/owner/screens/owner_dashboard_screen.dart';
import '../../features/owner/screens/add_meal_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/search_screen.dart';
import '../../features/customer/screens/reservations_screen.dart';
import '../../features/customer/screens/customer_profile_screen.dart';
import '../../features/customer/screens/food_detail_screen.dart';
import '../../features/customer/screens/reservation_pass_screen.dart';
import '../../features/customer/widgets/customer_bottom_nav.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';

import '../../features/owner/screens/property_registration_screen.dart';
import '../../features/owner/screens/property_pending_screen.dart';

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
      final loc = state.matchedLocation;

      // -----------------------------------------------------------------------
      // Priority 1 — Uninitialized / profile still loading
      // -----------------------------------------------------------------------
      if (status == AuthStatus.uninitialized ||
          status == AuthStatus.profileLoading) {
        if (loc == '/auth/role-selection' || loc == '/auth/welcome') return null;
        return '/auth/role-selection';
      }

      // -----------------------------------------------------------------------
      // Priority 2 — No session (welcome, role-selection, or login flows)
      // -----------------------------------------------------------------------
      if (status == AuthStatus.selectingRole) {
        if (loc == '/auth/role-selection' || loc == '/auth/welcome') return null;
        return '/auth/role-selection';
      }

      if (status == AuthStatus.unauthenticated ||
          status == AuthStatus.authenticating ||
          status == AuthStatus.error) {
        if (loc == '/auth/login' ||
            loc == '/auth/customer-login' ||
            loc == '/auth/owner-login' ||
            loc == '/auth/email-confirmation' ||
            loc == '/auth/forgot-password') {
          return null;
        }
        return '/auth/login';
      }

      // -----------------------------------------------------------------------
      // Priority 3 — Account suspended
      // -----------------------------------------------------------------------
      if (status == AuthStatus.suspended) {
        if (loc == '/auth/account-status') return null;
        return '/auth/account-status';
      }

      // -----------------------------------------------------------------------
      // Priority 4 — Pending owner approval (is_owner_eligible = false)
      // -----------------------------------------------------------------------
      if (status == AuthStatus.pendingOwnerApproval) {
        if (loc == '/auth/owner-pending') return null;
        return '/auth/owner-pending';
      }

      // -----------------------------------------------------------------------
      // Priority 4b — PG Owner but property needs registration / approval
      // -----------------------------------------------------------------------
      if (status == AuthStatus.propertyRegistrationRequired) {
        if (loc == '/owner/property-registration') return null;
        return '/owner/property-registration';
      }

      if (status == AuthStatus.propertyApprovalPending) {
        if (loc == '/owner/property-pending') return null;
        return '/owner/property-pending';
      }

      // -----------------------------------------------------------------------
      // Priority 5 — Authenticated with a valid session
      // -----------------------------------------------------------------------
      if (status == AuthStatus.authenticated) {
        final user = authState.user;
        final isAuthRoute = loc.startsWith('/auth');

        // --- 5a. role_finalized = false → Role Selection -----------------
        if (user != null && !user.roleFinalized) {
          if (loc == '/auth/role-selection') return null;
          return '/auth/role-selection';
        }

        // --- 5b. role_finalized = true → route by role -------------------
        final userRole = user?.role;

        if (userRole == UserRole.owner) {
          if (isAuthRoute || !loc.startsWith('/owner')) {
            return '/owner/dashboard';
          }
        } else if (userRole == UserRole.admin) {
          if (isAuthRoute || !loc.startsWith('/admin')) {
            return '/admin/dashboard';
          }
        } else {
          // personal / customer
          if (isAuthRoute || loc.startsWith('/owner')) {
            return '/customer/home';
          }
        }
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth/welcome',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: WelcomeScreen(),
        ),
      ),
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
        path: '/auth/customer-login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: CustomerAuthScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/owner-login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OwnerAuthScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/email-confirmation',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: EmailConfirmationScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/account-status',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AccountStatusScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/owner-pending',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OwnerPendingScreen(),
        ),
      ),

      // Admin routes
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminDashboardScreen(),
        ),
      ),

      // Owner routes
      GoRoute(
        path: '/owner/property-registration',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PropertyRegistrationScreen(),
        ),
      ),
      GoRoute(
        path: '/owner/property-pending',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PropertyPendingScreen(),
        ),
      ),
      GoRoute(
        path: '/owner/dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OwnerDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/owner/add-meal',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final authState = ref.read(authProvider);
          final user = authState.user;
          if (user == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return AddMealScreen(user: user);
        },
      ),

      // Customer shell (bottom nav)
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

      // Food detail (pushed above the shell)
      GoRoute(
        path: '/customer/food/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return FoodDetailScreen(foodId: id);
        },
      ),

      // Digital Reservation Pass & QR Ticket
      GoRoute(
        path: '/customer/pass/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ReservationPassScreen(reservationId: id);
        },
      ),
    ],
  );
});
