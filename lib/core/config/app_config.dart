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
  final String googleServerClientId;

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
    this.googleServerClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '419229913372-jraa988aqc0fd0a9flvifp64sl1e39r4.apps.googleusercontent.com',
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
