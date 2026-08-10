import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:extrabite_mobile/shared/widgets/pay_at_pickup_badge.dart';
import 'package:extrabite_mobile/core/constants/app_constants.dart';

void main() {
  group('Pay at Pickup Invariant Tests', () {
    testWidgets('PayAtPickupBadge renders "Pay at pickup" clearly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PayAtPickupBadge(showDescription: true),
          ),
        ),
      );

      // Verify Pay at pickup label
      expect(find.text(AppConstants.paymentMethodLabel), findsOneWidget);
      expect(find.text(AppConstants.paymentInstruction), findsOneWidget);

      // Verify no online payment text
      expect(find.textContaining('UPI'), findsNothing);
      expect(find.textContaining('Razorpay'), findsNothing);
      expect(find.textContaining('Credit Card'), findsNothing);
      expect(find.textContaining('Wallet'), findsNothing);
    });

    testWidgets('Compact PayAtPickupBadge renders in listing cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PayAtPickupBadge(isCompact: true),
          ),
        ),
      );

      expect(find.text(AppConstants.paymentMethodLabel), findsOneWidget);
    });
  });
}
