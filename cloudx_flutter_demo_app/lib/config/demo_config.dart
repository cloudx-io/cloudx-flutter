class DemoEnvironmentConfig {
  final String name;
  final String appKey;
  final String bannerPlacementName;
  final String mrecPlacementName;
  final String interstitialPlacementName;
  final String nativePlacementName;
  final String rewardedPlacementName;

  const DemoEnvironmentConfig({
    required this.name,
    required this.appKey,
    required this.bannerPlacementName,
    required this.mrecPlacementName,
    required this.interstitialPlacementName,
    required this.nativePlacementName,
    required this.rewardedPlacementName,
  });
}

class DemoConfig {
  // iOS Configs
  static const iosDev = DemoEnvironmentConfig(
    name: 'Development',
    appKey: 'g0PdN9_0ilfIcuNXhBopl',
    bannerPlacementName: 'metaBanner',
    mrecPlacementName: 'metaMREC',
    interstitialPlacementName: 'metaInterstitial',
    nativePlacementName: 'metaNative',
    rewardedPlacementName: 'metaRewarded',
  );

  static const iosStaging = DemoEnvironmentConfig(
    name: 'Staging',
    appKey: 'A7ovaBRCcAL8lapKtoZmm',
    bannerPlacementName: 'objcDemo-banner-1',
    mrecPlacementName: 'objcDemo-mrec-1',
    interstitialPlacementName: 'objcDemo-interstitial-1',
    nativePlacementName: '-',
    rewardedPlacementName: '-',
  );

  static const iosProduction = DemoEnvironmentConfig(
    name: 'Production',
    appKey: 'ZFyiqxXWTOGYclwHElLbM',
    bannerPlacementName: 'flutter-demo-banner-1',
    mrecPlacementName: 'flutter-demo-mrec-1',
    interstitialPlacementName: 'flutter-demo-interstitial-1',
    nativePlacementName: '-',
    rewardedPlacementName: '-',
  );

  // Android Configs
  static const androidDev = DemoEnvironmentConfig(
    name: 'Development',
    appKey: 'g0PdN9_0ilfIcuNXhBopl', // TODO: Replace with actual Android dev app key
    bannerPlacementName: 'metaBanner',
    mrecPlacementName: 'metaMREC',
    interstitialPlacementName: 'metaInterstitial',
    nativePlacementName: 'metaNative',
    rewardedPlacementName: 'metaRewarded',
  );

  static const androidStaging = DemoEnvironmentConfig(
    name: 'Staging',
    appKey: 'A7ovaBRCcAL8lapKtoZmm', // TODO: Replace with actual Android staging app key
    bannerPlacementName: 'objcDemo-banner-1',
    mrecPlacementName: 'objcDemo-mrec-1',
    interstitialPlacementName: 'objcDemo-interstitial-1',
    nativePlacementName: '-',
    rewardedPlacementName: '-',
  );

  static const androidProduction = DemoEnvironmentConfig(
    name: 'Production',
    appKey: 'QtGzyVf8AuffQIWC9jOUx',
    bannerPlacementName: 'FlutterDemoBanner',
    mrecPlacementName: 'FlutterDemoMrec',
    interstitialPlacementName: 'FlutterDemoInterstitial',
    nativePlacementName: '-',
    rewardedPlacementName: '-',
  );
}
