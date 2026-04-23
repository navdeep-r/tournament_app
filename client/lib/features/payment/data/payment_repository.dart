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

  // 0. Send OTP to phone
  Future<void> sendOtp({required String phone}) async {
    try {
      await _api.post(
        ApiConstants.authPhoneSendOtp,
        data: {'phone': phone},
      );
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  // 1. Validate referral code
  Future<ReferralCode> validateReferralCode({
    required String code,
    required String tournamentId,
  }) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw Exception('Referral code cannot be empty');
    }
    try {
      final response = await _api.post(
        ApiConstants.tournamentReferralValidate(tournamentId),
        data: {'code': normalized},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return ReferralCode.fromJson(data);
    } catch (e) {
      throw Exception('Invalid referral code');
    }
  }

  // 2. Register user for tournament
  Future<PaymentOrder> registerForTournament({
    required String tournamentId,
    required String userPhone,
    String? referralCode,
  }) async {
    try {
      final response = await _api.post(
        ApiConstants.tournamentRegister(tournamentId),
        data: {
          'phone': userPhone,
          'referral_code': referralCode,
        },
      );

      final data = (response.data['data'] ?? response.data) as Map<String, dynamic>;
      final now = DateTime.now();
      return PaymentOrder(
        orderId: data['order_id']?.toString() ?? data['id'].toString(),
        tournamentId: tournamentId,
        tournamentName: data['tournament_name']?.toString() ?? 'Tournament',
        amountPaise: (data['amount_paise'] as num?)?.toInt() ?? 0,
        originalAmountPaise: (data['original_amount_paise'] as num?)?.toInt() ?? 0,
        discountPaise: data['discount_paise'] ?? 0,
        currency: 'INR',
        receipt: data['receipt']?.toString() ?? 'manual_receipt',
        userPhone: userPhone,
        expiresAt: data['expires_at'] != null
            ? DateTime.parse(data['expires_at'].toString())
            : now.add(const Duration(minutes: 15)),
        status: data['status']?.toString() ?? 'created',
      );
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  // Legacy method for compatibility
  Future<PaymentOrder> createPaymentOrder({
    required String tournamentId,
    required String userPhone,
    String? referralCode,
  }) async {
    return registerForTournament(
      tournamentId: tournamentId,
      userPhone: userPhone,
      referralCode: referralCode,
    );
  }

  // 3. Verify payment signature server-side
  Future<PaymentSuccess> verifyPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required String userPhone,
  }) async {
    try {
      final response = await _api.post(
        '/payments/verify',
        data: {
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_signature': razorpaySignature,
          'phone': userPhone,
        },
      );

      final data = response.data;
      return PaymentSuccess(
        razorpayPaymentId: data['razorpay_payment_id'],
        razorpayOrderId: data['razorpay_order_id'],
        razorpaySignature: data['razorpay_signature'],
        userPhone: data['phone'],
        amountPaisePaid: data['amount_paid_paise'],
        tournamentId: data['tournament_id'],
        queueNumber: data['queue_number'],
        paidAt: DateTime.parse(data['paid_at']),
      );
    } catch (e) {
      throw Exception('Payment verification failed: $e');
    }
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
