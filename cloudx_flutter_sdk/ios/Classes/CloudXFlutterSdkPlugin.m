#import "CloudXFlutterSdkPlugin.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdDelegate.h>
#import <CloudXCore/CLXURLProvider.h>
#import <CloudXCore/CLXLogger.h>
#import <Flutter/Flutter.h>
#import <objc/runtime.h>

@interface CloudXFlutterSdkPlugin () <CLXInterstitialDelegate, CLXRewardedDelegate, CLXBannerDelegate, CLXNativeDelegate, FlutterStreamHandler>
@property (nonatomic, strong) CLXLogger *logger;
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong) FlutterEventChannel *eventChannel;
@property (nonatomic, strong) FlutterEventSink eventSink;

// Simple state management - just store instances and pending results
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *adInstances;
@property (nonatomic, strong) NSMutableDictionary<NSString *, FlutterResult> *pendingResults;
// Map CloudX internal placement IDs to Flutter adIds
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *placementToAdIdMap;
@end

@interface CloudXBannerPlatformView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView *view;
- (instancetype)initWithFrame:(CGRect)frame
                 viewIdentifier:(int64_t)viewId
                      arguments:(id)args
                        plugin:(CloudXFlutterSdkPlugin *)plugin;
@end

@implementation CloudXBannerPlatformView {
    CloudXFlutterSdkPlugin *_plugin;
}

- (instancetype)initWithFrame:(CGRect)frame
                 viewIdentifier:(int64_t)viewId
                      arguments:(id)args
                        plugin:(CloudXFlutterSdkPlugin *)plugin {
    self = [super init];
    if (self) {
        _plugin = plugin;
        NSString *adId = args[@"adId"];
        
        [_plugin.logger debug:[NSString stringWithFormat:@"BannerPlatformView init - adId: %@", adId]];
        
        UIView *bannerView = nil;
        if (adId && _plugin.adInstances[adId]) {
            id instance = _plugin.adInstances[adId];
            if ([instance isKindOfClass:[UIView class]]) {
                bannerView = (UIView *)instance;
                [_plugin.logger debug:@"BannerPlatformView - found banner view"];
            }
        } else {
            [_plugin.logger debug:@"BannerPlatformView - no ad instance, creating fallback"];
        }
        
        if (bannerView) {
            self.view = bannerView;
            self.view.layer.borderWidth = 0.0;
            self.view.layer.borderColor = nil;
            self.view.backgroundColor = [UIColor clearColor];
        } else {
            self.view = [[UIView alloc] initWithFrame:frame];
            self.view.backgroundColor = [UIColor clearColor];
        }
    }
    return self;
}

- (UIView *)view {
    return _view;
}
@end

@interface CloudXBannerPlatformViewFactory : NSObject <FlutterPlatformViewFactory>
@property(nonatomic, weak) CloudXFlutterSdkPlugin *plugin;
- (instancetype)initWithPlugin:(CloudXFlutterSdkPlugin *)plugin;
@end

