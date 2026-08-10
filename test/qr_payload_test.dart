import 'package:flutter_test/flutter_test.dart';
import 'package:extrabite_mobile/core/utils/qr_codec.dart';
import 'package:extrabite_mobile/services/qr_service.dart';
import 'package:extrabite_mobile/models/reservation_model.dart';

void main() {
  group('QR Code Payload & Verification Tests', () {
    test('Encodes and decodes QR payload with signature verification', () {
      final expiry = DateTime.now().add(const Duration(hours: 2));
      final raw = QrCodec.encode(
        reservationId: 'EB-99881',
        pickupToken: 'TOK-1234',
        pgId: 'pg_01',
        portions: 2,
        expiresAt: expiry,
      );

      expect(raw.isNotEmpty, true);

      final payload = QrCodec.decode(raw);
      expect(payload, isNotNull);
      expect(payload!.reservationId, 'EB-99881');
      expect(payload.pickupToken, 'TOK-1234');
      expect(payload.pgId, 'pg_01');
      expect(payload.portions, 2);
      expect(payload.isExpired, false);
    });

    test('Rejects tampered or malformed QR strings', () {
      final tampered = '{"v":1,"rid":"EB-99881","tok":"TOK-1234","pg":"pg_01","exp":1790000000,"sig":"fake_sig"}';
      final decoded = QrCodec.decode(tampered);
      expect(decoded, isNull);

      final garbage = 'not-a-valid-json';
      expect(QrCodec.decode(garbage), isNull);
    });

    test('Rejects expired QR pass in verification service', () {
      final pastExpiry = DateTime.now().subtract(const Duration(minutes: 10));
      final expiredRaw = QrCodec.encode(
        reservationId: 'EB-77112',
        pickupToken: 'TOK-5544',
        pgId: 'pg_01',
        portions: 1,
        expiresAt: pastExpiry,
      );

      final result = QrService.verifyQrCode(
        rawQrString: expiredRaw,
        allReservations: [],
        currentOwnerPgId: 'pg_01',
      );

      expect(result.isValid, false);
      expect(result.status, QrVerificationStatus.expired);
    });

    test('Rejects QR pass intended for a different PG owner', () {
      final expiry = DateTime.now().add(const Duration(hours: 1));
      final foreignRaw = QrCodec.encode(
        reservationId: 'EB-33441',
        pickupToken: 'TOK-9988',
        pgId: 'pg_other_hostel',
        portions: 1,
        expiresAt: expiry,
      );

      final result = QrService.verifyQrCode(
        rawQrString: foreignRaw,
        allReservations: [],
        currentOwnerPgId: 'pg_01', // Different host
      );

      expect(result.isValid, false);
      expect(result.status, QrVerificationStatus.wrongOwner);
    });

    test('Prevents duplicate pickup on already redeemed reservation', () {
      final expiry = DateTime.now().add(const Duration(hours: 1));
      final raw = QrCodec.encode(
        reservationId: 'EB-11111',
        pickupToken: 'TOK-2222',
        pgId: 'pg_01',
        portions: 1,
        expiresAt: expiry,
      );

      final redeemedReservation = ReservationModel(
        id: 'res_redeemed',
        readableId: 'EB-11111',
        listingId: 'list_01',
        listingTitle: 'Dinner Thali',
        pgId: 'pg_01',
        pgName: 'Hostel A',
        customerId: 'cust_1',
        customerName: 'Alice',
        customerPhone: '9999999999',
        portionsCount: 1,
        unitPrice: 50,
        totalAmount: 50,
        status: ReservationStatus.pickedUp, // Already picked up
        pickupToken: 'TOK-2222',
        qrPayload: raw,
        pickupStartTime: DateTime.now().subtract(const Duration(hours: 1)),
        pickupDeadline: expiry,
        pickupInstructions: 'counter',
        pgAddress: 'road',
        pgLatitude: 12.9,
        pgLongitude: 77.6,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final result = QrService.verifyQrCode(
        rawQrString: raw,
        allReservations: [redeemedReservation],
        currentOwnerPgId: 'pg_01',
      );

      expect(result.isValid, false);
      expect(result.status, QrVerificationStatus.alreadyRedeemed);
    });
  });
}
