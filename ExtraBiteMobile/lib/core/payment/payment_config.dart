/// Centralized configuration for Razorpay Payment Gateway
class PaymentConfig {
  PaymentConfig._();

  /// Razorpay API Key ID.
  /// 
  /// How to get your free Test / Live Key:
  /// 1. Log in to https://dashboard.razorpay.com/
  /// 2. Navigate to Settings -> API Keys
  /// 3. Click "Generate Test Key" (No KYC required for testing)
  /// 4. Paste your key ID (starts with `rzp_test_...` or `rzp_live_...`) below:
  static const String razorpayKey = 'rzp_test_TOudtiPsWOdXEu';

  /// Merchant display name on checkout
  static const String merchantName = 'ExtraBite (SavourE)';

  /// Brand theme color hex (#16A34A)
  static const String themeColorHex = '#16A34A';

  /// Default customer contact if not authenticated
  static const String defaultContact = '9876543210';

  /// Default customer email if not authenticated
  static const String defaultEmail = 'customer@savoure.food';

  /// Currency code
  static const String currency = 'INR';

  /// Whether simulated test flow fallback is enabled
  static bool enableTestSimulation = true;
}
