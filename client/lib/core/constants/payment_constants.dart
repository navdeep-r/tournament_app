abstract class PaymentConstants {
  // Replace with real keys from Razorpay dashboard
  static const String razorpayKeyId = 'rzp_live_XXXXXXXXXXXXXXXX';

  // Your UPI VPA registered with Razorpay
  static const String merchantUpiId = 'yourmerchant@razorpay';
  static const String merchantName = 'Tournament Hub';

  // Razorpay brand theme
  static const String brandColorHex = '#C8A96E';

  // UPI app package names (Android)
  static const String gPayPackage = 'com.google.android.apps.nbu.paisa.user';
  static const String phonePePackage = 'com.phonepe.app';
  static const String paytmPackage = 'net.one97.paytm';
  static const String bhimPackage = 'in.org.npci.upiapp';

  // Order expiry window
  static const Duration orderExpiry = Duration(minutes: 15);

  // Polling config for UPI intent return
  static const int pollMaxAttempts = 6;
  static const Duration pollInterval = Duration(seconds: 2);
}
