import 'package:flutter_test/flutter_test.dart';
import 'package:extrabite_mobile/models/user_model.dart';

void main() {
  group('Role-Based Route Guard Logic Tests', () {
    String? evaluateRouteGuard({
      required UserModel? user,
      required String targetPath,
    }) {
      if (targetPath == '/onboarding' || targetPath == '/role-selection' || targetPath == '/auth') {
        return null;
      }

      if (user == null) {
        return '/role-selection';
      }

      if (targetPath.startsWith('/owner-') || targetPath == '/create-listing' || targetPath == '/qr-scanner') {
        if (user.role != UserRole.pgOwner && user.role != UserRole.admin) {
          return '/discover';
        }
      }

      if (targetPath.startsWith('/admin-')) {
        if (user.role != UserRole.admin) {
          return user.role == UserRole.pgOwner ? '/owner-dashboard' : '/discover';
        }
      }

      return null;
    }

    test('Customer is blocked from PG Owner and Admin routes', () {
      const customer = UserModel(
        id: 'c1',
        email: 'c@eb.com',
        fullName: 'Customer',
        role: UserRole.customer,
      );

      expect(evaluateRouteGuard(user: customer, targetPath: '/owner-dashboard'), '/discover');
      expect(evaluateRouteGuard(user: customer, targetPath: '/create-listing'), '/discover');
      expect(evaluateRouteGuard(user: customer, targetPath: '/admin-dashboard'), '/discover');
      expect(evaluateRouteGuard(user: customer, targetPath: '/discover'), isNull);
      expect(evaluateRouteGuard(user: customer, targetPath: '/reservations'), isNull);
    });

    test('PG Owner can access owner routes but blocked from admin routes', () {
      const owner = UserModel(
        id: 'o1',
        email: 'o@eb.com',
        fullName: 'Owner',
        role: UserRole.pgOwner,
      );

      expect(evaluateRouteGuard(user: owner, targetPath: '/owner-dashboard'), isNull);
      expect(evaluateRouteGuard(user: owner, targetPath: '/create-listing'), isNull);
      expect(evaluateRouteGuard(user: owner, targetPath: '/admin-dashboard'), '/owner-dashboard');
    });

    test('Admin can access all routes', () {
      const admin = UserModel(
        id: 'a1',
        email: 'a@eb.com',
        fullName: 'Admin',
        role: UserRole.admin,
      );

      expect(evaluateRouteGuard(user: admin, targetPath: '/admin-dashboard'), isNull);
      expect(evaluateRouteGuard(user: admin, targetPath: '/admin-approvals'), isNull);
      expect(evaluateRouteGuard(user: admin, targetPath: '/owner-dashboard'), isNull);
      expect(evaluateRouteGuard(user: admin, targetPath: '/discover'), isNull);
    });
  });
}
