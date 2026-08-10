import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';

class QrPayload {
  final int version;
  final String reservationId;
  final String pickupToken;
  final String pgId;
  final int portions;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String signature;

  const QrPayload({
    required this.version,
    required this.reservationId,
    required this.pickupToken,
    required this.pgId,
    required this.portions,
    required this.issuedAt,
    required this.expiresAt,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'v': version,
        'rid': reservationId,
        'tok': pickupToken,
        'pg': pgId,
        'qty': portions,
        'iat': issuedAt.millisecondsSinceEpoch,
        'exp': expiresAt.millisecondsSinceEpoch,
        'sig': signature,
      };

  factory QrPayload.fromJson(Map<String, dynamic> json) {
    return QrPayload(
      version: json['v'] as int? ?? 1,
      reservationId: json['rid'] as String,
      pickupToken: json['tok'] as String,
      pgId: json['pg'] as String,
      portions: json['qty'] as int? ?? 1,
      issuedAt: DateTime.fromMillisecondsSinceEpoch(json['iat'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['exp'] as int),
      signature: json['sig'] as String,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class QrCodec {
  static String generateSignature({
    required String reservationId,
    required String pickupToken,
    required String pgId,
    required DateTime expiresAt,
  }) {
    final raw = '$reservationId|$pickupToken|$pgId|${expiresAt.millisecondsSinceEpoch}|${AppConstants.qrSecretPrefix}';
    final bytes = utf8.encode(raw);
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  static String encode({
    required String reservationId,
    required String pickupToken,
    required String pgId,
    required int portions,
    required DateTime expiresAt,
    DateTime? issuedAt,
  }) {
    final issueTime = issuedAt ?? DateTime.now();
    final signature = generateSignature(
      reservationId: reservationId,
      pickupToken: pickupToken,
      pgId: pgId,
      expiresAt: expiresAt,
    );

    final payload = QrPayload(
      version: AppConstants.qrVersion,
      reservationId: reservationId,
      pickupToken: pickupToken,
      pgId: pgId,
      portions: portions,
      issuedAt: issueTime,
      expiresAt: expiresAt,
      signature: signature,
    );

    return jsonEncode(payload.toJson());
  }

  static QrPayload? decode(String rawString) {
    try {
      final decoded = jsonDecode(rawString) as Map<String, dynamic>;
      final payload = QrPayload.fromJson(decoded);

      // Verify signature integrity
      final expectedSignature = generateSignature(
        reservationId: payload.reservationId,
        pickupToken: payload.pickupToken,
        pgId: payload.pgId,
        expiresAt: payload.expiresAt,
      );

      if (payload.signature != expectedSignature) {
        return null; // Tampered or invalid signature
      }

      return payload;
    } catch (_) {
      return null; // Malformed QR
    }
  }
}
