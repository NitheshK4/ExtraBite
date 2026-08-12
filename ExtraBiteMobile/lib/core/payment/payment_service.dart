import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'payment_config.dart';

typedef PaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef PaymentFailureCallback = void Function(PaymentFailureResponse response);
typedef ExternalWalletCallback = void Function(ExternalWalletResponse response);

/// PaymentService manages Razorpay checkout sessions, UPI Intent triggers,
/// and automated real-time payment response callbacks.
class PaymentService {
  Razorpay? _razorpay;
  PaymentSuccessCallback? _onSuccess;
  PaymentFailureCallback? _onFailure;
  ExternalWalletCallback? _onExternalWallet;
  bool _isInitialized = false;

  void initialize({
    required PaymentSuccessCallback onSuccess,
    required PaymentFailureCallback onFailure,
    ExternalWalletCallback? onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;

    if (!kIsWeb) {
      try {
        _razorpay ??= Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
        _isInitialized = true;
      } catch (e) {
        debugPrint('[PaymentService] Razorpay native init notice: $e');
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('[PaymentService] Payment Success: ${response.paymentId}');
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('[PaymentService] Payment Cancelled/Error: [${response.code}] ${response.message}');
    _onFailure?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[PaymentService] External Wallet Selected: ${response.walletName}');
    _onExternalWallet?.call(response);
  }

  /// Opens the Razorpay Standard Checkout / UPI Intent Modal
  Future<bool> startPayment({
    required double amount,
    required String orderTitle,
    String? orderId,
    String? customerContact,
    String? customerEmail,
  }) async {
    final amountInPaise = (amount * 100).round();
    final txnReceiptId = 'EB_TXN_${DateTime.now().millisecondsSinceEpoch}';

    final options = <String, dynamic>{
      'key': PaymentConfig.razorpayKey,
      'amount': amountInPaise,
      'name': PaymentConfig.merchantName,
      'description': orderTitle,
      if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
      'currency': PaymentConfig.currency,
      'timeout': 300, // 5 minutes timeout
      'prefill': {
        'contact': customerContact ?? PaymentConfig.defaultContact,
        'email': customerEmail ?? PaymentConfig.defaultEmail,
        'method': 'upi', // Pre-selects & prioritizes UPI payment tab in Razorpay Checkout
      },
      'theme': {
        'color': PaymentConfig.themeColorHex,
      },
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
      'send_sms_hash': true,
      'notes': {
        'receipt': txnReceiptId,
        'app': 'ExtraBite (SavourE)',
      },
    };

    if (_isInitialized && _razorpay != null) {
      try {
        _razorpay!.open(options);
        return true;
      } catch (e) {
        debugPrint('[PaymentService] Razorpay open failed: $e');
        return false;
      }
    } else {
      debugPrint('[PaymentService] Running in fallback/testing mode.');
      return false;
    }
  }

  /// Helper to trigger payment success simulation directly for test suites
  void triggerSimulatedSuccess({String? paymentId, String? orderId}) {
    final response = PaymentSuccessResponse(
      paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
      orderId ?? 'order_${DateTime.now().millisecondsSinceEpoch}',
      'sig_${DateTime.now().millisecondsSinceEpoch}',
      null,
    );
    _handlePaymentSuccess(response);
  }

  /// Helper to trigger payment cancellation/failure simulation directly for test suites
  void triggerSimulatedFailure({int? code, String? message}) {
    final response = PaymentFailureResponse(
      code ?? Razorpay.PAYMENT_CANCELLED,
      message ?? 'Payment cancelled by user',
      null,
    );
    _handlePaymentError(response);
  }

  /// Cleans up listeners when widget disposes
  void dispose() {
    try {
      _razorpay?.clear();
    } catch (_) {}
    _isInitialized = false;
  }
}
