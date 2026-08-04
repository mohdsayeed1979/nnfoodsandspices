import '../../../core/env/app_env.dart';
import '../domain/payment_method.dart';

class PaymentResult {
  const PaymentResult.success(this.transactionId) : failureMessage = null;
  const PaymentResult.failure(this.failureMessage) : transactionId = null;

  final String? transactionId;
  final String? failureMessage;

  bool get isSuccess => transactionId != null;
}

/// Payment gateway abstraction. [CashOnDeliveryService] works out of the
/// box (no external account needed). The card/UPI/wallet gateways are
/// wired for the moment real merchant keys are supplied via
/// `--dart-define-from-file=env.json` — until then they report a clear
/// "not configured" failure instead of silently pretending to charge a card.
abstract interface class PaymentService {
  bool get isConfigured;
  Future<PaymentResult> pay({required double amount, required String orderId});
}

class CashOnDeliveryService implements PaymentService {
  @override
  bool get isConfigured => true;

  @override
  Future<PaymentResult> pay({required double amount, required String orderId}) async {
    return PaymentResult.success('COD-$orderId');
  }
}

class RazorpayPaymentService implements PaymentService {
  @override
  bool get isConfigured => AppEnv.razorpayKey.isNotEmpty;

  @override
  Future<PaymentResult> pay({required double amount, required String orderId}) async {
    if (!isConfigured) {
      return const PaymentResult.failure(
        'Razorpay is not configured yet. Add RAZORPAY_KEY to env.json to enable card/UPI payments.',
      );
    }
    // Wire `razorpay_flutter` here once a live key is provided.
    return const PaymentResult.failure('Razorpay checkout is not yet wired up.');
  }
}

class StripePaymentService implements PaymentService {
  @override
  bool get isConfigured => AppEnv.stripePublishableKey.isNotEmpty;

  @override
  Future<PaymentResult> pay({required double amount, required String orderId}) async {
    if (!isConfigured) {
      return const PaymentResult.failure(
        'Stripe is not configured yet. Add STRIPE_PUBLISHABLE_KEY to env.json to enable card payments.',
      );
    }
    // Wire the `flutter_stripe` payment sheet here once a live key is provided.
    return const PaymentResult.failure('Stripe checkout is not yet wired up.');
  }
}

class PayTabsPaymentService implements PaymentService {
  @override
  bool get isConfigured => AppEnv.payTabsProfileId.isNotEmpty;

  @override
  Future<PaymentResult> pay({required double amount, required String orderId}) async {
    if (!isConfigured) {
      return const PaymentResult.failure(
        'PayTabs is not configured yet. Add PAYTABS_PROFILE_ID to env.json to enable this payment method.',
      );
    }
    return const PaymentResult.failure('PayTabs checkout is not yet wired up.');
  }
}

class WalletPaymentService implements PaymentService {
  WalletPaymentService(this.type);
  final PaymentMethodType type;

  @override
  bool get isConfigured => false;

  @override
  Future<PaymentResult> pay({required double amount, required String orderId}) async {
    return PaymentResult.failure('${type.label} requires native platform setup (merchant ID) that is not configured in this build.');
  }
}

PaymentService paymentServiceFor(PaymentMethodType type) => switch (type) {
      PaymentMethodType.cashOnDelivery => CashOnDeliveryService(),
      PaymentMethodType.razorpay => RazorpayPaymentService(),
      PaymentMethodType.stripe => StripePaymentService(),
      PaymentMethodType.payTabs => PayTabsPaymentService(),
      PaymentMethodType.googlePay => WalletPaymentService(PaymentMethodType.googlePay),
      PaymentMethodType.applePay => WalletPaymentService(PaymentMethodType.applePay),
    };
