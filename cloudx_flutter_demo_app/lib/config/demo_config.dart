class DemoEnvironmentConfig {
  final String name;
  final String appKey;
  final String bannerPlacement;
  final String mrecPlacement;
  final String interstitialPlacement;
  final String nativePlacement;
  final String rewardedPlacement;

  const DemoEnvironmentConfig({
    required this.name,
    required this.appKey,
    required this.bannerPlacement,
    required this.mrecPlacement,
    required this.interstitialPlacement,
    required this.nativePlacement,
    required this.rewardedPlacement,
  });
}

class DemoConfig {
  // iOS Configs
  static const iosDev = DemoEnvironmentConfig(
    name: 'Development',
    appKey: 'g0PdN9_0ilfIcuNXhBopl',
    bannerPlacement: 'metaBanner',
    mrecPlacement: 'metaMREC',
    interstitialPlacement: 'metaInterstitial',
    nativePlacement: 'metaNative',
    rewardedPlacement: 'metaRewarded',
  );

  static const iosStaging = DemoEnvironmentConfig(
    name: 'Staging',
    appKey: 'A7ovaBRCcAL8lapKtoZmm',
    bannerPlacement: 'objcDemo-banner-1',
    mrecPlacement: 'objcDemo-mrec-1',
    interstitialPlacement: 'objcDemo-interstitial-1',
    nativePlacement: '-',
    rewardedPlacement: '-',
  );

  static const iosProduction = DemoEnvironmentConfig(
    name: 'Production',
    appKey: 'ZFyiqxXWTOGYclwHElLbM',
    bannerPlacement: 'flutter-demo-banner-1',
    mrecPlacement: 'flutter-demo-mrec-1',
    interstitialPlacement: 'flutter-demo-interstitial-1',
    nativePlacement: '-',
    rewardedPlacement: '-',
  );

  // Android Configs
  static const androidDev = DemoEnvironmentConfig(
    name: 'Development',
    appKey: 'g0PdN9_0ilfIcuNXhBopl', // TODO: Replace with actual Android dev app key
    bannerPlacement: 'metaBanner',
    mrecPlacement: 'metaMREC',
    interstitialPlacement: 'metaInterstitial',
    nativePlacement: 'metaNative',
    rewardedPlacement: 'metaRewarded',
  );

  static const androidStaging = DemoEnvironmentConfig(
    name: 'Staging',
    appKey: 'A7ovaBRCcAL8lapKtoZmm', // TODO: Replace with actual Android staging app key
    bannerPlacement: 'objcDemo-banner-1',
    mrecPlacement: 'objcDemo-mrec-1',
    interstitialPlacement: 'objcDemo-interstitial-1',
    nativePlacement: '-',
    rewardedPlacement: '-',
  );

  static const androidProduction = DemoEnvironmentConfig(
    name: 'Production',
    appKey: 'QtGzyVf8AuffQIWC9jOUx',
    bannerPlacement: 'FlutterDemoBanner',
    mrecPlacement: 'FlutterDemoMrec',
    interstitialPlacement: 'FlutterDemoInterstitial',
    nativePlacement: '-',
    rewardedPlacement: '-',
  );
}
