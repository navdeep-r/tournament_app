// ═══ payment_order_model.dart ══════════════════════════════════════════════════
class PaymentOrder {
  final String orderId;
  final String tournamentId;
  final String tournamentName;
  final int amountPaise;
  final int originalAmountPaise;
  final int discountPaise;
  final String currency;
  final String receipt;
  final String userPhone;
  final String? referralCode;
  final DateTime expiresAt;
  final String status;

  const PaymentOrder({
    required this.orderId,
    required this.tournamentId,
    required this.tournamentName,
    required this.amountPaise,
    required this.originalAmountPaise,
    required this.discountPaise,
    required this.currency,
    required this.receipt,
    required this.userPhone,
    this.referralCode,
    required this.expiresAt,
    required this.status,
  });

  double get amountRupees => amountPaise / 100;
  double get originalRupees => originalAmountPaise / 100;
  double get discountRupees => discountPaise / 100;
  bool get hasDiscount => discountPaise > 0;
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory PaymentOrder.fromJson(Map<String, dynamic> json) => PaymentOrder(
        orderId: json['order_id'] as String,
        tournamentId: json['tournament_id'] as String,
        tournamentName: json['tournament_name'] as String,
        amountPaise: json['amount_paise'] as int,
        originalAmountPaise: json['original_amount_paise'] as int,
        discountPaise: json['discount_paise'] as int? ?? 0,
        currency: json['currency'] as String? ?? 'INR',
        receipt: json['receipt'] as String,
        userPhone: json['user_phone'] as String,
        referralCode: json['referral_code'] as String?,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        status: json['status'] as String,
      );
}

// ═══ referral_model.dart ══════════════════════════════════════════════════════
class ReferralCode {
  final String code;
  final String discountType; // "percent" | "flat"
  final int discountValue;
  final int maxUses;
  final int usedCount;
  final bool isValid;
  final String? errorMessage;

  const ReferralCode({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.maxUses,
    required this.usedCount,
    required this.isValid,
    this.errorMessage,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) => ReferralCode(
        code: json['code'] as String,
        discountType: json['discount_type'] as String,
        discountValue: json['discount_value'] as int,
        maxUses: json['max_uses'] as int? ?? 0,
        usedCount: json['used_count'] as int? ?? 0,
        isValid: json['is_valid'] as bool,
        errorMessage: json['error_message'] as String?,
      );
}

// ═══ payment_result_model.dart ════════════════════════════════════════════════
sealed class PaymentResult {}

class PaymentSuccess extends PaymentResult {
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;
  final String userPhone;
  final int amountPaisePaid;
  final String tournamentId;
  final int queueNumber;
  final DateTime paidAt;

  PaymentSuccess({
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
    required this.userPhone,
    required this.amountPaisePaid,
    required this.tournamentId,
    required this.queueNumber,
    required this.paidAt,
  });

  factory PaymentSuccess.fromJson(Map<String, dynamic> json) => PaymentSuccess(
        razorpayPaymentId: json['razorpay_payment_id'] as String? ?? '',
        razorpayOrderId: json['razorpay_order_id'] as String? ?? '',
        razorpaySignature: json['razorpay_signature'] as String? ?? '',
        userPhone: json['user_phone'] as String? ?? '',
        amountPaisePaid: json['amount_paise_paid'] as int? ?? 0,
        tournamentId: json['tournament_id'] as String,
        queueNumber: json['queue_number'] as int,
        paidAt: DateTime.parse(json['paid_at'] as String),
      );
}

class PaymentFailure extends PaymentResult {
  final String errorCode;
  final String errorDescription;
  final String errorSource;
  final String razorpayOrderId;

  PaymentFailure({
    required this.errorCode,
    required this.errorDescription,
    required this.errorSource,
    required this.razorpayOrderId,
  });
}

// ═══ payment_method_model.dart ════════════════════════════════════════════════
enum PaymentMethodType {
  googlePay,
  phonePe,
  paytm,
  bhimUpi,
  anyUpi,
  razorpayCard,
  netBanking,
}

class PaymentMethod {
  final PaymentMethodType type;
  final String displayName;
  final String subtitle;
  final bool isInstalled;
  final bool isRecommended;

  const PaymentMethod({
    required this.type,
    required this.displayName,
    required this.subtitle,
    required this.isInstalled,
    required this.isRecommended,
  });
}

// ═══ payment_status enum ══════════════════════════════════════════════════════
enum PaymentStatus {
  idle,
  loadingMethods,
  phoneVerification,
  validatingReferral,
  creatingOrder,
  processing,
  success,
  failure,
}
