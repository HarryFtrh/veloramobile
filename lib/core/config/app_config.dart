enum AppFlavor {
  fnb,
  customer,
  pharmacy,
  sales,
  marketplace,
}

class AppConfig {
  final AppFlavor flavor;
  final String appName;
  final String apiBaseUrl;
  final String reverbHost;
  final int reverbPort;
  final String reverbAppKey;

  static late AppConfig instance;

  AppConfig({
    required this.flavor,
    required this.appName,
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://velora.co.id/api',
    ),
    this.reverbHost = const String.fromEnvironment(
      'REVERB_HOST',
      defaultValue: 'velora.co.id',
    ),
    this.reverbPort = const int.fromEnvironment(
      'REVERB_PORT',
      defaultValue: 443,
    ),
    this.reverbAppKey = const String.fromEnvironment(
      'REVERB_APP_KEY',
      defaultValue: '',
    ),
  });

  static void initialize(AppConfig config) {
    instance = config;
  }

  bool get isFnb => flavor == AppFlavor.fnb;
  bool get isCustomer => flavor == AppFlavor.customer;
  bool get isPharmacy => flavor == AppFlavor.pharmacy;
  bool get isSales => flavor == AppFlavor.sales;
  bool get isMarketplace => flavor == AppFlavor.marketplace;
}
