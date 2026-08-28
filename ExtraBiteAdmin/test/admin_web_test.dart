import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:extrabite_admin/core/repositories/admin_repository.dart';
import 'package:extrabite_admin/features/auth/screens/login_screen.dart';
import 'package:extrabite_admin/features/dashboard/screens/admin_dashboard_layout.dart';
import 'package:extrabite_admin/features/dashboard/screens/pg_detail_screen.dart';
import 'package:extrabite_admin/models/pg_profile.dart';
import 'package:extrabite_admin/models/user_model.dart';
import 'package:extrabite_admin/models/user_role.dart';
import 'package:extrabite_admin/models/admin_food_listing.dart';
import 'package:extrabite_admin/models/admin_reservation.dart';
import 'package:extrabite_admin/models/admin_report.dart';
import 'package:extrabite_admin/models/analytics_data.dart';
import 'package:extrabite_admin/providers/auth_provider.dart';

class FakeGoTrueClient extends GoTrueClient {
  FakeGoTrueClient()
      : super(
          url: 'http://localhost:54321/auth/v1',
          autoRefreshToken: false,
        );

  @override
  User? get currentUser => const User(
        id: 'admin_1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-01-01',
      );
}

class FakeSupabaseClient extends SupabaseClient {
  FakeSupabaseClient()
      : super(
          'http://localhost:54321',
          'fake-anon-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );

  @override
  GoTrueClient get auth => FakeGoTrueClient();
}

class FakeAdminRepository extends AdminRepository {
  bool isApproved = false;
  String? rejectedReason;
  bool userSuspended = false;
  String listingStatus = 'active';
  String reportStatus = 'pending';

  FakeAdminRepository() : super(FakeSupabaseClient());

  @override
  Future<void> signOut() async {}

  @override
  Future<Map<String, int>> getDashboardStats() async {
    return {
      'totalUsers': 50,
      'pgOwners': 10,
      'pendingPgs': isApproved ? 0 : 1,
      'approvedPgs': isApproved ? 9 : 8,
      'foodListings': 12,
      'reservations': 15,
      'rescuedPortions': 35,
    };
  }

  @override
  Future<List<PgProfile>> getPendingPgProfiles() async {
    if (isApproved) return [];
    return [
      PgProfile(
        id: 'pg_123',
        ownerId: 'owner_123',
        pgName: 'Sri Sai Deluxe PG',
        address: 'Near VIT-AP Campus, Inorbit Road',
        neighborhood: 'Campus West Gate',
        city: 'Bengaluru',
        latitude: 16.4971,
        longitude: 80.5005,
        contactPhone: '9876543210',
        isApproved: false,
        isActive: true,
        fssaiLicenseNumber: 'FSSAI982736410',
        ownerName: 'Subba Rao',
        ownerEmail: 'subbarao@pgowner.com',
      )
    ];
  }

  @override
  Future<PgProfile?> getPgProfile(String id) async {
    return PgProfile(
      id: id,
      ownerId: 'owner_123',
      pgName: 'Sri Sai Deluxe PG',
      address: 'Near VIT-AP Campus, Inorbit Road',
      neighborhood: 'Campus West Gate',
      city: 'Bengaluru',
      latitude: 16.4971,
      longitude: 80.5005,
      contactPhone: '9876543210',
      isApproved: isApproved,
      isActive: true,
      fssaiLicenseNumber: 'FSSAI982736410',
      ownerName: 'Subba Rao',
      ownerEmail: 'subbarao@pgowner.com',
    );
  }

  @override
  Future<void> approvePgProfile(String id) async {
    isApproved = true;
  }

  @override
  Future<void> rejectPgProfile(String id, String reason) async {
    isApproved = false;
    rejectedReason = reason;
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    return [
      UserModel(
        id: 'user_cust_1',
        name: 'Rahul Sharma',
        email: 'rahul@student.edu',
        phone: '9876543210',
        role: UserRole.personal,
        isSuspended: userSuspended,
      ),
      UserModel(
        id: 'user_owner_1',
        name: 'Venkat Rao',
        email: 'venkat@pgstay.com',
        phone: '9123456789',
        role: UserRole.owner,
        propertyName: 'Balaji Executive PG',
      ),
    ];
  }

  @override
  Future<void> toggleUserSuspension(String userId, bool isSuspended) async {
    userSuspended = isSuspended;
  }

