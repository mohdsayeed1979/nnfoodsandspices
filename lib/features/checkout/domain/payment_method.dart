enum PaymentMethodType { cashOnDelivery, razorpay, stripe, payTabs, googlePay, applePay }

extension PaymentMethodTypeX on PaymentMethodType {
  String get label => switch (this) {
        PaymentMethodType.cashOnDelivery => 'Cash on Delivery',
        PaymentMethodType.razorpay => 'Razorpay (Cards / UPI / Netbanking)',
        PaymentMethodType.stripe => 'Stripe (International Cards)',
        PaymentMethodType.payTabs => 'PayTabs (MENA region)',
        PaymentMethodType.googlePay => 'Google Pay',
        PaymentMethodType.applePay => 'Apple Pay',
      };
}
