#import "CloudXFlutterSdkPlugin.h"
#import <CloudXCore/CloudXCore.h>
#import <CloudXCore/CLXAd.h>
#import <CloudXCore/CLXAdDelegate.h>
#import <CloudXCore/CLXURLProvider.h>
#import <Flutter/Flutter.h>
#import <objc/runtime.h>

@interface CloudXFlutterSdkPlugin () <CLXInterstitialDelegate, CLXRewardedDelegate, CLXBannerDelegate, CLXNativeDelegate, FlutterStreamHandler>
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
        
        NSLog(@"🔍 [CloudXBannerPlatformView] initWithFrame - frame: %@, viewId: %lld, adId: %@", NSStringFromCGRect(frame), viewId, adId);
        printf("🔍 [CloudXBannerPlatformView] initWithFrame - frame: %s, viewId: %lld, adId: %s\n", [NSStringFromCGRect(frame) UTF8String], viewId, [adId UTF8String]);
        
        UIView *bannerView = nil;
        if (adId && _plugin.adInstances[adId]) {
            id instance = _plugin.adInstances[adId];
            NSLog(@"🔍 [CloudXBannerPlatformView] Found ad instance for adId %@: %@", adId, instance);
            printf("🔍 [CloudXBannerPlatformView] Found ad instance for adId %s: %s\n", [adId UTF8String], [[instance description] UTF8String]);
            
            if ([instance isKindOfClass:[UIView class]]) {
                bannerView = (UIView *)instance;
                NSLog(@"🔍 [CloudXBannerPlatformView] Instance is UIView, using as bannerView: %@", bannerView);
                printf("🔍 [CloudXBannerPlatformView] Instance is UIView, using as bannerView: %s\n", [[bannerView description] UTF8String]);
            } else {
                NSLog(@"🔍 [CloudXBannerPlatformView] Instance is NOT UIView, class: %@", NSStringFromClass([instance class]));
                printf("🔍 [CloudXBannerPlatformView] Instance is NOT UIView, class: %s\n", [NSStringFromClass([instance class]) UTF8String]);
            }
        } else {
            NSLog(@"🔍 [CloudXBannerPlatformView] No ad instance found for adId: %@", adId);
            printf("🔍 [CloudXBannerPlatformView] No ad instance found for adId: %s\n", [adId UTF8String]);
            NSLog(@"🔍 [CloudXBannerPlatformView] Available ad instances: %@", _plugin.adInstances);
            NSString *instancesDescription = [_plugin.adInstances description] ?: @"nil";
            printf("🔍 [CloudXBannerPlatformView] Available ad instances: %s\n", [instancesDescription UTF8String]);
        }
        
        if (bannerView) {
            self.view = bannerView;
            
            // Remove debug border and background for production
            self.view.layer.borderWidth = 0.0;
            self.view.layer.borderColor = nil;
            self.view.backgroundColor = [UIColor clearColor];
            
            NSLog(@"🔍 [CloudXBannerPlatformView] Set bannerView as self.view with debug styling");
            printf("🔍 [CloudXBannerPlatformView] Set bannerView as self.view with debug styling\n");
            NSLog(@"🔍 [CloudXBannerPlatformView] View frame: %@", NSStringFromCGRect(self.view.frame));
            printf("🔍 [CloudXBannerPlatformView] View frame: %s\n", [NSStringFromCGRect(self.view.frame) UTF8String]);
            NSLog(@"🔍 [CloudXBannerPlatformView] View bounds: %@", NSStringFromCGRect(self.view.bounds));
            printf("🔍 [CloudXBannerPlatformView] View bounds: %s\n", [NSStringFromCGRect(self.view.bounds) UTF8String]);
            NSLog(@"🔍 [CloudXBannerPlatformView] View subviews count: %lu", (unsigned long)self.view.subviews.count);
            printf("🔍 [CloudXBannerPlatformView] View subviews count: %lu\n", (unsigned long)self.view.subviews.count);
            
            for (int i = 0; i < self.view.subviews.count; i++) {
                UIView *subview = self.view.subviews[i];
                NSLog(@"🔍 [CloudXBannerPlatformView] Subview %d: %@, frame: %@, hidden: %@", i, subview, NSStringFromCGRect(subview.frame), subview.hidden ? @"YES" : @"NO");
                printf("🔍 [CloudXBannerPlatformView] Subview %d: %s, frame: %s, hidden: %s\n", i, [[subview description] UTF8String], [NSStringFromCGRect(subview.frame) UTF8String], subview.hidden ? "YES" : "NO");
            }
            
            NSLog(@"🔍 [CloudXBannerPlatformView] View isHidden: %@", self.view.hidden ? @"YES" : @"NO");
            printf("🔍 [CloudXBannerPlatformView] View isHidden: %s\n", self.view.hidden ? "YES" : "NO");
            NSLog(@"🔍 [CloudXBannerPlatformView] View alpha: %f", self.view.alpha);
            printf("🔍 [CloudXBannerPlatformView] View alpha: %f\n", self.view.alpha);
            NSLog(@"🔍 [CloudXBannerPlatformView] View backgroundColor: %@", self.view.backgroundColor);
            printf("🔍 [CloudXBannerPlatformView] View backgroundColor: %s\n", [[self.view.backgroundColor description] UTF8String]);
            
        } else {
            // fallback: empty view
            self.view = [[UIView alloc] initWithFrame:frame];
            self.view.backgroundColor = [UIColor clearColor];
            
            NSLog(@"🔍 [CloudXBannerPlatformView] Created fallback empty view with frame: %@", NSStringFromCGRect(frame));
            printf("🔍 [CloudXBannerPlatformView] Created fallback empty view with frame: %s\n", [NSStringFromCGRect(frame) UTF8String]);
        }
        
        NSLog(@"🔍 [CloudXBannerPlatformView] Final self.view: %@", self.view);
        printf("🔍 [CloudXBannerPlatformView] Final self.view: %s\n", [[self.view description] UTF8String]);
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
        
        NSLog(@"🔍 [CloudXNativePlatformView] initWithFrame - frame: %@, viewId: %lld, adId: %@", NSStringFromCGRect(frame), viewId, adId);
        printf("🔍 [CloudXNativePlatformView] initWithFrame - frame: %s, viewId: %lld, adId: %s\n", [NSStringFromCGRect(frame) UTF8String], viewId, [adId UTF8String]);
        
        UIView *nativeView = nil;
        if (adId && _plugin.adInstances[adId]) {
            id instance = _plugin.adInstances[adId];
            NSLog(@"🔍 [CloudXNativePlatformView] Found ad instance for adId %@: %@", adId, instance);
            printf("🔍 [CloudXNativePlatformView] Found ad instance for adId %s: %s\n", [adId UTF8String], [[instance description] UTF8String]);
            
            if ([instance isKindOfClass:[UIView class]]) {
                nativeView = (UIView *)instance;
                NSLog(@"🔍 [CloudXNativePlatformView] Instance is UIView, using as nativeView: %@", nativeView);
                printf("🔍 [CloudXNativePlatformView] Instance is UIView, using as nativeView: %s\n", [[nativeView description] UTF8String]);
            } else {
                NSLog(@"🔍 [CloudXNativePlatformView] Instance is NOT UIView, class: %@", NSStringFromClass([instance class]));
                printf("🔍 [CloudXNativePlatformView] Instance is NOT UIView, class: %s\n", [NSStringFromClass([instance class]) UTF8String]);
            }
        } else {
            NSLog(@"🔍 [CloudXNativePlatformView] No ad instance found for adId: %@", adId);
            printf("🔍 [CloudXNativePlatformView] No ad instance found for adId: %s\n", [adId UTF8String]);
            NSLog(@"🔍 [CloudXNativePlatformView] Available ad instances: %@", _plugin.adInstances);
            NSString *instancesDescription = [_plugin.adInstances description] ?: @"nil";
            printf("🔍 [CloudXNativePlatformView] Available ad instances: %s\n", [instancesDescription UTF8String]);
        }
        
        if (nativeView) {
            self.view = nativeView;
            
            NSLog(@"🔍 [CloudXNativePlatformView] Set nativeView as self.view");
            printf("🔍 [CloudXNativePlatformView] Set nativeView as self.view\n");
            NSLog(@"🔍 [CloudXNativePlatformView] View frame: %@", NSStringFromCGRect(self.view.frame));
            printf("🔍 [CloudXNativePlatformView] View frame: %s\n", [NSStringFromCGRect(self.view.frame) UTF8String]);
            
        } else {
            // fallback: empty view
            self.view = [[UIView alloc] initWithFrame:frame];
            self.view.backgroundColor = [UIColor clearColor];
            
            NSLog(@"🔍 [CloudXNativePlatformView] Created fallback empty view with frame: %@", NSStringFromCGRect(frame));
            printf("🔍 [CloudXNativePlatformView] Created fallback empty view with frame: %s\n", [NSStringFromCGRect(frame) UTF8String]);
        }
        
        NSLog(@"🔍 [CloudXNativePlatformView] Final self.view: %@", self.view);
        printf("🔍 [CloudXNativePlatformView] Final self.view: %s\n", [[self.view description] UTF8String]);
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
        
        NSLog(@"🔍 [CloudXMRECPlatformView] initWithFrame - frame: %@, viewId: %lld, adId: %@", NSStringFromCGRect(frame), viewId, adId);
        printf("🔍 [CloudXMRECPlatformView] initWithFrame - frame: %s, viewId: %lld, adId: %s\n", [NSStringFromCGRect(frame) UTF8String], viewId, [adId UTF8String]);
        
        UIView *mrecView = nil;
        if (adId && _plugin.adInstances[adId]) {
            id instance = _plugin.adInstances[adId];
            NSLog(@"🔍 [CloudXMRECPlatformView] Found ad instance for adId %@: %@", adId, instance);
            printf("🔍 [CloudXMRECPlatformView] Found ad instance for adId %s: %s\n", [adId UTF8String], [[instance description] UTF8String]);
            
            if ([instance isKindOfClass:[UIView class]]) {
                mrecView = (UIView *)instance;
                NSLog(@"🔍 [CloudXMRECPlatformView] Instance is UIView, using as mrecView: %@", mrecView);
                printf("🔍 [CloudXMRECPlatformView] Instance is UIView, using as mrecView: %s\n", [[mrecView description] UTF8String]);
            } else {
                NSLog(@"🔍 [CloudXMRECPlatformView] Instance is NOT UIView, class: %@", NSStringFromClass([instance class]));
                printf("🔍 [CloudXMRECPlatformView] Instance is NOT UIView, class: %s\n", [NSStringFromClass([instance class]) UTF8String]);
            }
        } else {
            NSLog(@"🔍 [CloudXMRECPlatformView] No ad instance found for adId: %@", adId);
            printf("🔍 [CloudXMRECPlatformView] No ad instance found for adId: %s\n", [adId UTF8String]);
            NSLog(@"🔍 [CloudXMRECPlatformView] Available ad instances: %@", _plugin.adInstances);
            NSString *instancesDescription = [_plugin.adInstances description] ?: @"nil";
            printf("🔍 [CloudXMRECPlatformView] Available ad instances: %s\n", [instancesDescription UTF8String]);
        }
        
        if (mrecView) {
            self.view = mrecView;
            
            // Remove debug border and background for production
            self.view.layer.borderWidth = 0.0;
            self.view.layer.borderColor = nil;
            self.view.backgroundColor = [UIColor clearColor];
            
            NSLog(@"🔍 [CloudXMRECPlatformView] Set mrecView as self.view");
            printf("🔍 [CloudXMRECPlatformView] Set mrecView as self.view\n");
            NSLog(@"🔍 [CloudXMRECPlatformView] View frame: %@", NSStringFromCGRect(self.view.frame));
            printf("🔍 [CloudXMRECPlatformView] View frame: %s\n", [NSStringFromCGRect(self.view.frame) UTF8String]);
            
        } else {
            // fallback: empty view
            self.view = [[UIView alloc] initWithFrame:frame];
            self.view.backgroundColor = [UIColor clearColor];
            
            NSLog(@"🔍 [CloudXMRECPlatformView] Created fallback empty view with frame: %@", NSStringFromCGRect(frame));
            printf("🔍 [CloudXMRECPlatformView] Created fallback empty view with frame: %s\n", [NSStringFromCGRect(frame) UTF8String]);
        }
        
        NSLog(@"🔍 [CloudXMRECPlatformView] Final self.view: %@", self.view);
        printf("🔍 [CloudXMRECPlatformView] Final self.view: %s\n", [[self.view description] UTF8String]);
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
  
  // TEST: This should ALWAYS appear
  NSLog(@"🟢🟢🟢 [CloudX Flutter Plugin] registerWithRegistrar CALLED 🟢🟢🟢");
  printf("🟢🟢🟢 [CloudX Flutter Plugin] registerWithRegistrar CALLED 🟢🟢🟢\n");
  fflush(stdout);
  
  // Set environment variables for verbose logging
  setenv("CLOUDX_VERBOSE_LOG", "1", 1);
  setenv("CLOUDX_FLUTTER_VERBOSE_LOG", "1", 1);
  NSLog(@"🟢 [CloudX Flutter Plugin] Environment variables set: CLOUDX_VERBOSE_LOG=1, CLOUDX_FLUTTER_VERBOSE_LOG=1");
  printf("🟢 [CloudX Flutter Plugin] Environment variables set: CLOUDX_VERBOSE_LOG=1, CLOUDX_FLUTTER_VERBOSE_LOG=1\n");
  fflush(stdout);
  
  // DEMO APP ONLY: Force test mode for all bid requests
  // This internal flag ensures test=1 is always set in bid requests for demo app
  // regardless of build configuration (simulator/device, debug/release)
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CLXCore_Internal_ForceTestMode"];
  
  // DEMO APP ONLY: Enable Meta test mode for release builds
  // This ensures Meta SDK registers device as test device and serves test ads
  [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"CLXMetaTestModeEnabled"];
  
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  NSLog(@"🟢 [CloudX Flutter Plugin] Test mode flags set: CLXCore_Internal_ForceTestMode=YES, CLXMetaTestModeEnabled=YES");
  printf("🟢 [CloudX Flutter Plugin] Test mode flags set\n");
  fflush(stdout);
  
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
    
    NSLog(@"🔴 [CloudX Flutter] initSDK called with appKey: %@, hashedUserID: %@", appKey, hashedUserID);
    printf("🔴 [CloudX Flutter] initSDK called with appKey: %s, hashedUserID: %s\n", [appKey UTF8String], [hashedUserID UTF8String] ?: "nil");
    
    if (!appKey) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"appKey is required" 
                                  details:nil]);
        return;
    }
    
    if (hashedUserID) {
        NSLog(@"🔴 [CloudX Flutter] Calling initSDK WITH hashedUserID");
        printf("🔴 [CloudX Flutter] Calling initSDK WITH hashedUserID\n");
        [[CloudXCore shared] initializeSDKWithAppKey:appKey 
                                        hashedUserID:hashedUserID 
                                          completion:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"🔴 [CloudX Flutter] initSDK completion - success: %d, error: %@", success, error);
            printf("🔴 [CloudX Flutter] initSDK completion - success: %d, error: %s\n", success, [[error description] UTF8String] ?: "nil");
            [self handleInitResult:success error:error result:result];
        }];
    } else {
        NSLog(@"🔴 [CloudX Flutter] Calling initSDK WITHOUT hashedUserID");
        printf("🔴 [CloudX Flutter] Calling initSDK WITHOUT hashedUserID\n");
        [[CloudXCore shared] initializeSDKWithAppKey:appKey 
                                          completion:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"🔴 [CloudX Flutter] initSDK completion - success: %d, error: %@", success, error);
            printf("🔴 [CloudX Flutter] initSDK completion - success: %d, error: %s\n", success, [[error description] UTF8String] ?: "nil");
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
        NSLog(@"✅ [CloudX Plugin] createBanner SUCCESS - banner: %p, class: %@, adId: %@", 
              bannerAd, NSStringFromClass([bannerAd class]), adId);
        
        // Store instance and tag it (old simple approach)
        self.adInstances[adId] = bannerAd;
        [self setAdId:adId forInstance:bannerAd];
        NSLog(@"✅ [CloudX Plugin] Stored and tagged banner instance %p with adId '%@'", bannerAd, adId);
        
        // Try to get the CloudX internal placementId and store the mapping
        // This is critical because the delegate receives a different CLXAd object
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
    
    NSLog(@"[Flutter Plugin] createInterstitial called with placement: %@, adId: %@", placement, adId);
    printf("[Flutter Plugin] createInterstitial called with placement: %s, adId: %s\n", [placement UTF8String], [adId UTF8String]);
    
    if (!placement || !adId) {
        NSLog(@"[Flutter Plugin] createInterstitial ERROR - placement and adId are required");
        printf("[Flutter Plugin] createInterstitial ERROR - placement and adId are required\n");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    NSLog(@"[Flutter Plugin] createInterstitial - About to create interstitial with delegate: %@", self);
    printf("[Flutter Plugin] createInterstitial - About to create interstitial with delegate: %s\n", [[self description] UTF8String]);
    
    CLXPublisherFullscreenAd *interstitialAd = [[CloudXCore shared] createInterstitialWithPlacement:placement
                                                                                              delegate:self];
    
    NSLog(@"[Flutter Plugin] createInterstitial: interstitialAd created: %@", interstitialAd);
    printf("[Flutter Plugin] createInterstitial: interstitialAd created: %s\n", [[interstitialAd description] UTF8String]);
    
    if (interstitialAd) {
        NSLog(@"[Flutter Plugin] createInterstitial - Storing interstitial instance in adInstances for adId: %@", adId);
        printf("[Flutter Plugin] createInterstitial - Storing interstitial instance in adInstances for adId: %s\n", [adId UTF8String]);
        
        self.adInstances[adId] = interstitialAd;
        [self setAdId:adId forInstance:interstitialAd];
        
        // Try to get the CloudX internal placementId and store the mapping (like we do for banners)
        [self storePlacementIdMappingForAdInstance:interstitialAd withAdId:adId adType:@"interstitial"];
        
        // Call load() on the interstitial instance, following the working Objective-C app pattern
        NSLog(@"[Flutter Plugin] createInterstitial - Calling load() on interstitial instance");
        printf("[Flutter Plugin] createInterstitial - Calling load() on interstitial instance\n");
        [interstitialAd load];
        
        NSLog(@"[Flutter Plugin] createInterstitial - Returning success to Flutter");
        printf("[Flutter Plugin] createInterstitial - Returning success to Flutter\n");
        result(@YES);
    } else{
        NSLog(@"[Flutter Plugin] createInterstitial: FAILED to create interstitial ad");
        printf("[Flutter Plugin] createInterstitial: FAILED to create interstitial ad\n");
        result([FlutterError errorWithCode:@"AD_CREATION_FAILED" 
                                  message:@"Failed to create interstitial ad" 
                                  details:nil]);
    }
}

- (void)createRewarded:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *placement = arguments[@"placement"];
    NSString *adId = arguments[@"adId"];
    
    NSLog(@"[Flutter Plugin] createRewarded called with placement: %@, adId: %@", placement, adId);
    printf("[Flutter Plugin] createRewarded called with placement: %s, adId: %s\n", [placement UTF8String], [adId UTF8String]);
    
    if (!placement || !adId) {
        NSLog(@"[Flutter Plugin] createRewarded ERROR - placement and adId are required");
        printf("[Flutter Plugin] createRewarded ERROR - placement and adId are required\n");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    NSLog(@"[Flutter Plugin] createRewarded - About to create rewarded with delegate: %@", self);
    printf("[Flutter Plugin] createRewarded - About to create rewarded with delegate: %s\n", [[self description] UTF8String]);
    
    CLXPublisherFullscreenAd *rewardedAd = [[CloudXCore shared] createRewardedWithPlacement:placement
                                                                                     delegate:self];
    
    NSLog(@"[Flutter Plugin] createRewarded: rewardedAd created: %@", rewardedAd);
    printf("[Flutter Plugin] createRewarded: rewardedAd created: %s\n", [[rewardedAd description] UTF8String]);
    
    if (rewardedAd) {
        NSLog(@"[Flutter Plugin] createRewarded - Storing rewarded instance in adInstances for adId: %@", adId);
        printf("[Flutter Plugin] createRewarded - Storing rewarded instance in adInstances for adId: %s\n", [adId UTF8String]);
        
        self.adInstances[adId] = rewardedAd;
        [self setAdId:adId forInstance:rewardedAd];
        
        // Try to get the CloudX internal placementId and store the mapping
        [self storePlacementIdMappingForAdInstance:rewardedAd withAdId:adId adType:@"rewarded"];
        
        // Call load() on the rewarded instance, following the working Objective-C app pattern
        NSLog(@"[Flutter Plugin] createRewarded - Calling load() on rewarded instance");
        printf("[Flutter Plugin] createRewarded - Calling load() on rewarded instance\n");
        [rewardedAd load];
        
        NSLog(@"[Flutter Plugin] createRewarded - Returning success to Flutter");
        printf("[Flutter Plugin] createRewarded - Returning success to Flutter\n");
        result(@YES);
    } else {
        NSLog(@"[Flutter Plugin] createRewarded: FAILED to create rewarded ad");
        printf("[Flutter Plugin] createRewarded: FAILED to create rewarded ad\n");
        result([FlutterError errorWithCode:@"AD_CREATION_FAILED" 
                                  message:@"Failed to create rewarded ad" 
                                  details:nil]);
    }
}

- (void)createNative:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *placement = arguments[@"placement"];
    NSString *adId = arguments[@"adId"];
    
    NSLog(@"[Flutter Plugin] createNative called with placement: %@, adId: %@", placement, adId);
    printf("[Flutter Plugin] createNative called with placement: %s, adId: %s\n", [placement UTF8String], [adId UTF8String]);
    
    if (!placement || !adId) {
        NSLog(@"[Flutter Plugin] createNative ERROR - placement and adId are required");
        printf("[Flutter Plugin] createNative ERROR - placement and adId are required\n");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    UIViewController *viewController = [self getTopViewController];
    NSLog(@"[Flutter Plugin] createNative - got viewController: %@", viewController);
    printf("[Flutter Plugin] createNative - got viewController: %s\n", [[viewController description] UTF8String]);
    
    NSLog(@"[Flutter Plugin] createNative - About to create native with delegate: %@", self);
    printf("[Flutter Plugin] createNative - About to create native with delegate: %s\n", [[self description] UTF8String]);
    
        CLXNativeAdView *nativeAd = [[CloudXCore shared] createNativeAdWithPlacement:placement
                                                                        viewController:viewController
                                                                            delegate:self];
    
    NSLog(@"[Flutter Plugin] createNative: nativeAd created: %@", nativeAd);
    printf("[Flutter Plugin] createNative: nativeAd created: %s\n", [[nativeAd description] UTF8String]);
    
    if (nativeAd) {
        NSLog(@"[Flutter Plugin] createNative - Storing native instance in adInstances for adId: %@", adId);
        printf("[Flutter Plugin] createNative - Storing native instance in adInstances for adId: %s\n", [adId UTF8String]);
        
        self.adInstances[adId] = nativeAd;
        [self setAdId:adId forInstance:nativeAd];
        
        // Call load() on the native instance, following the working Objective-C app pattern
        NSLog(@"[Flutter Plugin] createNative - Calling load() on native instance");
        printf("[Flutter Plugin] createNative - Calling load() on native instance\n");
        [nativeAd load];
        
        NSLog(@"[Flutter Plugin] createNative - Returning success to Flutter");
        printf("[Flutter Plugin] createNative - Returning success to Flutter\n");
        result(@YES);
    } else {
        NSLog(@"[Flutter Plugin] createNative: FAILED to create native ad");
        printf("[Flutter Plugin] createNative: FAILED to create native ad\n");
        result([FlutterError errorWithCode:@"AD_CREATION_FAILED" 
                                  message:@"Failed to create native ad" 
                                  details:nil]);
    }
}

- (void)createMREC:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *placement = arguments[@"placement"];
    NSString *adId = arguments[@"adId"];
    
    NSLog(@"[Flutter Plugin] createMREC called with placement: %@, adId: %@", placement, adId);
    printf("[Flutter Plugin] createMREC called with placement: %s, adId: %s\n", [placement UTF8String], [adId UTF8String]);
    
    if (!placement || !adId) {
        NSLog(@"[Flutter Plugin] createMREC ERROR - placement and adId are required");
        printf("[Flutter Plugin] createMREC ERROR - placement and adId are required\n");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    UIViewController *viewController = [self getTopViewController];
    NSLog(@"[Flutter Plugin] createMREC - got viewController: %@", viewController);
    printf("[Flutter Plugin] createMREC - got viewController: %s\n", [[viewController description] UTF8String]);
    
    NSLog(@"[Flutter Plugin] createMREC - About to create MREC with delegate: %@", self);
    printf("[Flutter Plugin] createMREC - About to create MREC with delegate: %s\n", [[self description] UTF8String]);
    
    // Match the working Objective-C app exactly: createMRECWithPlacement:viewController:delegate:
        CLXBannerAdView *mrecAd = [[CloudXCore shared] createMRECWithPlacement:placement
                                                                  viewController:viewController
                                                                      delegate:self];
    
    NSLog(@"[Flutter Plugin] createMREC: mrecAd created: %@", mrecAd);
    printf("[Flutter Plugin] createMREC: mrecAd created: %s\n", [[mrecAd description] UTF8String]);
    
    if (mrecAd) {
        NSLog(@"[Flutter Plugin] createMREC - Storing MREC instance in adInstances for adId: %@", adId);
        printf("[Flutter Plugin] createMREC - Storing MREC instance in adInstances for adId: %s\n", [adId UTF8String]);
        
        self.adInstances[adId] = mrecAd;
        [self setAdId:adId forInstance:mrecAd];
        
        // Store placementId mapping and tag inner ad if available
        [self storePlacementIdMappingForAdInstance:mrecAd withAdId:adId adType:@"mrec"];
        
        // Note: MREC does NOT call load() here - that happens when showing, following the working app pattern
        NSLog(@"[Flutter Plugin] createMREC - MREC created successfully, load() will be called when showing");
        printf("[Flutter Plugin] createMREC - MREC created successfully, load() will be called when showing\n");
        
        NSLog(@"[Flutter Plugin] createMREC - Returning success to Flutter");
        printf("[Flutter Plugin] createMREC - Returning success to Flutter\n");
        result(@YES);
    } else {
        NSLog(@"[Flutter Plugin] createMREC: FAILED to create MREC ad");
        printf("[Flutter Plugin] createMREC: FAILED to create MREC ad\n");
        result([FlutterError errorWithCode:@"AD_CREATION_FAILED" 
                                  message:@"Failed to create MREC ad" 
                                  details:nil]);
    }
}

#pragma mark - Ad Operations

- (void)loadAd:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *adId = arguments[@"adId"];
    
    NSLog(@"🚀 [CloudX Plugin] loadAd called - adId: %@", adId);
    
    if (!adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adId is required" 
                                  details:nil]);
        return;
    }
    
    id adInstance = self.adInstances[adId];
    NSLog(@"🔍 [CloudX Plugin] loadAd - adInstance: %p, class: %@", adInstance, NSStringFromClass([adInstance class]));
    
    if (!adInstance) {
        NSLog(@"❌ [CloudX Plugin] loadAd ERROR - adInstance not found for adId: %@", adId);
        result([FlutterError errorWithCode:@"AD_NOT_FOUND" 
                                  message:@"Ad instance not found" 
                                  details:nil]);
        return;
    }
    
    // Call load method on the ad instance
    if ([adInstance respondsToSelector:@selector(load)]) {
        // Try to get placementId and store mapping (might be available now even if it wasn't at creation)
        @try {
            // Try direct placementId access
            if ([adInstance respondsToSelector:@selector(placementId)]) {
                NSString *internalPlacementId = [adInstance valueForKey:@"placementId"];
                if (internalPlacementId) {
                    self.placementToAdIdMap[internalPlacementId] = adId;
                    NSLog(@"✅ [CloudX Plugin] Stored placementId mapping at load: '%@' -> '%@'", internalPlacementId, adId);
                }
            }
            
            // Tag the inner ad if it exists (in case SDK passes it to delegates)
            id innerAd = [adInstance valueForKey:@"ad"];
            if (innerAd) {
                [self setAdId:adId forInstance:innerAd];
                NSLog(@"✅ [CloudX Plugin] Also tagged inner ad %p with adId '%@'", innerAd, adId);
                
                // Try to get placementId from inner ad
                if ([innerAd respondsToSelector:@selector(placementId)]) {
                    NSString *innerPlacementId = [innerAd valueForKey:@"placementId"];
                    if (innerPlacementId) {
                        self.placementToAdIdMap[innerPlacementId] = adId;
                        NSLog(@"✅ [CloudX Plugin] Stored inner placementId mapping at load: '%@' -> '%@'", innerPlacementId, adId);
                    }
                }
            }
        } @catch (NSException *exception) {
            // No inner ad, that's fine
        }
        
        // Perform the actual load using performSelector to avoid ambiguous method signature issues
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [adInstance performSelector:@selector(load)];
        #pragma clang diagnostic pop
        NSLog(@"✅ [CloudX Plugin] loadAd completed for adId: %@", adId);
        result(@YES);
    } else {
        NSLog(@"❌ [CloudX Plugin] Ad instance does not support loading");
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
    NSLog(@"🗑️ [CloudX Plugin] destroyAd called with adId: %@", adId);
    
    if (!adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adId is required" 
                                  details:nil]);
        return;
    }
    
    id adInstance = self.adInstances[adId];
    
    if (adInstance) {
        // Clean up associated objects (old simple approach)
        objc_setAssociatedObject(adInstance, "adId", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        // Clean up inner ad's associated objects (for banner/MREC)
        @try {
            id innerAd = [adInstance valueForKey:@"ad"];
            if (innerAd) {
                objc_setAssociatedObject(innerAd, "adId", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        } @catch (NSException *exception) {
            // No inner ad, that's fine
        }
        
        // Call destroy if supported
        if ([adInstance respondsToSelector:@selector(destroy)]) {
            [adInstance destroy];
        }
        
        // Clean up from state dictionaries
        [self.adInstances removeObjectForKey:adId];
        [self.pendingResults removeObjectForKey:adId];
        
        NSLog(@"✅ [CloudX Plugin] destroyAd complete for adId: %@", adId);
    } else {
        NSLog(@"⚠️ [CloudX Plugin] destroyAd - ad instance not found for adId: %@", adId);
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
    if (!instance) {
        NSLog(@"⚠️ [CloudX Plugin] setAdId called with nil instance, skipping");
        return;
    }
    if (!adId) {
        NSLog(@"⚠️ [CloudX Plugin] setAdId called with nil adId, skipping");
        return;
    }
    objc_setAssociatedObject(instance, "adId", adId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// Helper to store placementId mapping for an ad instance
- (void)storePlacementIdMappingForAdInstance:(id)adInstance withAdId:(NSString *)adId adType:(NSString *)adType {
    if (!adInstance) {
        NSLog(@"⚠️ [CloudX Plugin] storePlacementIdMapping called with nil adInstance, skipping");
        return;
    }
    if (!adId) {
        NSLog(@"⚠️ [CloudX Plugin] storePlacementIdMapping called with nil adId, skipping");
        return;
    }
    
    NSLog(@"🔍🔍🔍 [CloudX Plugin] storePlacementIdMapping START - adType: %@, adId: %@, instance: %p, class: %@", 
          adType, adId, adInstance, NSStringFromClass([adInstance class]));
    
    @try {
        // Try direct placementId access using KVC (don't check respondsToSelector for properties on protocol types)
        // Note: CLXPublisherFullscreenAd uses "placementID" (capital ID), but banners/MREC use "placementId" (lowercase id)
        NSLog(@"🔍 [CloudX Plugin] Attempting KVC for placementId on %@...", NSStringFromClass([adInstance class]));
        NSString *internalPlacementId = nil;
        @try {
            internalPlacementId = [(NSObject *)adInstance valueForKey:@"placementId"];
        } @catch (NSException *e) {
            // Try with capital ID for fullscreen ads
            internalPlacementId = [(NSObject *)adInstance valueForKey:@"placementID"];
        }
        NSLog(@"🔍 [CloudX Plugin] KVC completed - placementId: %@", internalPlacementId ?: @"(nil)");
        
        if (internalPlacementId) {
            self.placementToAdIdMap[internalPlacementId] = adId;
            NSLog(@"✅✅✅ [CloudX Plugin] Stored %@ placementId mapping: '%@' -> '%@'", adType, internalPlacementId, adId);
        } else {
            NSLog(@"📊📊📊 [DEBUG] %@ placementId is nil at creation time", adType);
        }
    } @catch (NSException *e) {
        NSLog(@"⚠️⚠️⚠️ [DEBUG] KVC EXCEPTION for %@ placementId: %@ - %@", adType, e.name, e.reason);
    }
    
    // For banner/MREC types, also try to access inner .ad property (may be nil at creation)
    if ([adType isEqualToString:@"banner"] || [adType isEqualToString:@"mrec"]) {
        NSLog(@"🔍 [CloudX Plugin] Checking inner ad for %@...", adType);
        @try {
            id innerAd = [(NSObject *)adInstance valueForKey:@"ad"];
            if (innerAd) {
                NSLog(@"✅ [CloudX Plugin] Inner ad exists at creation: %p, tagging it", innerAd);
                [self setAdId:adId forInstance:innerAd];
                
                // Try to get placementId from inner ad
                NSString *innerPlacementId = [(NSObject *)innerAd valueForKey:@"placementId"];
                if (innerPlacementId) {
                    self.placementToAdIdMap[innerPlacementId] = adId;
                    NSLog(@"✅ [CloudX Plugin] Stored inner placementId mapping: '%@' -> '%@'", innerPlacementId, adId);
                }
            } else {
                NSLog(@"📊 [DEBUG] Inner ad is nil at creation");
            }
        } @catch (NSException *e) {
            NSLog(@"⚠️ [DEBUG] Could not access inner ad for %@: %@", adType, e.reason);
        }
    }
    
    NSLog(@"🔍🔍🔍 [CloudX Plugin] storePlacementIdMapping END - placementToAdIdMap keys: %@", [self.placementToAdIdMap allKeys]);
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
    NSLog(@"🔍 [Flutter Plugin] sendEventToFlutter START - eventName: %@, adId: %@, data: %@", eventName, adId, data);
    printf("🔍 [Flutter Plugin] sendEventToFlutter START - eventName: %s, adId: %s, data: %s\n", [eventName UTF8String], [adId UTF8String], [[data description] UTF8String]);
    
    if (!self.eventSink) {
        NSLog(@"🔍 [Flutter Plugin] sendEventToFlutter ERROR - eventSink is nil, cannot send event");
        printf("🔍 [Flutter Plugin] sendEventToFlutter ERROR - eventSink is nil, cannot send event\n");
        return;
    }
    
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    arguments[@"adId"] = adId;
    arguments[@"event"] = eventName;
    if (data) {
        arguments[@"data"] = data;
    }
    
    NSLog(@"🔍 [Flutter Plugin] sendEventToFlutter - Created arguments: %@", arguments);
    printf("🔍 [Flutter Plugin] sendEventToFlutter - Created arguments: %s\n", [[arguments description] UTF8String]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"🔍 [Flutter Plugin] sendEventToFlutter - Calling eventSink on main queue");
        printf("🔍 [Flutter Plugin] sendEventToFlutter - Calling eventSink on main queue\n");
        self.eventSink(arguments);
        NSLog(@"🔍 [Flutter Plugin] sendEventToFlutter - eventSink called successfully");
        printf("🔍 [Flutter Plugin] sendEventToFlutter - eventSink called successfully\n");
    });
    
    NSLog(@"🔍 [Flutter Plugin] sendEventToFlutter END");
    printf("🔍 [Flutter Plugin] sendEventToFlutter END\n");
}



#pragma mark - CLXBannerDelegate

- (void)didLoadBanner:(id<CLXAdapterBanner>)banner {
    NSLog(@"🔴🔴🔴 [Flutter Plugin] didLoadBanner called for banner: %@", banner);
    printf("🔴🔴🔴 [Flutter Plugin] didLoadBanner called for banner: %s\n", [[banner description] UTF8String]);
    
    // Get adId directly from the banner object (set during creation)
    NSString *adId = [self getAdIdForInstance:banner];
    
    if (adId) {
        NSLog(@"🔍 [Flutter Plugin] didLoadBanner - Found adId: %@, sending event to Flutter", adId);
        printf("🔍 [Flutter Plugin] didLoadBanner - Found adId: %s, sending event to Flutter\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"didLoad" adId:adId data:nil];
        
        NSLog(@"🔍 [Flutter Plugin] didLoadBanner - Event sent to Flutter");
        printf("🔍 [Flutter Plugin] didLoadBanner - Event sent to Flutter\n");
    } else {
        NSLog(@"🔍 [Flutter Plugin] didLoadBanner ERROR - could not find adId for banner: %@", banner);
        printf("🔍 [Flutter Plugin] didLoadBanner ERROR - could not find adId for banner: %s\n", [[banner description] UTF8String]);
    }
    
    NSLog(@"🔍 [Flutter Plugin] didLoadBanner END");
    printf("🔍 [Flutter Plugin] didLoadBanner END\n");
}

- (void)failToLoadBanner:(id<CLXAdapterBanner>)banner error:(NSError *)error {
    NSLog(@"🔴🔴🔴 [Flutter Plugin] failToLoadBanner called for banner: %@, error: %@", banner, error.localizedDescription);
    printf("🔴🔴🔴 [Flutter Plugin] failToLoadBanner called for banner: %s, error: %s\n", [[banner description] UTF8String], [error.localizedDescription UTF8String]);
    
    // Get adId directly from the banner object (set during creation)
    NSString *adId = [self getAdIdForInstance:banner];
    
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] failToLoadBanner - adId: %@, error: %@", adId, error.localizedDescription);
        printf("🔴 [Flutter Plugin] failToLoadBanner - adId: %s, error: %s\n", [adId UTF8String], [error.localizedDescription UTF8String]);
        
        NSDictionary *data = @{@"error": error.localizedDescription ?: @"Unknown error"};
        [self sendEventToFlutter:@"failToLoad" adId:adId data:data];
    } else {
        NSLog(@"🔴 [Flutter Plugin] failToLoadBanner - could not find adId for banner: %@", banner);
        printf("🔴 [Flutter Plugin] failToLoadBanner - could not find adId for banner: %s\n", [[banner description] UTF8String]);
    }
}

- (void)didLoadWithAd:(CLXAd *)ad {
    NSLog(@"🎯 [CloudX Plugin] didLoadWithAd called - ad: %p, class: %@, placementId: %@", 
          ad, NSStringFromClass([ad class]), ad.placementId);
    
    NSString *adId = nil;
    
    // STRATEGY 1: Try placementId mapping (most reliable for current SDK)
    if (ad.placementId) {
        adId = self.placementToAdIdMap[ad.placementId];
        if (adId) {
            NSLog(@"✅ [CloudX Plugin] Found adId via placementId mapping: '%@' -> '%@'", ad.placementId, adId);
        } else {
            NSLog(@"📊 [DEBUG] No mapping found for placementId: '%@'", ad.placementId);
        }
    }
    
    // STRATEGY 2: Try direct tag lookup (works if we successfully tagged the ad)
    if (!adId) {
        adId = [self getAdIdForInstance:ad];
        if (adId) {
            NSLog(@"✅ [CloudX Plugin] Found adId via direct tag: '%@'", adId);
        }
    }
    
    // STRATEGY 3: Search for wrapper containing this inner ad (last resort)
    if (!adId) {
        NSLog(@"🔍 [DEBUG] Searching for wrapper containing inner ad...");
        for (NSString *candidateAdId in self.adInstances) {
            id instance = self.adInstances[candidateAdId];
            
            @try {
                id innerAd = [instance valueForKey:@"ad"];
                if (innerAd == ad) {
                    adId = [self getAdIdForInstance:instance];
                    NSLog(@"✅ [CloudX Plugin] Found wrapper! Wrapper %p contains inner ad %p, adId: %@", 
                          instance, ad, adId);
                    
                    // Tag for future callbacks
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
        NSLog(@"✅ [CloudX Plugin] Resolved adId: '%@', sending to Flutter", adId);
        [self sendEventToFlutter:@"didLoad" adId:adId data:nil];
    } else {
        NSLog(@"❌ [CloudX Plugin] CRITICAL ERROR - Could not resolve adId for ad %p (placementId: %@)", ad, ad.placementId);
        NSLog(@"❌ [DEBUG] placementToAdIdMap: %@", self.placementToAdIdMap);
        NSLog(@"❌ [DEBUG] adInstances: %@", [self.adInstances allKeys]);
    }
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"🔴 [Flutter Plugin] failToLoadWithAd called - ad: %p, class: %@, placementId: %@, error: %@", 
          ad, NSStringFromClass([ad class]), ad.placementId, error.localizedDescription);
    
    NSString *adId = nil;
    
    // STRATEGY 1: Try placementId mapping (most reliable for current SDK)
    if (ad.placementId) {
        adId = self.placementToAdIdMap[ad.placementId];
        if (adId) {
            NSLog(@"✅ [Flutter Plugin] Found adId via placementId mapping: '%@' -> '%@'", ad.placementId, adId);
        } else {
            NSLog(@"📊 [DEBUG] No mapping found for placementId: '%@'", ad.placementId);
        }
    }
    
    // STRATEGY 2: Try direct tag lookup (works if we successfully tagged the ad)
    if (!adId) {
        adId = [self getAdIdForInstance:ad];
        if (adId) {
            NSLog(@"✅ [Flutter Plugin] Found adId via direct tag: '%@'", adId);
        }
    }
    
    // STRATEGY 3: Search for wrapper containing this inner ad (last resort)
    if (!adId) {
        NSLog(@"🔍 [DEBUG] Searching for wrapper containing inner ad...");
        for (NSString *candidateAdId in self.adInstances) {
            id instance = self.adInstances[candidateAdId];
            
            @try {
                id innerAd = [instance valueForKey:@"ad"];
                if (innerAd == ad) {
                    adId = [self getAdIdForInstance:instance];
                    NSLog(@"✅ [Flutter Plugin] Found wrapper! Wrapper %p contains inner ad %p, adId: %@", 
                          instance, ad, adId);
                    
                    // Tag for future callbacks
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
        NSLog(@"✅ [Flutter Plugin] Resolved adId: '%@', sending failToLoad to Flutter", adId);
        NSDictionary *data = @{@"error": error.localizedDescription ?: @"Unknown error"};
        [self sendEventToFlutter:@"failToLoad" adId:adId data:data];
    } else {
        NSLog(@"❌ [Flutter Plugin] CRITICAL ERROR - Could not resolve adId for ad %p (placementId: %@)", ad, ad.placementId);
        NSLog(@"❌ [DEBUG] placementToAdIdMap: %@", self.placementToAdIdMap);
        NSLog(@"❌ [DEBUG] adInstances: %@", [self.adInstances allKeys]);
    }
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] didShowWithAd - adId: %@", adId);
        printf("🔴 [Flutter Plugin] didShowWithAd - adId: %s\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"didShow" adId:adId data:nil];
    } else {
        NSLog(@"🔴 [Flutter Plugin] didShowWithAd - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] didShowWithAd - could not find adId for ad: %s\n", [[ad description] UTF8String]);
    }
}

- (void)failToShowWithAd:(CLXAd *)ad error:(NSError *)error {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] failToShowWithAd - adId: %@, error: %@", adId, error.localizedDescription);
        printf("🔴 [Flutter Plugin] failToShowWithAd - adId: %s, error: %s\n", [adId UTF8String], [error.localizedDescription UTF8String]);
        
        NSDictionary *data = @{@"error": error.localizedDescription ?: @"Unknown error"};
        [self sendEventToFlutter:@"failToShow" adId:adId data:data];
    } else {
        NSLog(@"🔴 [Flutter Plugin] failToShowWithAd - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] failToShowWithAd - could not find adId for ad: %s\n", [[ad description] UTF8String]);
    }
}

- (void)didHideWithAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] didHideWithAd - adId: %@", adId);
        printf("🔴 [Flutter Plugin] didHideWithAd - adId: %s\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"didHide" adId:adId data:nil];
    } else {
        NSLog(@"🔴 [Flutter Plugin] didHideWithAd - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] didHideWithAd - could not find adId for ad: %s\n", [[ad description] UTF8String]);
    }
}

- (void)didClickWithAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] didClickWithAd - adId: %@", adId);
        printf("🔴 [Flutter Plugin] didClickWithAd - adId: %s\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"didClick" adId:adId data:nil];
    } else {
        NSLog(@"🔴 [Flutter Plugin] didClickWithAd - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] didClickWithAd - could not find adId for ad: %s\n", [[ad description] UTF8String]);
    }
}

