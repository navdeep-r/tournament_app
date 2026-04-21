import 'dart:io';
import 'package:upi_india/upi_india.dart';
import 'package:tournament_app/core/network/api_client.dart';
import 'package:tournament_app/core/constants/api_constants.dart';
import 'package:tournament_app/core/constants/payment_constants.dart';
import 'package:tournament_app/features/payment/data/models/payment_models.dart';

class PaymentRepository {
  final ApiClient _api;
  final UpiIndia _upiIndia = UpiIndia();

  PaymentRepository(this._api);

  // 1. Validate referral code
  Future<ReferralCode> validateReferralCode({
    required String code,
    required String tournamentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (code.toUpperCase() == 'DISCOUNT50') {
      return const ReferralCode(
        code: 'DISCOUNT50',
        discountType: 'fixed',
        discountValue: 5000,
        maxUses: 100,
        usedCount: 0,
        isValid: true,
      );
    }
    throw Exception('Invalid referral code');
  }

  // 2. Create Razorpay order on backend
  Future<PaymentOrder> createPaymentOrder({
    required String tournamentId,
    required String userPhone,
    String? referralCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return PaymentOrder(
      orderId: 'order_dummy_${DateTime.now().millisecondsSinceEpoch}',
      tournamentId: tournamentId,
      tournamentName: 'Dummy Tournament',
      amountPaise: 10000,
      originalAmountPaise: 10000,
      discountPaise: 0,
      currency: 'INR',
      receipt: 'rcpt_dummy',
      userPhone: userPhone,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      status: 'created',
    );
  }

  // 3. Verify payment signature server-side
  Future<PaymentSuccess> verifyPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required String userPhone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return PaymentSuccess(
      razorpayPaymentId: razorpayPaymentId,
      razorpayOrderId: razorpayOrderId,
      razorpaySignature: razorpaySignature,
      userPhone: userPhone,
      amountPaisePaid: 10000,
      tournamentId: 't_dummy',
      queueNumber: 42,
      paidAt: DateTime.now(),
    );
  }

  // 4. Poll order status (for UPI intent return)
  Future<String> getOrderStatus(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'paid'; // Automatically return paid for prototype
  }

  // 5. Detect installed UPI apps
  Future<List<PaymentMethod>> getAvailablePaymentMethods() async {
    final methods = <PaymentMethod>[];

    // Android: detect installed UPI apps
    if (Platform.isAndroid) {
      try {
        final apps =
            await _upiIndia.getAllUpiApps(mandatoryTransactionId: false);
        final appPackages = apps.map((a) => a.packageName.toString()).toSet();

        methods.add(PaymentMethod(
          type: PaymentMethodType.googlePay,
          displayName: 'Google Pay',
          subtitle: 'Instant · Most popular',
          isInstalled: appPackages.contains(PaymentConstants.gPayPackage),
          isRecommended: true,
        ));
        methods.add(PaymentMethod(
          type: PaymentMethodType.phonePe,
          displayName: 'PhonePe',
          subtitle: 'UPI payment',
          isInstalled: appPackages.contains(PaymentConstants.phonePePackage),
          isRecommended: false,
        ));
        methods.add(PaymentMethod(
          type: PaymentMethodType.paytm,
          displayName: 'Paytm',
          subtitle: 'UPI / Wallet',
          isInstalled: appPackages.contains(PaymentConstants.paytmPackage),
          isRecommended: false,
        ));
      } catch (_) {
        // Fall through to defaults
      }
    }

    // BHIM UPI always available (system picker)
    methods.add(const PaymentMethod(
      type: PaymentMethodType.bhimUpi,
      displayName: 'BHIM UPI',
      subtitle: 'Any UPI app',
      isInstalled: true,
      isRecommended: false,
    ));

    // Card & NetBanking always via Razorpay
    methods.add(const PaymentMethod(
      type: PaymentMethodType.razorpayCard,
      displayName: 'Credit / Debit Card',
      subtitle: 'Visa, Mastercard, RuPay',
      isInstalled: true,
      isRecommended: false,
    ));
    methods.add(const PaymentMethod(
      type: PaymentMethodType.netBanking,
      displayName: 'Net Banking',
      subtitle: 'All major banks',
      isInstalled: true,
      isRecommended: false,
    ));

    return methods;
  }
}
