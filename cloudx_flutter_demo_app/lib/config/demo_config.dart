class DemoEnvironmentConfig {
  final String name;
  final String appKey;
  final String hashedUserId;
  final String bannerPlacement;
  final String mrecPlacement;
  final String interstitialPlacement;
  final String nativePlacement;
  final String rewardedPlacement;

  const DemoEnvironmentConfig({
    required this.name,
    required this.appKey,
    required this.hashedUserId,
    required this.bannerPlacement,
    required this.mrecPlacement,
    required this.interstitialPlacement,
    required this.nativePlacement,
    required this.rewardedPlacement,
  });
}

class DemoConfig {
  static const dev = DemoEnvironmentConfig(
    name: 'Development',
    appKey: 'g0PdN9_0ilfIcuNXhBopl',
    hashedUserId: 'test-user-123',
    bannerPlacement: 'metaBanner',
    mrecPlacement: 'metaMREC',
    interstitialPlacement: 'metaInterstitial',
    nativePlacement: 'metaNative',
    rewardedPlacement: 'metaRewarded',
  );

  static const staging = DemoEnvironmentConfig(
    name: 'Staging',
    appKey: 'Ty5bVlbX2tQOSL9YNoZ0D',
    hashedUserId: 'test-user-123-staging',
    bannerPlacement: 'objcDemo-banner-1',
    mrecPlacement: 'objcDemo-mrec-1',
    interstitialPlacement: 'objcDemo-interstitial-1',
    nativePlacement: '-',
    rewardedPlacement: '-',
  );

  static const production = DemoEnvironmentConfig(
    name: 'Production',
    appKey: 'ZFyiqxXWTOGYclwHElLbM',  // FlutterDemoApp - com.example.cloudxFlutterHostApp
    hashedUserId: 'prod-user-123',
    bannerPlacement: 'flutter-demo-banner-1',
    mrecPlacement: 'flutter-demo-mrec-1',
    interstitialPlacement: 'flutter-demo-interstitial-1',
    nativePlacement: '-',
    rewardedPlacement: '-',
  );
}

