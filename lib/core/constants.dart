class AppConstants {
  AppConstants._();

  static const bundleId = 'com.gonzorevol.blocktap';
  static const appMetricaApiKey = '8d12d2cc-5f4e-43dc-8909-7e2ad95ad293';
  static const startAppId = '206450178';

  static const termsOfUseUrl = 'https://telegra.ph/Terms-of-Use-07-02-8';
  static const privacyPolicyUrl = 'https://telegra.ph/Privacy-Policy-07-02-132';

  static const iapStarter = 'gonzotokrevo_1500';
  static const iapPremium = 'gonzotokrevo_4500';
  static const iapVip = 'gonzotokrevo_10000';
  static const iapProductIds = <String>{iapStarter, iapPremium, iapVip};

  static const wheelCooldown = Duration(hours: 12);
  static const lowBalanceThreshold = 10;
  static const lowBalanceBonus = 100;
  static const exchangeStep = 10000;
  static const exchangeUsdPerStep = 5.0;
}