@implementation CloudXBannerPlatformViewFactory
- (instancetype)initWithPlugin:(CloudXFlutterSdkPlugin *)plugin {
    self = [super init];
    if (self) {
        _plugin = plugin;
    }
    return self;
}
- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}
- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id)args {
    return [[CloudXBannerPlatformView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args plugin:_plugin];
}
@end

@interface CloudXNativePlatformView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView *view;
- (instancetype)initWithFrame:(CGRect)frame
                 viewIdentifier:(int64_t)viewId
                      arguments:(id)args
                        plugin:(CloudXFlutterSdkPlugin *)plugin;
@end

@implementation CloudXNativePlatformView {
    CloudXFlutterSdkPlugin *_plugin;
}

- (instancetype)initWithFrame:(CGRect)frame
                 viewIdentifier:(int64_t)viewId
                      arguments:(id)args
                        plugin:(CloudXFlutterSdkPlugin *)plugin {
    self = [super init];
    if (self) {
        _plugin = plugin;
        NSString *adId = args[@"adId"];
        
        [_plugin.logger debug:[NSString stringWithFormat:@"NativePlatformView init - adId: %@", adId]];
        
        UIView *nativeView = nil;
        if (adId && _plugin.adInstances[adId]) {
            id instance = _plugin.adInstances[adId];
            if ([instance isKindOfClass:[UIView class]]) {
                nativeView = (UIView *)instance;
                [_plugin.logger debug:@"NativePlatformView - found native view"];
            }
        } else {
            [_plugin.logger debug:@"NativePlatformView - no ad instance, creating fallback"];
        }
        
        if (nativeView) {
            self.view = nativeView;
        } else {
            self.view = [[UIView alloc] initWithFrame:frame];
            self.view.backgroundColor = [UIColor clearColor];
        }
    }
    return self;
}

- (UIView *)view {
    return _view;
}
@end

@interface CloudXNativePlatformViewFactory : NSObject <FlutterPlatformViewFactory>
@property(nonatomic, weak) CloudXFlutterSdkPlugin *plugin;
- (instancetype)initWithPlugin:(CloudXFlutterSdkPlugin *)plugin;
@end

@implementation CloudXNativePlatformViewFactory
- (instancetype)initWithPlugin:(CloudXFlutterSdkPlugin *)plugin {
    self = [super init];
    if (self) {
        _plugin = plugin;
    }
    return self;
}
- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}
- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id)args {
    return [[CloudXNativePlatformView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args plugin:_plugin];
}
@end

@interface CloudXMRECPlatformView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView *view;
- (instancetype)initWithFrame:(CGRect)frame
                 viewIdentifier:(int64_t)viewId
                      arguments:(id)args
                        plugin:(CloudXFlutterSdkPlugin *)plugin;
@end

@implementation CloudXMRECPlatformView {
    CloudXFlutterSdkPlugin *_plugin;
}

- (instancetype)initWithFrame:(CGRect)frame
                 viewIdentifier:(int64_t)viewId
                      arguments:(id)args
                        plugin:(CloudXFlutterSdkPlugin *)plugin {
    self = [super init];
    if (self) {
        _plugin = plugin;
        NSString *adId = args[@"adId"];
        
        [_plugin.logger debug:[NSString stringWithFormat:@"MRECPlatformView init - adId: %@", adId]];
        
        UIView *mrecView = nil;
        if (adId && _plugin.adInstances[adId]) {
            id instance = _plugin.adInstances[adId];
            if ([instance isKindOfClass:[UIView class]]) {
                mrecView = (UIView *)instance;
                [_plugin.logger debug:@"MRECPlatformView - found MREC view"];
            }
        } else {
            [_plugin.logger debug:@"MRECPlatformView - no ad instance, creating fallback"];
        }
        
        if (mrecView) {
            self.view = mrecView;
            self.view.layer.borderWidth = 0.0;
            self.view.layer.borderColor = nil;
            self.view.backgroundColor = [UIColor clearColor];
        } else {
            self.view = [[UIView alloc] initWithFrame:frame];
            self.view.backgroundColor = [UIColor clearColor];
        }
    }
    return self;
}

- (UIView *)view {
    return _view;
}
@end

@interface CloudXMRECPlatformViewFactory : NSObject <FlutterPlatformViewFactory>
@property(nonatomic, weak) CloudXFlutterSdkPlugin *plugin;
- (instancetype)initWithPlugin:(CloudXFlutterSdkPlugin *)plugin;
@end

@implementation CloudXMRECPlatformViewFactory
- (instancetype)initWithPlugin:(CloudXFlutterSdkPlugin *)plugin {
    self = [super init];
    if (self) {
        _plugin = plugin;
    }
    return self;
}
- (NSObject<FlutterMessageCodec> *)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}
- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id)args {
    return [[CloudXMRECPlatformView alloc] initWithFrame:frame viewIdentifier:viewId arguments:args plugin:_plugin];
}
@end

@implementation CloudXFlutterSdkPlugin

