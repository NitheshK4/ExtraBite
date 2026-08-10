import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/role_selection_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/customer/customer_shell_screen.dart';
import '../../features/discovery/discovery_screen.dart';
import '../../features/discovery/search_screen.dart';
import '../../features/listings/listing_detail_screen.dart';
import '../../features/reservations/reservation_flow_screen.dart';
import '../../features/reservations/reservation_success_screen.dart';
import '../../features/reservations/active_reservations_screen.dart';
import '../../features/reservations/reservation_history_screen.dart';
import '../../features/reservations/reservation_detail_screen.dart';
import '../../features/customer/favorites_screen.dart';
import '../../features/customer/notifications_screen.dart';
import '../../features/customer/customer_profile_screen.dart';
import '../../features/maps/map_explorer_screen.dart';
import '../../features/qr_pickup/qr_pass_screen.dart';
import '../../features/qr_pickup/qr_scanner_screen.dart';
import '../../features/qr_pickup/manual_code_verification_screen.dart';
import '../../features/owner/owner_shell_screen.dart';
import '../../features/owner/owner_dashboard_screen.dart';
import '../../features/owner/owner_listings_screen.dart';
import '../../features/owner/create_edit_listing_screen.dart';
import '../../features/owner/owner_reservations_queue_screen.dart';
import '../../features/owner/owner_analytics_screen.dart';
import '../../features/owner/owner_profile_screen.dart';
import '../../features/admin/admin_shell_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/admin/owner_approvals_screen.dart';
import '../../features/admin/listing_moderation_screen.dart';
import '../../features/admin/reports_management_screen.dart';
import '../../features/admin/audit_log_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/discover',
    redirect: (context, state) {
      final user = authState.currentUser;
      final path = state.uri.path;

      // Allow public auth & onboarding routes
      if (path == '/onboarding' || path == '/role-selection' || path == '/auth') {
        return null;
      }

      if (user == null) {
        return '/role-selection';
      }

      // Role Guards
      if (path.startsWith('/owner-') || path == '/create-listing' || path == '/qr-scanner' || path == '/manual-code-verify') {
        if (user.role != UserRole.pgOwner && user.role != UserRole.admin) {
          return '/discover'; // Guard: Customer cannot access owner features
        }
      }

      if (path.startsWith('/admin-')) {
        if (user.role != UserRole.admin) {
          return user.role == UserRole.pgOwner ? '/owner-dashboard' : '/discover'; // Guard: Only admin can access admin features
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final roleParam = state.uri.queryParameters['role'];
          UserRole role = UserRole.customer;
          if (roleParam == 'pgOwner' || roleParam == 'owner') {
            role = UserRole.pgOwner;
          } else if (roleParam == 'admin') {
            role = UserRole.admin;
          }
          return AuthScreen(initialRole: role);
        },
      ),

      // Customer Navigation Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => CustomerShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoveryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reservations',
                builder: (context, state) => const ActiveReservationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const CustomerProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Customer Subroutes
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapExplorerScreen(),
      ),
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) => ListingDetailScreen(
          listingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/reserve/:id',
        builder: (context, state) {
          final qty = int.tryParse(state.uri.queryParameters['qty'] ?? '1') ?? 1;
          return ReservationFlowScreen(
            listingId: state.pathParameters['id']!,
            initialQuantity: qty,
          );
        },
      ),
      GoRoute(
        path: '/reservation-success/:id',
        builder: (context, state) => ReservationSuccessScreen(
          reservationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/qr-pass/:id',
        builder: (context, state) => QrPassScreen(
          reservationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/reservation-history',
        builder: (context, state) => const ReservationHistoryScreen(),
      ),
      GoRoute(
        path: '/reservation-detail/:id',
        builder: (context, state) => ReservationDetailScreen(
          reservationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // PG Owner Shell & Routes
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => OwnerShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner-dashboard',
                builder: (context, state) => const OwnerDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner-listings',
                builder: (context, state) => const OwnerListingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner-queue',
                builder: (context, state) => const OwnerReservationsQueueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner-analytics',
                builder: (context, state) => const OwnerAnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner-profile',
                builder: (context, state) => const OwnerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/create-listing',
        builder: (context, state) => const CreateEditListingScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/manual-code-verify',
        builder: (context, state) => const ManualCodeVerificationScreen(),
      ),

      // Admin Shell & Routes
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AdminShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin-dashboard',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin-moderation',
                builder: (context, state) => const ListingModerationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin-approvals',
                builder: (context, state) => const OwnerApprovalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin-reports',
                builder: (context, state) => const ReportsManagementScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin-audit',
                builder: (context, state) => const AuditLogScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
