import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:upi_india/upi_india.dart';
import '../../../core/constants/payment_constants.dart';
import '../data/payment_repository.dart';
import '../data/models/payment_models.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class PaymentEvent {}

class PaymentInitRequested extends PaymentEvent {
  final String tournamentId;
  PaymentInitRequested(this.tournamentId);
}

class PaymentPhoneChanged extends PaymentEvent {
  final String phone;
  PaymentPhoneChanged(this.phone);
}

class PaymentPhoneSubmitted extends PaymentEvent {}

class PaymentSendOtpRequested extends PaymentEvent {
  final String phone;
  PaymentSendOtpRequested(this.phone);
}

class PaymentOtpChanged extends PaymentEvent {
  final String otp;
  PaymentOtpChanged(this.otp);
}

class PaymentOtpVerified extends PaymentEvent {}

class PaymentReferralCodeChanged extends PaymentEvent {
  final String code;
  PaymentReferralCodeChanged(this.code);
}

class PaymentReferralSubmitted extends PaymentEvent {
  final String code;
  PaymentReferralSubmitted(this.code);
}

class PaymentReferralRemoved extends PaymentEvent {}

class PaymentMethodSelected extends PaymentEvent {
  final PaymentMethodType method;
  PaymentMethodSelected(this.method);
}

class PaymentCreateOrder extends PaymentEvent {}

class PaymentInitiateRequested extends PaymentEvent {}

class PaymentSucceeded extends PaymentEvent {
  final String paymentId;
  final String orderId;
  final String signature;
  PaymentSucceeded(this.paymentId, this.orderId, this.signature);
}

class PaymentFailed extends PaymentEvent {
  final String errorCode;
  final String description;
  final String source;
  PaymentFailed(this.errorCode, this.description, {this.source = 'unknown'});
}

class PaymentRetryRequested extends PaymentEvent {}

// ── State ─────────────────────────────────────────────────────────────────────
class PaymentState {
  final String tournamentId;
  final String phone;
  final bool isPhoneValid;
  final bool isPhoneVerified;
  final bool isOtpSent;
  final String otp;
  final String referralCode;
  final ReferralCode? appliedReferral;
  final bool isValidatingReferral;
  final String? referralError;
  final List<PaymentMethod> availableMethods;
  final PaymentMethodType? selectedMethod;
  final PaymentOrder? currentOrder;
  final int originalAmountPaise;
  final int discountAmountPaise;
  final int finalAmountPaise;
  final PaymentStatus status;
  final PaymentResult? result;
  final String? errorMessage;
  final int currentStep; // 0, 1, 2

  const PaymentState({
    this.tournamentId = '',
    this.phone = '',
    this.isPhoneValid = false,
    this.isPhoneVerified = false,
    this.isOtpSent = false,
    this.otp = '',
    this.referralCode = '',
    this.appliedReferral,
    this.isValidatingReferral = false,
    this.referralError,
    this.availableMethods = const [],
    this.selectedMethod,
    this.currentOrder,
    this.originalAmountPaise = 0,
    this.discountAmountPaise = 0,
    this.finalAmountPaise = 0,
    this.status = PaymentStatus.idle,
    this.result,
    this.errorMessage,
    this.currentStep = 0,
  });

  PaymentState copyWith({
    String? tournamentId,
    String? phone,
    bool? isPhoneValid,
    bool? isPhoneVerified,
    bool? isOtpSent,
    String? otp,
    String? referralCode,
    ReferralCode? appliedReferral,
    bool clearAppliedReferral = false,
    bool? isValidatingReferral,
    String? referralError,
    List<PaymentMethod>? availableMethods,
    PaymentMethodType? selectedMethod,
    PaymentOrder? currentOrder,
    int? originalAmountPaise,
    int? discountAmountPaise,
    int? finalAmountPaise,
    PaymentStatus? status,
    PaymentResult? result,
    String? errorMessage,
    int? currentStep,
  }) =>
      PaymentState(
        tournamentId: tournamentId ?? this.tournamentId,
        phone: phone ?? this.phone,
        isPhoneValid: isPhoneValid ?? this.isPhoneValid,
        isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
        isOtpSent: isOtpSent ?? this.isOtpSent,
        otp: otp ?? this.otp,
        referralCode: referralCode ?? this.referralCode,
        appliedReferral:
            clearAppliedReferral ? null : (appliedReferral ?? this.appliedReferral),
        isValidatingReferral: isValidatingReferral ?? this.isValidatingReferral,
        referralError: referralError,
        availableMethods: availableMethods ?? this.availableMethods,
        selectedMethod: selectedMethod ?? this.selectedMethod,
        currentOrder: currentOrder ?? this.currentOrder,
        originalAmountPaise: originalAmountPaise ?? this.originalAmountPaise,
        discountAmountPaise: discountAmountPaise ?? this.discountAmountPaise,
        finalAmountPaise: finalAmountPaise ?? this.finalAmountPaise,
        status: status ?? this.status,
        result: result ?? this.result,
        errorMessage: errorMessage,
        currentStep: currentStep ?? this.currentStep,
      );