+ (void)load {
    // Plugin loaded - no verbose logging setup needed
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  
  // DEMO APP ONLY: Force test mode for all bid requests
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CLXCore_Internal_ForceTestMode"];
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CLXMetaTestModeEnabled"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"cloudx_flutter_sdk"
            binaryMessenger:[registrar messenger]];
  
  CloudXFlutterSdkPlugin* instance = [[CloudXFlutterSdkPlugin alloc] init];
  instance.channel = channel;
  [registrar addMethodCallDelegate:instance channel:channel];
  
  // Set up event channel
  FlutterEventChannel* eventChannel = [FlutterEventChannel
                                       eventChannelWithName:@"cloudx_flutter_sdk_events"
                                       binaryMessenger:[registrar messenger]];
  instance.eventChannel = eventChannel;
  [eventChannel setStreamHandler:instance];

  // Register platform view factory for banner
  CloudXBannerPlatformViewFactory *bannerFactory = [[CloudXBannerPlatformViewFactory alloc] initWithPlugin:instance];
  [registrar registerViewFactory:bannerFactory withId:@"cloudx_banner_view"];
  
  // Register platform view factory for native
  CloudXNativePlatformViewFactory *nativeFactory = [[CloudXNativePlatformViewFactory alloc] initWithPlugin:instance];
  [registrar registerViewFactory:nativeFactory withId:@"cloudx_native_view"];
  
  // Register platform view factory for MREC
  CloudXMRECPlatformViewFactory *mrecFactory = [[CloudXMRECPlatformViewFactory alloc] initWithPlugin:instance];
  [registrar registerViewFactory:mrecFactory withId:@"cloudx_mrec_view"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logger = [[CLXLogger alloc] initWithCategory:@"CloudX-Flutter"];
        _adInstances = [NSMutableDictionary dictionary];
        _pendingResults = [NSMutableDictionary dictionary];
        _placementToAdIdMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    // Core SDK Methods
    if ([call.method isEqualToString:@"initSDK"]) {
        [self initSDK:call.arguments result:result];
    } else if ([call.method isEqualToString:@"isSDKInitialized"]) {
        result(@([[CloudXCore shared] isInitialized]));
    } else if ([call.method isEqualToString:@"getSDKVersion"]) {
        result([[CloudXCore shared] sdkVersion]);
    } else if ([call.method isEqualToString:@"getUserID"]) {
        result([[CloudXCore shared] userID]);
    } else if ([call.method isEqualToString:@"setUserID"]) {
        [CloudXCore shared].userID = call.arguments[@"userID"];
        result(@YES);
    } else if ([call.method isEqualToString:@"trackSDKError"]) {
        NSString *errorMsg = call.arguments[@"error"];
        NSError *error = [NSError errorWithDomain:@"com.cloudx.flutter" code:-1 
            userInfo:@{NSLocalizedDescriptionKey: errorMsg ?: @"Unknown error"}];
        [CloudXCore trackSDKError:error];
        result(@YES);
    } else if ([call.method isEqualToString:@"setEnvironment"]) {
        NSString *environment = call.arguments[@"environment"];
        [CLXURLProvider setEnvironment:environment];
        result(@YES);
    }
    // Privacy & Compliance Methods
    else if ([call.method isEqualToString:@"setCCPAPrivacyString"]) {
        [CloudXCore setCCPAPrivacyString:call.arguments[@"ccpaString"]];
        result(@YES);
    } else if ([call.method isEqualToString:@"setIsUserConsent"]) {
        [CloudXCore setIsUserConsent:[call.arguments[@"isUserConsent"] boolValue]];
        result(@YES);
    } else if ([call.method isEqualToString:@"setIsAgeRestrictedUser"]) {
        [CloudXCore setIsAgeRestrictedUser:[call.arguments[@"isAgeRestrictedUser"] boolValue]];
        result(@YES);
    } else if ([call.method isEqualToString:@"setIsDoNotSell"]) {
        [CloudXCore setIsDoNotSell:[call.arguments[@"isDoNotSell"] boolValue]];
        result(@YES);
    } else if ([call.method isEqualToString:@"setGPPString"]) {
        [CloudXCore setGPPString:call.arguments[@"gppString"]];
        result(@YES);
    } else if ([call.method isEqualToString:@"getGPPString"]) {
        result([CloudXCore getGPPString]);
    } else if ([call.method isEqualToString:@"setGPPSid"]) {
        [CloudXCore setGPPSid:call.arguments[@"gppSid"]];
        result(@YES);
    } else if ([call.method isEqualToString:@"getGPPSid"]) {
        result([CloudXCore getGPPSid]);
    }
    // Targeting Methods
    else if ([call.method isEqualToString:@"provideUserDetails"]) {
        [[CloudXCore shared] setHashedUserID:call.arguments[@"hashedUserID"]];
        result(@YES);
    } else if ([call.method isEqualToString:@"useHashedKeyValue"]) {
        [[CloudXCore shared] setHashedKeyValue:call.arguments[@"key"] 
                                          value:call.arguments[@"value"]];
        result(@YES);
    } else if ([call.method isEqualToString:@"useKeyValues"]) {
        [[CloudXCore shared] setKeyValueDictionary:call.arguments[@"keyValues"]];
        result(@YES);
    } else if ([call.method isEqualToString:@"useBidderKeyValue"]) {
        [[CloudXCore shared] setBidderKeyValue:call.arguments[@"bidder"]
                                           key:call.arguments[@"key"]
                                         value:call.arguments[@"value"]];
        result(@YES);
    }
    // Ad Creation Methods
    else if ([call.method isEqualToString:@"createBanner"]) {
        [self createBanner:call.arguments result:result];
    } else if ([call.method isEqualToString:@"createInterstitial"]) {
        [self createInterstitial:call.arguments result:result];
    } else if ([call.method isEqualToString:@"createRewarded"]) {
        [self createRewarded:call.arguments result:result];
    } else if ([call.method isEqualToString:@"createNative"]) {
        [self createNative:call.arguments result:result];
    } else if ([call.method isEqualToString:@"createMREC"]) {
        [self createMREC:call.arguments result:result];
    }
    // Ad Operation Methods
    else if ([call.method isEqualToString:@"loadAd"]) {
        [self loadAd:call.arguments result:result];
    } else if ([call.method isEqualToString:@"showAd"]) {
        [self showAd:call.arguments result:result];
    } else if ([call.method isEqualToString:@"hideAd"]) {
        [self hideAd:call.arguments result:result];
    } else if ([call.method isEqualToString:@"isAdReady"]) {
        [self isAdReady:call.arguments result:result];
    } else if ([call.method isEqualToString:@"destroyAd"]) {
        [self destroyAd:call.arguments result:result];
    }
    // Unknown method
    else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - SDK Initialization

- (void)initSDK:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *appKey = arguments[@"appKey"];
    NSString *hashedUserID = arguments[@"hashedUserID"];
    
    [self.logger info:[NSString stringWithFormat:@"Initializing SDK with appKey: %@", appKey]];
    
    if (!appKey) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"appKey is required" 
                                  details:nil]);
        return;
    }
    
    if (hashedUserID) {
        [[CloudXCore shared] initializeSDKWithAppKey:appKey 
                                        hashedUserID:hashedUserID 
                                          completion:^(BOOL success, NSError * _Nullable error) {
            [self handleInitResult:success error:error result:result];
        }];
    } else {
        [[CloudXCore shared] initializeSDKWithAppKey:appKey 
                                          completion:^(BOOL success, NSError * _Nullable error) {
            [self handleInitResult:success error:error result:result];
        }];
    }
}

