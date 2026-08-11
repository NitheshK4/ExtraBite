import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:extrabite_mobile/app/app.dart';
import 'package:extrabite_mobile/models/user_role.dart';
import 'package:extrabite_mobile/providers/auth_provider.dart';

void main() {
  group('Privacy & User Data Isolation Tests', () {
    testWidgets('1. Fresh install shows Role Selection, not a hardcoded profile', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExtraBiteApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Must show role selection screen
      expect(find.text('Welcome to ExtraBite'), findsOneWidget);
      expect(find.text('Personal User'), findsOneWidget);
      expect(find.text('Hostel / PG Owner'), findsOneWidget);

      // Must NOT show hardcoded developer profile data anywhere
      expect(find.text('Pavan Kumar'), findsNothing);
      expect(find.text('pavan.kumar@example.com'), findsNothing);
      expect(find.text('+91 9876543210'), findsNothing);
    });

    testWidgets('1b. Back button and Change button on Auth Screen navigate back to Role Selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExtraBiteApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Personal User role
      await tester.tap(find.text('Personal User'));
      await tester.pumpAndSettle();

      // We are on Auth Screen
      expect(find.text('Personal User Auth'), findsOneWidget);

      // Tap AppBar back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Must be back on Role Selection screen
      expect(find.text('Welcome to ExtraBite'), findsOneWidget);
      expect(find.text('Personal User'), findsOneWidget);

      // Select Owner role
      await tester.tap(find.text('Hostel / PG Owner'));
      await tester.pumpAndSettle();

      // We are on Owner Auth Screen
      expect(find.text('Hostel / PG Owner Auth'), findsOneWidget);

      // Tap 'Change' button
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      // Must be back on Role Selection screen
      expect(find.text('Welcome to ExtraBite'), findsOneWidget);
    });

    testWidgets('2. User A logs in and sees only User A\'s authenticated data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExtraBiteApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Personal User role
      await tester.tap(find.text('Personal User'));
      await tester.pumpAndSettle();

      // Switch to Signup tab and register User A (Alice)
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Alice Smith');
      await tester.enterText(textFields.at(1), 'alice@example.com');
      await tester.enterText(textFields.at(2), '+91 9111111111');
      await tester.enterText(textFields.at(3), 'secret123');

      await tester.tap(find.text('Create Personal User Account'));
      await tester.pumpAndSettle();

      // On Home screen, header must show dynamic initials 'AS' and not 'PK'
      expect(find.text('AS'), findsOneWidget);
      expect(find.text('PK'), findsNothing);

      // Tap on the header avatar to navigate to Profile
      await tester.tap(find.text('AS'));
      await tester.pumpAndSettle();

      // Verify User A's data is displayed on Profile
      expect(find.text('Alice Smith'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.text('+91 9111111111'), findsOneWidget);

      // Must NOT show developer details or other user details
      expect(find.text('Pavan Kumar'), findsNothing);
      expect(find.text('pavan.kumar@example.com'), findsNothing);
    });

    test('3. User A logs out; User B logs in and never sees User A\'s data', () async {
      final container = ProviderContainer();
      
      // Step A: Login User A (Alice)
      final authNotifier = container.read(authProvider.notifier);
      await authNotifier.signup(
        name: 'Alice Smith',
        email: 'alice@example.com',
        phone: '+91 9111111111',
        password: 'pass',
        role: UserRole.personal,
      );

      var currentState = container.read(authProvider);
      expect(currentState.user?.name, equals('Alice Smith'));

      // Step B: User A Logs out
      await authNotifier.logout();
      currentState = container.read(authProvider);
      expect(currentState.user, isNull);
      expect(currentState.status, equals(AuthStatus.selectingRole));

      // Step C: Login User B (Bob)
      await authNotifier.signup(
        name: 'Bob Johnson',
        email: 'bob@example.com',
        phone: '+91 9222222222',
        password: 'pass',
        role: UserRole.personal,
      );

      currentState = container.read(authProvider);
      expect(currentState.user?.name, equals('Bob Johnson'));
      expect(currentState.user?.email, equals('bob@example.com'));

      // Verify User A's data is completely absent from active session
      expect(currentState.user?.name, isNot(equals('Alice Smith')));
      expect(currentState.user?.email, isNot(equals('alice@example.com')));
    });

    test('4. Reinstall / clear app data resets to Role Selection with zero profile leaks', () async {
      final container = ProviderContainer();
      final authNotifier = container.read(authProvider.notifier);

      // Login Owner User
      await authNotifier.signup(
        name: 'Owner Name',
        email: 'owner@example.com',
        phone: '+91 9333333333',
        password: 'pass',
        role: UserRole.owner,
        propertyName: 'Royal PG',
      );

      expect(container.read(authProvider).user?.name, equals('Owner Name'));

      // Clear app data (simulate fresh reinstall)
      await authNotifier.clearAppData();

      final resetState = container.read(authProvider);
      expect(resetState.status, equals(AuthStatus.selectingRole));
      expect(resetState.user, isNull);
    });

    testWidgets('5. Owner Role onboarding loads Owner Dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ExtraBiteApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Hostel / PG Owner role
      await tester.tap(find.text('Hostel / PG Owner'));
      await tester.pumpAndSettle();

      // Sign up as PG Owner
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Rajesh Kumar');
      await tester.enterText(textFields.at(1), 'rajesh@srisai.com');
      await tester.enterText(textFields.at(2), '+91 9444444444');
      await tester.enterText(textFields.at(3), 'Sri Sai Luxury PG');
      await tester.enterText(textFields.at(4), 'ownerpass');

      final submitBtn = find.text('Create Hostel / PG Owner Account');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Must navigate to Owner Dashboard
      expect(find.text('Sri Sai Luxury PG'), findsWidgets);
      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.text('Active Listings'), findsOneWidget);
    });
  });
}
