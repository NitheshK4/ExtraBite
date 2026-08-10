import '../core/utils/qr_codec.dart';
import '../models/reservation_model.dart';

enum QrVerificationStatus {
  valid,
  malformed,
  expired,
  alreadyRedeemed,
  cancelled,
  wrongOwner,
  notFound,
}

class QrVerificationResult {
  final QrVerificationStatus status;
  final String message;
  final ReservationModel? reservation;
  final QrPayload? payload;

  const QrVerificationResult({
    required this.status,
    required this.message,
    this.reservation,
    this.payload,
  });

  bool get isValid => status == QrVerificationStatus.valid;
}

class QrService {
  /// Validates a scanned QR string against a reservation record and host PG ID
  static QrVerificationResult verifyQrCode({
    required String rawQrString,
    required List<ReservationModel> allReservations,
    required String currentOwnerPgId,
  }) {
    final payload = QrCodec.decode(rawQrString);
    if (payload == null) {
      return const QrVerificationResult(
        status: QrVerificationStatus.malformed,
        message: 'Invalid or tampered QR code pass.',
      );
    }

    if (payload.isExpired) {
      return QrVerificationResult(
        status: QrVerificationStatus.expired,
        message: 'This pickup pass has expired. Pickup window is closed.',
        payload: payload,
      );
    }

    if (payload.pgId != currentOwnerPgId) {
      return QrVerificationResult(
        status: QrVerificationStatus.wrongOwner,
        message: 'This pass belongs to a different PG/Hostel.',
        payload: payload,
      );
    }

    ReservationModel? matchedReservation;
    try {
      matchedReservation = allReservations.firstWhere(
        (r) => r.readableId == payload.reservationId && r.pickupToken == payload.pickupToken,
      );
    } catch (_) {
      matchedReservation = null;
    }

    if (matchedReservation == null) {
      return QrVerificationResult(
        status: QrVerificationStatus.notFound,
        message: 'No matching reservation found in system.',
        payload: payload,
      );
    }

    if (matchedReservation.status == ReservationStatus.pickedUp) {
      return QrVerificationResult(
        status: QrVerificationStatus.alreadyRedeemed,
        message: 'This reservation has already been picked up.',
        reservation: matchedReservation,
        payload: payload,
      );
    }

    if (matchedReservation.status == ReservationStatus.cancelled) {
      return QrVerificationResult(
        status: QrVerificationStatus.cancelled,
        message: 'This reservation was cancelled by the customer.',
        reservation: matchedReservation,
        payload: payload,
      );
    }

    return QrVerificationResult(
      status: QrVerificationStatus.valid,
      message: 'Valid Pickup Pass. Ready for collection.',
      reservation: matchedReservation,
      payload: payload,
    );
  }
}