- (void)handleInitResult:(BOOL)success error:(NSError *)error result:(FlutterResult)result {
    if (success) {
        result(@YES);
    } else {
        NSString *errorMessage = error ? error.localizedDescription : @"Unknown error occurred";
        result([FlutterError errorWithCode:@"INIT_FAILED" 
                                  message:errorMessage 
                                  details:nil]);
    }
}

#pragma mark - Ad Creation

- (void)createAd:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *adType = arguments[@"adType"];
    NSString *placement = arguments[@"placement"];
    NSString *adId = arguments[@"adId"];
    
    if (!adType || !placement || !adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adType, placement, and adId are required" 
                                  details:nil]);
        return;
    }
    
    if ([adType isEqualToString:@"banner"]) {
        [self createBanner:@{@"placement": placement, @"adId": adId} result:result];
    } else if ([adType isEqualToString:@"interstitial"]) {
        [self createInterstitial:@{@"placement": placement, @"adId": adId} result:result];
    } else if ([adType isEqualToString:@"rewarded"]) {
        [self createRewarded:@{@"placement": placement, @"adId": adId} result:result];
    } else if ([adType isEqualToString:@"native"]) {
        [self createNative:@{@"placement": placement, @"adId": adId} result:result];
    } else if ([adType isEqualToString:@"mrec"]) {
        [self createMREC:@{@"placement": placement, @"adId": adId} result:result];
    } else {
        result([FlutterError errorWithCode:@"INVALID_AD_TYPE" 
                                  message:[NSString stringWithFormat:@"Unknown ad type: %@", adType] 
                                  details:nil]);
    }
}