  String get formattedFinalAmount =>
      '₹${(finalAmountPaise / 100).toStringAsFixed(2)}';
  String get formattedOriginalAmount =>
      '₹${(originalAmountPaise / 100).toStringAsFixed(2)}';
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repo;
  final Razorpay _razorpay = Razorpay();
  final UpiIndia _upiIndia = UpiIndia();

  PaymentBloc(this._repo) : super(const PaymentState()) {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    on<PaymentInitRequested>(_onInit);
    on<PaymentPhoneChanged>(_onPhoneChanged);
    on<PaymentPhoneSubmitted>(_onPhoneSubmitted);
    on<PaymentSendOtpRequested>(_onSendOtp);
    on<PaymentOtpChanged>(_onOtpChanged);
    on<PaymentOtpVerified>(_onOtpVerified);
    on<PaymentReferralCodeChanged>(_onReferralCodeChanged);
    on<PaymentReferralSubmitted>(_onReferralSubmitted);
    on<PaymentReferralRemoved>(_onReferralRemoved);
    on<PaymentMethodSelected>(_onMethodSelected);
    on<PaymentCreateOrder>(_onCreateOrder);
    on<PaymentInitiateRequested>(_onInitiatePayment);
    on<PaymentSucceeded>(_onSuccess);
    on<PaymentFailed>(_onFailure);
    on<PaymentRetryRequested>(_onRetry);
  }

