import 'package:flutter_test/flutter_test.dart';
import 'package:extrabite_mobile/models/order_type.dart';
import 'package:extrabite_mobile/models/reservation.dart';
import 'package:extrabite_mobile/models/food_listing.dart';

void main() {

  group('OrderType & Reservation Billing Tests', () {
    test('OrderType extension correctly handles display names, codes, and parsing', () {
      expect(OrderType.dineIn.displayName, equals('Dine In'));
      expect(OrderType.dineIn.code, equals('dine_in'));

      expect(OrderType.takeAway.displayName, equals('Take Away'));
      expect(OrderType.takeAway.code, equals('take_away'));

      expect(OrderTypeExtension.fromCode('dine_in'), equals(OrderType.dineIn));
      expect(OrderTypeExtension.fromCode('take_away'), equals(OrderType.takeAway));
      expect(OrderTypeExtension.fromCode(null), isNull);
      expect(OrderTypeExtension.fromCode('unknown'), isNull);
    });

    test('Reservation model correctly serializes and deserializes order_type from Supabase map', () {
      final now = DateTime.now();
      
      final dineInMap = {
        'readable_id': 'EB-10001',
        'listing_id': 'fl_1',
        'title': 'Veg Meals',
        'pg_name': 'Sri Sai PG',
        'portions_count': 2,
        'total_amount': 60.0,
        'order_type': 'dine_in',
        'status': 'reserved',
        'created_at': now.toIso8601String(),
      };

      final dineInRes = Reservation.fromMap(dineInMap);
      expect(dineInRes.orderType, equals(OrderType.dineIn));
      expect(dineInRes.orderTypeDisplayName, equals('Dine In'));
      expect(dineInRes.toMap()['order_type'], equals('dine_in'));

      final takeAwayMap = {
        'readable_id': 'EB-10002',
        'listing_id': 'fl_2',
        'title': 'Biryani',
        'pg_name': 'Lakshmi Hostel',
        'portions_count': 1,
        'total_amount': 80.0,
        'order_type': 'take_away',
        'status': 'reserved',
        'created_at': now.toIso8601String(),
      };

      final takeAwayRes = Reservation.fromMap(takeAwayMap);
      expect(takeAwayRes.orderType, equals(OrderType.takeAway));
      expect(takeAwayRes.orderTypeDisplayName, equals('Take Away'));
      expect(takeAwayRes.toMap()['order_type'], equals('take_away'));
    });

    test('Reservation maintains 100% backward compatibility for legacy records with null order_type', () {
      final now = DateTime.now();

      final legacyMap = {
        'readable_id': 'EB-10000',
        'listing_id': 'fl_0',
        'title': 'Thali',
        'pg_name': 'Old PG',
        'portions_count': 1,
        'total_amount': 50.0,
        'order_type': null, // Legacy bill record
        'status': 'completed',
        'created_at': now.toIso8601String(),
      };

      final legacyRes = Reservation.fromMap(legacyMap);
      expect(legacyRes.orderType, isNull);
      expect(legacyRes.orderTypeDisplayName, equals('Legacy Order'));
      expect(legacyRes.toMap()['order_type'], isNull);
      expect(legacyRes.isPrepaid, isTrue);
      expect(legacyRes.amountPaid, equals(50.0));
      expect(legacyRes.paymentStatus, equals('paid'));
    });

    test('Reservation model supports and serializes prepaid online payment method and status', () {
      final now = DateTime.now();

      final onlineMap = {
        'readable_id': 'EB-20001',
        'listing_id': 'fl_99',
        'title': 'Butter Chicken',
        'pg_name': 'Green PG',
        'portions_count': 2,
        'amount_paid': 150.0,
        'order_type': 'take_away',
        'payment_status': 'paid',
        'payment_method': 'Paytm UPI (Prepaid)',
        'status': 'reserved',
        'created_at': now.toIso8601String(),
      };

      final res = Reservation.fromMap(onlineMap);
      expect(res.isPrepaid, isTrue);
      expect(res.paymentStatus, equals('paid'));
      expect(res.paymentMethod, equals('Paytm UPI (Prepaid)'));
      expect(res.amountPaid, equals(150.0));
      expect(res.toMap()['payment_status'], equals('paid'));
      expect(res.toMap()['payment_method'], equals('Paytm UPI (Prepaid)'));
      expect(res.toMap()['amount_paid'], equals(150.0));

      final phonePeMap = {
        'readable_id': 'EB-20002',
        'listing_id': 'fl_100',
        'title': 'Paneer Biryani',
        'pg_name': 'Sai PG',
        'portions_count': 1,
        'amount_paid': 80.0,
        'order_type': 'dine_in',
        'payment_status': 'paid',
        'payment_method': 'PhonePe UPI (Prepaid)',
        'status': 'reserved',
        'created_at': now.toIso8601String(),
      };

      final phonePeRes = Reservation.fromMap(phonePeMap);
      expect(phonePeRes.paymentMethod, equals('PhonePe UPI (Prepaid)'));
      expect(phonePeRes.isPrepaid, isTrue);

      final razorpayMap = {
        'readable_id': 'EB-30003',
        'listing_id': 'fl_200',
        'title': 'South Indian Meals',
        'pg_name': 'Green PG',
        'portions_count': 2,
        'amount_paid': 120.0,
        'order_type': 'take_away',
        'payment_status': 'paid',
        'payment_method': 'Razorpay UPI & Cards (Prepaid)',
        'status': 'reserved',
        'created_at': now.toIso8601String(),
      };

      final razorpayRes = Reservation.fromMap(razorpayMap);
      expect(razorpayRes.paymentMethod, equals('Razorpay UPI & Cards (Prepaid)'));
      expect(razorpayRes.isPrepaid, isTrue);
      expect(razorpayRes.amountPaid, equals(120.0));
      expect(razorpayRes.toMap()['payment_method'], equals('Razorpay UPI & Cards (Prepaid)'));
    });


    test('FoodListing model correctly serializes, deserializes, and defaults allowsDineIn', () {
      // Case 1: Dine-in allowed listing
      final dineInMap = {
        'id': 'fl_dine',
        'title': 'Veg Thali',
        'description': 'Fresh Meals',
        'pg_id': 'pg_1',
        'propertyName': 'Sai Mess',
        'locationAddress': 'Gate 2',
        'distanceKm': 0.5,
        'category': 'Lunch',
        'dietary_type': 'vegetarian',
        'original_price': 80.0,
        'discounted_price': 40.0,
        'available_portions': 5,
        'allows_dine_in': true,
        'verificationStatus': 'verified',
        'status': 'active',
      };

      final dineInFood = FoodListing.fromMap(dineInMap);
      expect(dineInFood.allowsDineIn, isTrue);
      expect(dineInFood.toMap()['allows_dine_in'], isTrue);

      // Case 2: Takeaway only listing (Dine-in NOT allowed)
      final takeawayMap = {
        'id': 'fl_takeaway',
        'title': 'Paneer Biryani',
        'description': 'Parcel',
        'pg_id': 'pg_2',
        'propertyName': 'Royal PG',
        'locationAddress': 'Gate 1',
        'distanceKm': 1.0,
        'category': 'Dinner',
        'dietary_type': 'vegetarian',
        'original_price': 120.0,
        'discounted_price': 60.0,
        'available_portions': 3,
        'allows_dine_in': false,
        'verificationStatus': 'verified',
        'status': 'active',
      };

      final takeawayFood = FoodListing.fromMap(takeawayMap);
      expect(takeawayFood.allowsDineIn, isFalse);
      expect(takeawayFood.toMap()['allows_dine_in'], isFalse);

      // Case 3: Defaults to true for backward compatibility
      final defaultFood = FoodListing.fromMap({
        'id': 'fl_legacy',
        'title': 'Old Meal',
      });
      expect(defaultFood.allowsDineIn, isTrue);

      // Case 4: copyWith allowsDineIn
      final updatedFood = dineInFood.copyWith(allowsDineIn: false);
      expect(updatedFood.allowsDineIn, isFalse);
    });
  });
}