- (void)createBanner:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *adId = arguments[@"adId"];
    NSString *placement = arguments[@"placement"];
    NSNumber *tmax = arguments[@"tmax"];  // NEW: Support tmax parameter
    
    if (!placement || !adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    UIViewController *viewController = [self getTopViewController];
    
    // Create banner with optional tmax parameter
    CLXBannerAdView *bannerAd = [[CloudXCore shared] createBannerWithPlacement:placement
                                                                  viewController:viewController
                                                                        delegate:self
                                                                            tmax:tmax];
    
    if (bannerAd) {
        self.adInstances[adId] = bannerAd;
        [self setAdId:adId forInstance:bannerAd];
        [self storePlacementIdMappingForAdInstance:bannerAd withAdId:adId adType:@"banner"];
        result(@YES);
    } else {
        result([FlutterError errorWithCode:@"AD_CREATION_FAILED" 
                                  message:@"Failed to create banner ad" 
                                  details:nil]);
    }
}

- (void)createInterstitial:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *placement = arguments[@"placement"];
    NSString *adId = arguments[@"adId"];
    
    if (!placement || !adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    CLXPublisherFullscreenAd *interstitialAd = [[CloudXCore shared] createInterstitialWithPlacement:placement
                                                                                              delegate:self];
    
    if (interstitialAd) {
        self.adInstances[adId] = interstitialAd;
        [self setAdId:adId forInstance:interstitialAd];
        [self storePlacementIdMappingForAdInstance:interstitialAd withAdId:adId adType:@"interstitial"];
        [interstitialAd load];
        result(@YES);
    } else{
        result([FlutterError errorWithCode:@"AD_CREATION_FAILED" 
                                  message:@"Failed to create interstitial ad" 
                                  details:nil]);
    }
}

- (void)createRewarded:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *placement = arguments[@"placement"];
    NSString *adId = arguments[@"adId"];
    
    if (!placement || !adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    CLXPublisherFullscreenAd *rewardedAd = [[CloudXCore shared] createRewardedWithPlacement:placement
                                                                                     delegate:self];
    
    if (rewardedAd) {
        self.adInstances[adId] = rewardedAd;
        [self setAdId:adId forInstance:rewardedAd];
        [self storePlacementIdMappingForAdInstance:rewardedAd withAdId:adId adType:@"rewarded"];
        [rewardedAd load];
        result(@YES);
    } else {
        result([FlutterError errorWithCode:@"AD_CREATION_FAILED" 
                                  message:@"Failed to create rewarded ad" 
                                  details:nil]);
    }
}

- (void)createNative:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *placement = arguments[@"placement"];
    NSString *adId = arguments[@"adId"];
    
    if (!placement || !adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    UIViewController *viewController = [self getTopViewController];
    CLXNativeAdView *nativeAd = [[CloudXCore shared] createNativeAdWithPlacement:placement
                                                                    viewController:viewController
                                                                        delegate:self];
    
    if (nativeAd) {
        self.adInstances[adId] = nativeAd;
        [self setAdId:adId forInstance:nativeAd];
        [nativeAd load];
        result(@YES);
    } else {
        result([FlutterError errorWithCode:@"AD_CREATION_FAILED" 
                                  message:@"Failed to create native ad" 
                                  details:nil]);
    }
}

- (void)createMREC:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *placement = arguments[@"placement"];
    NSString *adId = arguments[@"adId"];
    
    if (!placement || !adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    UIViewController *viewController = [self getTopViewController];
    CLXBannerAdView *mrecAd = [[CloudXCore shared] createMRECWithPlacement:placement
                                                              viewController:viewController
                                                                  delegate:self];
    
    if (mrecAd) {
        self.adInstances[adId] = mrecAd;
        [self setAdId:adId forInstance:mrecAd];
        [self storePlacementIdMappingForAdInstance:mrecAd withAdId:adId adType:@"mrec"];
        result(@YES);
    } else {
        result([FlutterError errorWithCode:@"AD_CREATION_FAILED" 
                                  message:@"Failed to create MREC ad" 
                                  details:nil]);
    }
}

#pragma mark - Ad Operations