  Future<void> _onInit(
      PaymentInitRequested event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(
        tournamentId: event.tournamentId,
        status: PaymentStatus.loadingMethods));
    final methods = await _repo.getAvailablePaymentMethods();
    final recommended = methods.firstWhere(
        (m) => m.isRecommended && m.isInstalled,
        orElse: () => methods.first);
    emit(state.copyWith(
      availableMethods: methods,
      selectedMethod: recommended.type,
      status: PaymentStatus.idle,
    ));
  }

  void _onPhoneChanged(
      PaymentPhoneChanged event, Emitter<PaymentState> emit) {
    final cleaned = event.phone.replaceAll(RegExp(r'[^\d]'), '');
    final isValid = cleaned.length == 10 &&
        RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned);
    emit(state.copyWith(phone: cleaned, isPhoneValid: isValid));
  }

  void _onPhoneSubmitted(
      PaymentPhoneSubmitted event, Emitter<PaymentState> emit) {
    if (state.isPhoneValid) {
      emit(state.copyWith(isOtpSent: true, status: PaymentStatus.phoneVerification));
    }
  }

  Future<void> _onSendOtp(
      PaymentSendOtpRequested event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(status: PaymentStatus.phoneVerification));
    try {
      await _repo.sendOtp(phone: event.phone);
      emit(state.copyWith(
        isOtpSent: true,
        status: PaymentStatus.idle,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PaymentStatus.idle,
        errorMessage: 'Failed to send OTP. Try again.',
      ));
    }
  }

  void _onOtpChanged(
      PaymentOtpChanged event, Emitter<PaymentState> emit) {
    emit(state.copyWith(otp: event.otp, errorMessage: null));
  }

  void _onOtpVerified(
      PaymentOtpVerified event, Emitter<PaymentState> emit) {
    emit(state.copyWith(isPhoneVerified: true, currentStep: 1));
  }

  void _onReferralCodeChanged(
      PaymentReferralCodeChanged event, Emitter<PaymentState> emit) {
    emit(state.copyWith(
      referralCode: event.code.trim().toUpperCase(),
      referralError: null,
      errorMessage: null,
    ));
  }

  Future<void> _onReferralSubmitted(
      PaymentReferralSubmitted event, Emitter<PaymentState> emit) async {
    if (event.code.trim().isEmpty) {
      emit(state.copyWith(referralError: 'Please enter a referral code'));
      return;
    }
    emit(state.copyWith(
        isValidatingReferral: true, referralError: null));
    try {
      final normalized = event.code.trim().toUpperCase();
      final referral = await _repo.validateReferralCode(
        code: normalized,
        tournamentId: state.tournamentId,
      );
      if (referral.isValid) {
        emit(state.copyWith(
          appliedReferral: referral,
          originalAmountPaise: referral.originalAmountPaise,
          discountAmountPaise: referral.discountAmountPaise,
          finalAmountPaise: referral.finalAmountPaise,
          isValidatingReferral: false,
          referralCode: normalized,
          referralError: null,
        ));
      } else {
        emit(state.copyWith(
          isValidatingReferral: false,
          referralError: referral.errorMessage ?? 'Invalid referral code',
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        isValidatingReferral: false,
        referralError: 'Invalid or non-existent referral code',
      ));
    }
  }

  void _onReferralRemoved(
      PaymentReferralRemoved event, Emitter<PaymentState> emit) {
    emit(state.copyWith(
      referralCode: '',
      clearAppliedReferral: true,
      discountAmountPaise: 0,
      finalAmountPaise: state.originalAmountPaise,
      referralError: null,
    ));
  }

  void _onMethodSelected(
      PaymentMethodSelected event, Emitter<PaymentState> emit) {
    emit(state.copyWith(selectedMethod: event.method));
  }

  Future<void> _onCreateOrder(
      PaymentCreateOrder event, Emitter<PaymentState> emit) async {
    emit(state.copyWith(status: PaymentStatus.creatingOrder));
    try {
      final order = await _repo.createPaymentOrder(
        tournamentId: state.tournamentId,
        userPhone: '+91${state.phone}',
        referralCode: state.appliedReferral?.code,
      );

      if (order.isFree) {
        final freeSuccess = PaymentSuccess(
          razorpayPaymentId: order.orderId,
          razorpayOrderId: order.orderId,
          razorpaySignature: 'FREE_REGISTRATION',
          userPhone: '+91${state.phone}',
          amountPaisePaid: order.amountPaise,
          tournamentId: order.tournamentId,
          queueNumber: order.queueNumber ?? 0,
          paidAt: order.registeredAt ?? DateTime.now(),
        );
        emit(state.copyWith(
          currentOrder: order,
          originalAmountPaise: order.originalAmountPaise,
          discountAmountPaise: order.discountPaise,
          finalAmountPaise: order.amountPaise,
          status: PaymentStatus.success,
          result: freeSuccess,
        ));
        return;
      }

      emit(state.copyWith(
        currentOrder: order,
        originalAmountPaise: order.originalAmountPaise,
        discountAmountPaise: order.discountPaise,
        finalAmountPaise: order.amountPaise,
        currentStep: 2,
        status: PaymentStatus.idle,
      ));
    } catch (e) {
      final raw = e.toString();
      final cleaned = raw.startsWith('Exception: ')
          ? raw.substring('Exception: '.length)
          : raw;
      final message = cleaned.toLowerCase().contains('referral')
          ? 'Invalid or non-existent referral code'
          : cleaned;
      emit(state.copyWith(
        status: PaymentStatus.idle,
        referralError: message,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onInitiatePayment(
      PaymentInitiateRequested event, Emitter<PaymentState> emit) async {
    final order = state.currentOrder;
    if (order == null) return;
    emit(state.copyWith(status: PaymentStatus.processing));

    if (_isDirectUpiMethod(state.selectedMethod) && Platform.isAndroid) {
      await _launchDirectUpi(order, state.selectedMethod!);
    } else {
      _openRazorpay(order);
    }
  }

  bool _isDirectUpiMethod(PaymentMethodType? type) =>
      type == PaymentMethodType.googlePay ||
      type == PaymentMethodType.phonePe ||
      type == PaymentMethodType.paytm;

  UpiApp _upiAppFor(PaymentMethodType type) => switch (type) {
        PaymentMethodType.phonePe => UpiApp.phonePe,
        PaymentMethodType.paytm => UpiApp.paytm,
        _ => UpiApp.googlePay,
      };

  Future<void> _launchDirectUpi(
      PaymentOrder order, PaymentMethodType method) async {
    try {
      final response = await _upiIndia.startTransaction(
        app: _upiAppFor(method),
        receiverUpiId: PaymentConstants.merchantUpiId,
        receiverName: PaymentConstants.merchantName,
        transactionRefId: order.orderId,
        transactionNote: 'Entry: ${order.tournamentName}',
        amount: order.amountRupees,
      );
      _handleUpiResponse(response, order);
    } catch (e) {
      add(PaymentFailed('UPI_ERROR', e.toString(), source: 'upi'));
    }
  }

  void _handleUpiResponse(UpiResponse? response, PaymentOrder order) {
    if (response == null) {
      add(PaymentFailed('NULL_RESPONSE', 'No response from UPI app'));
      return;
    }
    if (response.status == UpiPaymentStatus.SUCCESS) {
      add(PaymentSucceeded(
          response.transactionId ?? '', order.orderId, ''));
    } else if (response.status == UpiPaymentStatus.FAILURE) {
      add(PaymentFailed('UPI_FAILURE', 'UPI payment failed', source: 'upi'));
    } else {
      add(PaymentFailed('UPI_SUBMITTED',
          'Payment submitted. Verifying...', source: 'upi'));
    }
  }

  void _openRazorpay(PaymentOrder order) {
    final options = {
      'key': PaymentConstants.razorpayKeyId,
      'amount': order.amountPaise,
      'currency': 'INR',
      'name': PaymentConstants.merchantName,
      'description': order.tournamentName,
      'order_id': order.orderId,
      'prefill': {
        'contact': '+91${state.phone}',
        'email': '',
      },
      'notes': {
        'tournament_id': order.tournamentId,
        'referral_code': state.appliedReferral?.code ?? '',
      },
      'theme': {'color': PaymentConstants.brandColorHex},
    };
    _razorpay.open(options);
  }

  Future<void> _onSuccess(
      PaymentSucceeded event, Emitter<PaymentState> emit) async {
    try {
      final result = await _repo.verifyPayment(
        razorpayPaymentId: event.paymentId,
        razorpayOrderId: event.orderId,
        razorpaySignature: event.signature,
        userPhone: '+91${state.phone}',
      );
      emit(state.copyWith(
          status: PaymentStatus.success, result: result));
    } catch (_) {
      emit(state.copyWith(
        status: PaymentStatus.failure,
        errorMessage:
            'Verification failed. Contact support if amount was deducted.',
      ));
    }
  }

  void _onFailure(PaymentFailed event, Emitter<PaymentState> emit) {
    emit(state.copyWith(
      status: PaymentStatus.failure,
      result: PaymentFailure(
        errorCode: event.errorCode,
        errorDescription: event.description,
        errorSource: event.source,
        razorpayOrderId: state.currentOrder?.orderId ?? '',
      ),
    ));
  }

  void _onRetry(PaymentRetryRequested event, Emitter<PaymentState> emit) {
    final order = state.currentOrder;
    if (order == null || order.isExpired) {
      emit(state.copyWith(
          currentOrder: null, status: PaymentStatus.idle, currentStep: 1));
    } else {
      emit(state.copyWith(status: PaymentStatus.idle, currentStep: 2));
    }
  }

  void _onRazorpaySuccess(PaymentSuccessResponse r) =>
      add(PaymentSucceeded(r.paymentId!, r.orderId!, r.signature!));

  void _onRazorpayError(PaymentFailureResponse r) =>
      add(PaymentFailed(r.code.toString(), r.message ?? 'Payment failed'));

  void _onExternalWallet(ExternalWalletResponse r) {}

  @override
  Future<void> close() {
    _razorpay.clear();
    return super.close();
  }
}
