import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:extrabite_mobile/app/app.dart';
import 'package:extrabite_mobile/features/auth/screens/welcome_screen.dart';
import 'package:extrabite_mobile/features/auth/screens/role_selection_screen.dart';
import 'package:extrabite_mobile/features/auth/screens/customer_auth_screen.dart';
import 'package:extrabite_mobile/features/auth/screens/owner_auth_screen.dart';
import 'package:extrabite_mobile/features/auth/screens/email_confirmation_screen.dart';
import 'package:extrabite_mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:extrabite_mobile/features/auth/screens/account_status_screen.dart';
import 'package:extrabite_mobile/features/auth/screens/owner_pending_screen.dart';
import 'package:extrabite_mobile/features/owner/screens/owner_dashboard_screen.dart';
import 'package:extrabite_mobile/features/owner/screens/property_pending_screen.dart';
import 'package:extrabite_mobile/features/owner/screens/property_registration_screen.dart';
import 'package:extrabite_mobile/features/customer/screens/customer_home_screen.dart';
import 'package:extrabite_mobile/features/customer/screens/food_detail_screen.dart';
import 'package:extrabite_mobile/features/customer/screens/reservation_pass_screen.dart';
import 'package:extrabite_mobile/features/customer/screens/reservations_screen.dart';
import 'package:extrabite_mobile/features/customer/screens/customer_profile_screen.dart';
import 'package:extrabite_mobile/models/user_model.dart';
import 'package:extrabite_mobile/models/user_role.dart';
import 'package:extrabite_mobile/providers/auth_provider.dart';
import 'mocks.dart';

void main() {
  final testOwner = UserModel(
    id: 'owner_123',
    name: 'Sri Sai PG Host',
    email: 'pgowner@example.com',
    phone: '+91 9876543210',
    role: UserRole.owner,
    propertyName: 'Sri Sai PG',
    roleFinalized: true,
    isOwnerEligible: true,
    isSuspended: false,
  );

  final testCustomer = UserModel(
    id: 'cust_123',
    name: 'Alice Student',
    email: 'student@example.com',
    phone: '+91 9123456780',
    role: UserRole.personal,
    roleFinalized: true,
    isOwnerEligible: false,
    isSuspended: false,
  );

  group('Semantics & ParentData Rigorous Test Suite', () {
    testWidgets('1. OwnerDashboardScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakeLocationAndAuthOverrides(),
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
                notifier.state = AuthState.fromProfile(testOwner);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: OwnerDashboardScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('2. WelcomeScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeLocationAndAuthOverrides(),
            child: const MaterialApp(
              home: WelcomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('3. RoleSelectionScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeLocationAndAuthOverrides(),
            child: const MaterialApp(
              home: RoleSelectionScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('4. CustomerAuthScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeLocationAndAuthOverrides(),
            child: const MaterialApp(
              home: CustomerAuthScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('5. OwnerAuthScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeLocationAndAuthOverrides(),
            child: const MaterialApp(
              home: OwnerAuthScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('6. EmailConfirmationScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeLocationAndAuthOverrides(),
            child: const MaterialApp(
              home: EmailConfirmationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('7. ForgotPasswordScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeLocationAndAuthOverrides(),
            child: const MaterialApp(
              home: ForgotPasswordScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('8. AccountStatusScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeLocationAndAuthOverrides(),
            child: const MaterialApp(
              home: AccountStatusScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('9. PropertyPendingScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakeLocationAndAuthOverrides(),
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
                notifier.state = AuthState.fromProfile(testOwner);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: PropertyPendingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('10. PropertyRegistrationScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakeLocationAndAuthOverrides(),
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
                notifier.state = AuthState.fromProfile(testOwner);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: PropertyRegistrationScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('11. CustomerHomeScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakeLocationAndAuthOverrides(),
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
                notifier.state = AuthState.fromProfile(testCustomer);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: CustomerHomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('12. FoodDetailScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakeLocationAndAuthOverrides(),
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
                notifier.state = AuthState.fromProfile(testCustomer);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: FoodDetailScreen(foodId: 'item_1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('13. ReservationPassScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakeLocationAndAuthOverrides(),
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
                notifier.state = AuthState.fromProfile(testCustomer);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: ReservationPassScreen(reservationId: 'res_1'),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('14. OwnerPendingScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakeLocationAndAuthOverrides(),
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
                notifier.state = AuthState.pendingOwnerApproval(testOwner);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: OwnerPendingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('15. ReservationsScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakeLocationAndAuthOverrides(),
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
                notifier.state = AuthState.fromProfile(testCustomer);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: ReservationsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('16. CustomerProfileScreen with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakeLocationAndAuthOverrides(),
              authProvider.overrideWith((ref) {
                final notifier = AuthNotifier(ref.read(authRepositoryProvider), ref);
                notifier.state = AuthState.fromProfile(testCustomer);
                return notifier;
              }),
            ],
            child: const MaterialApp(
              home: CustomerProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });

    testWidgets('17. Full App Navigation Flow with semantics enabled', (WidgetTester tester) async {
      final semanticsHandle = tester.binding.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: fakeLocationAndAuthOverrides(),
            child: const ExtraBiteApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Tap role selection
        await tester.tap(find.text('Personal User'));
        await tester.pumpAndSettle();

        // Login
        await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
        await tester.tap(find.text('Log In as Personal User'));
        await tester.pumpAndSettle();

        // Set role
        await tester.tap(find.text('Personal User'));
        await tester.pumpAndSettle();
      } finally {
        semanticsHandle.dispose();
      }
    });
  });
}