- (void)loadAd:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *adId = arguments[@"adId"];
    
    if (!adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adId is required" 
                                  details:nil]);
        return;
    }
    
    id adInstance = self.adInstances[adId];
    
    if (!adInstance) {
        [self.logger error:[NSString stringWithFormat:@"loadAd - adInstance not found for adId: %@", adId]];
        result([FlutterError errorWithCode:@"AD_NOT_FOUND" 
                                  message:@"Ad instance not found" 
                                  details:nil]);
        return;
    }
    
    if ([adInstance respondsToSelector:@selector(load)]) {
        @try {
            if ([adInstance respondsToSelector:@selector(placementId)]) {
                NSString *internalPlacementId = [adInstance valueForKey:@"placementId"];
                if (internalPlacementId) {
                    self.placementToAdIdMap[internalPlacementId] = adId;
                }
            }
            
            id innerAd = [adInstance valueForKey:@"ad"];
            if (innerAd) {
                [self setAdId:adId forInstance:innerAd];
                if ([innerAd respondsToSelector:@selector(placementId)]) {
                    NSString *innerPlacementId = [innerAd valueForKey:@"placementId"];
                    if (innerPlacementId) {
                        self.placementToAdIdMap[innerPlacementId] = adId;
                    }
                }
            }
        } @catch (NSException *exception) {
            // No inner ad, that's fine
        }
        
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [adInstance performSelector:@selector(load)];
        #pragma clang diagnostic pop
        result(@YES);
    } else {
        [self.logger error:@"Ad instance does not support loading"];
        result([FlutterError errorWithCode:@"INVALID_AD_TYPE" 
                                  message:@"Ad instance does not support loading" 
                                  details:nil]);
    }
}

- (void)showAd:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *adId = arguments[@"adId"];
    
    if (!adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adId is required" 
                                  details:nil]);
        return;
    }
    
    id adInstance = self.adInstances[adId];
    if (!adInstance) {
        result([FlutterError errorWithCode:@"AD_NOT_FOUND" 
                                  message:@"Ad instance not found" 
                                  details:nil]);
        return;
    }
    
    UIViewController *viewController = [self getTopViewController];
    
    if ([adInstance respondsToSelector:@selector(showFromViewController:)]) {
        [adInstance showFromViewController:viewController];
        result(@YES);
    } else {
        result([FlutterError errorWithCode:@"INVALID_AD_TYPE" 
                                  message:@"Ad instance does not support showing" 
                                  details:nil]);
    }
}

- (void)hideAd:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *adId = arguments[@"adId"];
    
    if (!adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adId is required" 
                                  details:nil]);
        return;
    }
    
    id adInstance = self.adInstances[adId];
    if (!adInstance) {
        result([FlutterError errorWithCode:@"AD_NOT_FOUND" 
                                  message:@"Ad instance not found" 
                                  details:nil]);
        return;
    }
    
    // Handle different ad types according to CloudX SDK and industry standards
    if ([adInstance isKindOfClass:[UIView class]]) {
        // Banner ads (UIView-based) - remove from superview or hide
        UIView *bannerView = (UIView *)adInstance;
        if (bannerView.superview) {
            [bannerView removeFromSuperview];
        } else {
            bannerView.hidden = YES;
        }
        result(@YES);
    } else if ([adInstance respondsToSelector:@selector(destroy)]) {
        // For other ad types that have a destroy method, call it
        [adInstance destroy];
        result(@YES);
    } else {
        // For fullscreen ads (interstitial/rewarded) - they auto-dismiss, so just return success
        result(@YES);
    }
}

- (void)isAdReady:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *adId = arguments[@"adId"];
    
    if (!adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adId is required" 
                                  details:nil]);
        return;
    }
    
    id adInstance = self.adInstances[adId];
    if (!adInstance) {
        result([FlutterError errorWithCode:@"AD_NOT_FOUND" 
                                  message:@"Ad instance not found" 
                                  details:nil]);
        return;
    }
    
    if ([adInstance respondsToSelector:@selector(isReady)]) {
        result(@([adInstance isReady]));
    } else {
        result([FlutterError errorWithCode:@"INVALID_AD_TYPE" 
                                  message:@"Ad instance does not support checking readiness" 
                                  details:nil]);
    }
}