- (void)impressionOn:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] impressionOn - adId: %@", adId);
        printf("🔴 [Flutter Plugin] impressionOn - adId: %s\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"impression" adId:adId data:nil];
    } else {
        NSLog(@"🔴 [Flutter Plugin] impressionOn - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] impressionOn - could not find adId for ad: %s\n", [[ad description] UTF8String]);
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
        NSLog(@"🔴 [Flutter Plugin] userRewarded - adId: %@", adId);
        printf("🔴 [Flutter Plugin] userRewarded - adId: %s\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"userRewarded" adId:adId data:nil];
    } else {
        NSLog(@"🔴 [Flutter Plugin] userRewarded - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] userRewarded - could not find adId for ad: %s\n", [[ad description] UTF8String]);
    }
}

- (void)rewardedVideoStarted:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] rewardedVideoStarted - adId: %@", adId);
        printf("🔴 [Flutter Plugin] rewardedVideoStarted - adId: %s\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"rewardedVideoStarted" adId:adId data:nil];
    } else {
        NSLog(@"🔴 [Flutter Plugin] rewardedVideoStarted - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] rewardedVideoStarted - could not find adId for ad: %s\n", [[ad description] UTF8String]);
    }
}

- (void)rewardedVideoCompleted:(CLXAd *)ad {
    NSString *adId = [self getAdIdForCLXAd:ad];
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] rewardedVideoCompleted - adId: %@", adId);
        printf("🔴 [Flutter Plugin] rewardedVideoCompleted - adId: %s\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"rewardedVideoCompleted" adId:adId data:nil];
    } else {
        NSLog(@"🔴 [Flutter Plugin] rewardedVideoCompleted - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] rewardedVideoCompleted - could not find adId for ad: %s\n", [[ad description] UTF8String]);
    }
}

#pragma mark - CLXInterstitialDelegate (inherits from BaseAdDelegate, so same methods)

#pragma mark - CLXNativeDelegate (inherits from BaseAdDelegate, so same methods)

#pragma mark - FlutterStreamHandler

- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    NSLog(@"🔴 [Flutter Plugin] onListenWithArguments called");
    printf("🔴 [Flutter Plugin] onListenWithArguments called\n");
    self.eventSink = events;
    
    // Send ready confirmation to Dart side
    dispatch_async(dispatch_get_main_queue(), ^{
        self.eventSink(@{
            @"event": @"__eventChannelReady__",
            @"adId": @"__system__"
        });
        NSLog(@"🔴 [Flutter Plugin] Sent EventChannel ready confirmation");
        printf("🔴 [Flutter Plugin] Sent EventChannel ready confirmation\n");
    });
    
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    NSLog(@"🔴 [Flutter Plugin] onCancelWithArguments called");
    printf("🔴 [Flutter Plugin] onCancelWithArguments called\n");
    self.eventSink = nil;
    return nil;
}

@end 