  @override
  Future<List<AdminFoodListing>> getAllFoodListings() async {
    return [
      AdminFoodListing(
        id: 'list_1',
        pgId: 'pg_123',
        pgName: 'Sri Sai Deluxe PG',
        ownerName: 'Subba Rao',
        title: 'Dal Makhani & Roti Combo',
        category: 'Dinner',
        originalPrice: 80.0,
        discountedPrice: 35.0,
        totalPortions: 10,
        availablePortions: 6,
        dietaryType: 'vegetarian',
        pickupStartTime: DateTime.now(),
        pickupEndTime: DateTime.now().add(const Duration(hours: 2)),
        status: listingStatus,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> updateListingStatus(String listingId, String newStatus) async {
    listingStatus = newStatus;
  }

  @override
  Future<List<AdminReservation>> getAllReservations() async {
    return [
      AdminReservation(
        id: 'res_1',
        readableId: '#EB-77889',
        listingId: 'list_1',
        foodTitle: 'Dal Makhani & Roti Combo',
        customerId: 'user_cust_1',
        customerName: 'Rahul Sharma',
        customerEmail: 'rahul@student.edu',
        pgName: 'Sri Sai Deluxe PG',
        portionsCount: 2,
        unitPrice: 35.0,
        totalAmount: 70.0,
        paymentMethod: 'pay_at_pickup',
        status: 'confirmed',
        pickupDeadline: DateTime.now().add(const Duration(hours: 1)),
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<AdminReport>> getAllReports() async {
    return [
      AdminReport(
        id: 'rep_1',
        reporterId: 'user_cust_1',
        reporterName: 'Rahul Sharma',
        reporterEmail: 'rahul@student.edu',
        listingId: 'list_1',
        listingTitle: 'Dal Makhani & Roti Combo',
        reason: 'Food Quality Concern',
        description: 'Packaging seal was open at counter.',
        status: reportStatus,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<void> resolveReport(String reportId, String status, String adminNotes) async {
    reportStatus = status;
  }

  @override
  Future<AnalyticsData> getAnalyticsData() async {
    return AnalyticsData(
      totalUsers: 50,
      totalCustomers: 38,
      totalPgOwners: 10,
      totalAdmins: 2,
      verifiedPgs: 8,
      pendingPgs: 1,
      totalFoodListings: 12,
      activeFoodListings: 9,
      totalReservations: 15,
      completedPickups: 12,
      cancelledReservations: 3,
      rescuedPortions: 35,
      totalFoodValueRescued: 1225.0,
      completionRate: 80.0,
    );
  }
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(AdminRepository repo, {bool authenticated = false})
      : super(repo, FakeSupabaseClient()) {
    if (authenticated) {
      state = AuthState.authenticated(
        UserModel(
          id: 'admin_1',
          name: 'Super Admin',
          email: 'admin@extrabite.in',
          phone: '9999999999',
          role: UserRole.admin,
        ),
      );
    } else {
      state = AuthState.unauthenticated();
    }
  }

  @override
  Future<void> checkCurrentSession() async {}

  @override
  Future<bool> login({required String email, required String password}) async {
    if (email == 'admin@extrabite.in' && password == 'admin123') {
      state = AuthState.authenticated(
        UserModel(
          id: 'admin_1',
          name: 'Super Admin',
          email: email,
          phone: '9999999999',
          role: UserRole.admin,
        ),
      );
      return true;
    } else if (email == 'customer@extrabite.in') {
      state = AuthState.error('Admin access required');
      return false;
    } else {
      state = AuthState.error('Invalid email or password. Please try again.');
      return false;
    }
  }

  @override
  Future<void> logout() async {
    state = AuthState.unauthenticated();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAdminRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAdminRepository();
  });

  group('ExtraBite Admin Web - Operations Portal Tests', () {
    testWidgets('1. Admin login screen submits and succeeds with valid credentials', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: false);
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Scaffold(body: Text('Admin Dashboard Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ExtraBite Admin'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'admin@extrabite.in');
      await tester.enterText(find.byType(TextFormField).last, 'admin123');
      await tester.pump();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Admin Dashboard Screen'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('2. Non-admin email login is rejected with error banner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: false);
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'customer@extrabite.in');
      await tester.enterText(find.byType(TextFormField).last, 'secret');
      await tester.pump();

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Admin access required'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('3. Admin loads dashboard overview with real counts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: true);
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const AdminDashboardLayout(initialTab: 0),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Operations Overview'), findsOneWidget);
      expect(find.text('TOTAL USERS'), findsOneWidget);
      expect(find.text('50'), findsWidgets);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('4. Verification list renders pending PG properties and views details', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: true);
      final router = GoRouter(
        initialLocation: '/pg-verification',
        routes: [
          GoRoute(
            path: '/pg-verification',
            builder: (context, state) => const AdminDashboardLayout(initialTab: 1),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Property Approvals Queue'), findsOneWidget);
      expect(find.text('Sri Sai Deluxe PG'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('5. Detailed review displays FSSAI, Address, Coordinates, and triggers approval', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: true);
      final router = GoRouter(
        initialLocation: '/pg_123',
        routes: [
          GoRoute(
            path: '/pg_123',
            builder: (context, state) => const PgDetailScreen(pgId: 'pg_123'),
          ),
          GoRoute(
            path: '/pg-verification',
            builder: (context, state) => const Scaffold(body: Text('PG Verification Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sri Sai Deluxe PG'), findsOneWidget);
      expect(find.text('FSSAI982736410'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('Near VIT-AP Campus, Inorbit Road'), findsOneWidget);
      expect(find.text('Approve PG Property'), findsOneWidget);

      await tester.ensureVisible(find.text('Approve PG Property'));
      await tester.tap(find.text('Approve PG Property'));
      await tester.pump();

      expect(find.text('Confirm Approval'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Approve'));
      await tester.pumpAndSettle();

      expect(fakeRepository.isApproved, true);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('6. Detailed review opens rejection modal, submits feedback, and updates repository', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: true);
      final router = GoRouter(
        initialLocation: '/pg_123',
        routes: [
          GoRoute(
            path: '/pg_123',
            builder: (context, state) => const PgDetailScreen(pgId: 'pg_123'),
          ),
          GoRoute(
            path: '/pg-verification',
            builder: (context, state) => const Scaffold(body: Text('PG Verification Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reject Property'), findsOneWidget);
      await tester.tap(find.text('Reject Property'));
      await tester.pumpAndSettle();

      expect(find.text('Reject Property Application'), findsOneWidget);
      expect(find.text('Rejection Category *'), findsOneWidget);
      expect(find.text('Admin Feedback Note *'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, ''),
        'FSSAI document is expired. Please re-upload active license.',
      );
      await tester.pump();

      await tester.tap(find.text('Confirm Rejection'));
      await tester.pumpAndSettle();

      expect(fakeRepository.rejectedReason, contains('FSSAI document is expired'));

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('7. User Management renders real users, opens detail modal, and toggles suspension', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: true);
      final router = GoRouter(
        initialLocation: '/users',
        routes: [
          GoRoute(
            path: '/users',
            builder: (context, state) => const AdminDashboardLayout(initialTab: 2),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Venkat Rao'), findsOneWidget);
      expect(find.text('Balaji Executive PG'), findsOneWidget);

      // Open user detail
      await tester.ensureVisible(find.byIcon(Icons.visibility_outlined).first);
      await tester.tap(find.byIcon(Icons.visibility_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('rahul@student.edu'), findsWidgets);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Toggle suspension
      await tester.ensureVisible(find.byIcon(Icons.block_outlined).first);
      await tester.tap(find.byIcon(Icons.block_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Suspend User Account'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Suspend'));
      await tester.pumpAndSettle();

      expect(fakeRepository.userSuspended, true);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('8. Food Listings tab renders meals and allows moderation toggle', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: true);
      final router = GoRouter(
        initialLocation: '/food-listings',
        routes: [
          GoRoute(
            path: '/food-listings',
            builder: (context, state) => const AdminDashboardLayout(initialTab: 3),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dal Makhani & Roti Combo'), findsOneWidget);
      expect(find.text('₹35'), findsOneWidget);

      // Moderation toggle
      await tester.ensureVisible(find.byIcon(Icons.delete_outline));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Remove from Marketplace?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Remove'));
      await tester.pumpAndSettle();

      expect(fakeRepository.listingStatus, 'removed');

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('9. Reservations feed tab renders live orders and details modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: true);
      final router = GoRouter(
        initialLocation: '/reservations',
        routes: [
          GoRoute(
            path: '/reservations',
            builder: (context, state) => const AdminDashboardLayout(initialTab: 4),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('#EB-77889'), findsOneWidget);
      expect(find.text('₹70'), findsOneWidget);

      await tester.ensureVisible(find.byIcon(Icons.visibility_outlined));
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Reservation #EB-77889'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('10. Safety & Reports tab renders incident and resolves with notes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: true);
      final router = GoRouter(
        initialLocation: '/reports',
        routes: [
          GoRoute(
            path: '/reports',
            builder: (context, state) => const AdminDashboardLayout(initialTab: 5),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Food Quality Concern'), findsOneWidget);
      expect(find.text('Review Incident'), findsOneWidget);

      await tester.ensureVisible(find.text('Review Incident'));
      await tester.tap(find.text('Review Incident'));
      await tester.pumpAndSettle();

      expect(find.text('Review Safety Incident'), findsOneWidget);
      await tester.tap(find.text('Mark Resolved'));
      await tester.pumpAndSettle();

      expect(fakeRepository.reportStatus, 'resolved');

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });

    testWidgets('11. Analytics & Platform Settings tabs load successfully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1024));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fakeAuth = FakeAuthNotifier(fakeRepository, authenticated: true);

      // 1. Analytics
      final router1 = GoRouter(
        initialLocation: '/analytics',
        routes: [
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AdminDashboardLayout(initialTab: 6),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router1,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Analytics & Sustainability Impact'), findsOneWidget);
      expect(find.text('35'), findsOneWidget); // Portions rescued
      expect(find.text('₹1225'), findsOneWidget); // Food value rescued

      // 2. Settings
      final router2 = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const AdminDashboardLayout(initialTab: 7),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminRepositoryProvider.overrideWithValue(fakeRepository),
            authProvider.overrideWith((ref) => fakeAuth),
          ],
          child: MaterialApp.router(
            routerConfig: router2,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Platform Configuration & Policy Status'), findsOneWidget);
      expect(find.text('Zero Online Payment Gateway ("Pay at Pickup" Invariant)'), findsOneWidget);

      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
    });
  });
}