- (void)destroyAd:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *adId = arguments[@"adId"];
    
    if (!adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adId is required" 
                                  details:nil]);
        return;
    }
    
    id adInstance = self.adInstances[adId];
    
    if (adInstance) {
        objc_setAssociatedObject(adInstance, "adId", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        @try {
            id innerAd = [adInstance valueForKey:@"ad"];
            if (innerAd) {
                objc_setAssociatedObject(innerAd, "adId", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        } @catch (NSException *exception) {
            // No inner ad, that's fine
        }
        
        if ([adInstance respondsToSelector:@selector(destroy)]) {
            [adInstance destroy];
        }
        
        [self.adInstances removeObjectForKey:adId];
        [self.pendingResults removeObjectForKey:adId];
    }
    
    result(@YES);
}

#pragma mark - Helper Methods

- (UIViewController *)getTopViewController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}

- (NSString *)getAdIdForInstance:(id)instance {
    if (!instance) {
        return nil;
    }
    return objc_getAssociatedObject(instance, "adId");
}

- (void)setAdId:(NSString *)adId forInstance:(id)instance {
    if (!instance || !adId) {
        [self.logger debug:@"setAdId called with nil parameter, skipping"];
        return;
    }
    objc_setAssociatedObject(instance, "adId", adId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Helper to store placementId mapping for an ad instance
- (void)storePlacementIdMappingForAdInstance:(id)adInstance withAdId:(NSString *)adId adType:(NSString *)adType {
    if (!adInstance || !adId) {
        [self.logger debug:@"storePlacementIdMapping called with nil parameter, skipping"];
        return;
    }
    
    @try {
        NSString *internalPlacementId = nil;
        @try {
            internalPlacementId = [(NSObject *)adInstance valueForKey:@"placementId"];
        } @catch (NSException *e) {
            internalPlacementId = [(NSObject *)adInstance valueForKey:@"placementID"];
        }
        
        if (internalPlacementId) {
            self.placementToAdIdMap[internalPlacementId] = adId;
        }
    } @catch (NSException *e) {
        // Silently continue
    }
    
    // For banner/MREC types, also try to access inner .ad property
    if ([adType isEqualToString:@"banner"] || [adType isEqualToString:@"mrec"]) {
        @try {
            id innerAd = [(NSObject *)adInstance valueForKey:@"ad"];
            if (innerAd) {
                [self setAdId:adId forInstance:innerAd];
                NSString *innerPlacementId = [(NSObject *)innerAd valueForKey:@"placementId"];
                if (innerPlacementId) {
                    self.placementToAdIdMap[innerPlacementId] = adId;
                }
            }
        } @catch (NSException *e) {
            // Silently continue
        }
    }
}

// Helper to get adId from CLXAd using placement mapping
- (NSString *)getAdIdForCLXAd:(CLXAd *)ad {
    // Multi-strategy lookup to handle different SDK object lifecycle scenarios
    NSString *adId = nil;
    
    // STRATEGY 1: Try placementId mapping (most reliable for current SDK)
    if (ad.placementId) {
        adId = self.placementToAdIdMap[ad.placementId];
        if (adId) {
            return adId;
        }
    }
    
    // STRATEGY 2: Try direct tag lookup (works if we successfully tagged the ad)
    adId = [self getAdIdForInstance:ad];
    if (adId) {
        return adId;
    }
    
    // STRATEGY 3: Search for wrapper containing this inner ad (last resort)
    for (NSString *candidateAdId in self.adInstances) {
        id instance = self.adInstances[candidateAdId];
        
        @try {
            id innerAd = [instance valueForKey:@"ad"];
            if (innerAd == ad) {
                adId = [self getAdIdForInstance:instance];
                if (adId) {
                    // Tag for future callbacks
                    [self setAdId:adId forInstance:ad];
                    if (ad.placementId) {
                        self.placementToAdIdMap[ad.placementId] = adId;
                    }
                    return adId;
                }
            }
        } @catch (NSException *exception) {
            // No .ad property, continue
        }
    }
    
    return nil;
}

- (void)sendEventToFlutter:(NSString *)eventName adId:(NSString *)adId data:(NSDictionary *)data {
    if (!self.eventSink) {
        [self.logger error:@"eventSink is nil, cannot send event"];
        return;
    }
    
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    arguments[@"adId"] = adId;
    arguments[@"event"] = eventName;
    if (data) {
        arguments[@"data"] = data;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.eventSink(arguments);
    });
}



#pragma mark - CLXBannerDelegate

- (void)didLoadBanner:(id<CLXAdapterBanner>)banner {
    NSString *adId = [self getAdIdForInstance:banner];
    if (adId) {
        [self sendEventToFlutter:@"didLoad" adId:adId data:nil];
    }
}

- (void)failToLoadBanner:(id<CLXAdapterBanner>)banner error:(NSError *)error {
    NSString *adId = [self getAdIdForInstance:banner];
    if (adId) {
        NSDictionary *data = @{@"error": error.localizedDescription ?: @"Unknown error"};
        [self sendEventToFlutter:@"failToLoad" adId:adId data:data];
    }
}

- (void)didLoadWithAd:(CLXAd *)ad {
    [self.logger debug:[NSString stringWithFormat:@"didLoadWithAd - placementId: %@", ad.placementId]];
    
    NSString *adId = nil;
    
    // STRATEGY 1: Try placementId mapping
    if (ad.placementId) {
        adId = self.placementToAdIdMap[ad.placementId];
    }
    
    // STRATEGY 2: Try direct tag lookup
    if (!adId) {
        adId = [self getAdIdForInstance:ad];
    }
    
    // STRATEGY 3: Search for wrapper containing this inner ad
    if (!adId) {
        for (NSString *candidateAdId in self.adInstances) {
            id instance = self.adInstances[candidateAdId];
            @try {
                id innerAd = [instance valueForKey:@"ad"];
                if (innerAd == ad) {
                    adId = [self getAdIdForInstance:instance];
                    [self setAdId:adId forInstance:ad];
                    if (ad.placementId) {
                        self.placementToAdIdMap[ad.placementId] = adId;
                    }
                    break;
                }
            } @catch (NSException *exception) {
                // No .ad property, continue
            }
        }
    }
    
    if (adId) {
        [self sendEventToFlutter:@"didLoad" adId:adId data:nil];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Could not resolve adId for placementId: %@", ad.placementId]];
    }
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    [self.logger debug:[NSString stringWithFormat:@"failToLoadWithAd - placementId: %@, error: %@", ad.placementId, error.localizedDescription]];
    
    NSString *adId = [self getAdIdForCLXAd:ad];
    
    if (adId) {
        NSDictionary *data = @{@"error": error.localizedDescription ?: @"Unknown error"};
        [self sendEventToFlutter:@"failToLoad" adId:adId data:data];
    } else {
        [self.logger error:[NSString stringWithFormat:@"Could not resolve adId for placementId: %@", ad.placementId]];
    }
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"didShow" adId:adId data:nil];
    }
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        NSDictionary *data = @{@"error": error.localizedDescription ?: @"Unknown error"};
        [self sendEventToFlutter:@"failToShow" adId:adId data:data];
    }
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"didHide" adId:adId data:nil];
    }
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"didClick" adId:adId data:nil];
    }
}

