class PlatformSettings {
  final double normalListingPrice;
  final double featuredPriceWeek;
  final double featuredPriceTwoWeeks;
  final double featuredPriceMonth;
  final int listingDurationDays;
  final Map<String, PaymentMethodConfig> paymentMethods;
  final String supportPhone;
  final String supportEmail;
  final int maxImagesPerProperty;

  PlatformSettings({
    required this.normalListingPrice,
    required this.featuredPriceWeek,
    required this.featuredPriceTwoWeeks,
    required this.featuredPriceMonth,
    required this.listingDurationDays,
    required this.paymentMethods,
    required this.supportPhone,
    required this.supportEmail,
    required this.maxImagesPerProperty,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    final methods = <String, PaymentMethodConfig>{};
    if (json['paymentMethods'] != null) {
      (json['paymentMethods'] as Map<String, dynamic>).forEach((key, value) {
        methods[key] = PaymentMethodConfig.fromJson(value);
      });
    }
    return PlatformSettings(
      normalListingPrice: (json['normalListingPrice'] as num).toDouble(),
      featuredPriceWeek: (json['featuredPriceWeek'] as num?)?.toDouble() ?? 60,
      featuredPriceTwoWeeks: (json['featuredPriceTwoWeeks'] as num?)?.toDouble() ?? 120,
      featuredPriceMonth: (json['featuredPriceMonth'] as num?)?.toDouble() ?? 150,
      listingDurationDays: json['listingDurationDays'] as int,
      paymentMethods: methods,
      supportPhone: json['supportPhone'] ?? '',
      supportEmail: json['supportEmail'] ?? '',
      maxImagesPerProperty: json['maxImagesPerProperty'] ?? 10,
    );
  }
}

class PaymentMethodConfig {
  final bool enabled;
  final String? name;
  final String? number;
  final String? holder;
  final String? bank;
  final String? cardNumber;

  PaymentMethodConfig({
    required this.enabled,
    this.name,
    this.number,
    this.holder,
    this.bank,
    this.cardNumber,
  });

  factory PaymentMethodConfig.fromJson(Map<String, dynamic> json) {
    return PaymentMethodConfig(
      enabled: json['enabled'] ?? false,
      name: json['name'],
      number: json['number'],
      holder: json['holder'],
      bank: json['bank'],
      cardNumber: json['cardNumber'],
    );
  }
}