- (void)impressionOn:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"impression" adId:adId data:nil];
    }
}

- (void)closedByUserActionWithAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"closedByUserAction" adId:adId data:nil];
    }
}

- (void)revenuePaid:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"revenuePaid" adId:adId data:nil];
    }
}

#pragma mark - CLXBannerDelegate (Banner-specific methods)

- (void)didExpandAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"didExpandAd" adId:adId data:nil];
    }
}

- (void)didCollapseAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"didCollapseAd" adId:adId data:nil];
    }
}

#pragma mark - CLXInterstitialDelegate (inherits from BaseAdDelegate, so same methods)

#pragma mark - CLXNativeDelegate (inherits from BaseAdDelegate, so same methods)

#pragma mark - CLXRewardedDelegate (Rewarded-specific methods)

- (void)userRewarded:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"userRewarded" adId:adId data:nil];
    }
}

- (void)rewardedVideoStarted:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"rewardedVideoStarted" adId:adId data:nil];
    }
}

- (void)rewardedVideoCompleted:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        [self sendEventToFlutter:@"rewardedVideoCompleted" adId:adId data:nil];
    }
}

#pragma mark - CLXInterstitialDelegate (inherits from BaseAdDelegate, so same methods)

#pragma mark - CLXNativeDelegate (inherits from BaseAdDelegate, so same methods)

#pragma mark - FlutterStreamHandler

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    self.eventSink = events;
    
    // Send ready confirmation to Dart side
    dispatch_async(dispatch_get_main_queue(), ^{
        self.eventSink(@{
            @"event": @"__eventChannelReady__",
            @"adId": @"__system__"
        });
    });
    
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    self.eventSink = nil;
    return nil;
}

@end 