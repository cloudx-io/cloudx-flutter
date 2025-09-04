#import "CloudXFlutterSdkPlugin.h"
#import <CloudXCore/CloudXCore.h>
#import <Flutter/Flutter.h>
#import <objc/runtime.h>

@interface CloudXFlutterSdkPlugin () <CLXInterstitialDelegate, CLXRewardedDelegate, CLXBannerDelegate, CLXNativeDelegate, FlutterStreamHandler>
@property (nonatomic, strong) FlutterMethodChannel *channel;
@property (nonatomic, strong) FlutterEventChannel *eventChannel;
@property (nonatomic, strong) FlutterEventSink eventSink;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *adInstances;
@property (nonatomic, strong) NSMutableDictionary<NSString *, FlutterResult> *pendingResults;
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
  
  // Set environment variables for verbose logging
  setenv("CLOUDX_FLUTTER_VERBOSE_LOG", "1", 1);
  NSLog(@"[CloudX Flutter Plugin] Environment variables set: CLOUDX_VERBOSE_LOG=1, CLOUDX_FLUTTER_VERBOSE_LOG=1");
  
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
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    if ([call.method isEqualToString:@"test"]) {
        result(@"TEST_SUCCESS");
    } else if ([call.method isEqualToString:@"testMethod"]) {
        result(@"TEST_SUCCESS");
    } else if ([call.method isEqualToString:@"enableVerboseLogging"]) {
        result(@YES);
    } else if ([call.method isEqualToString:@"initSDK"]) {
        NSLog(@"[Flutter Plugin] initSDK method called");
        printf("[Flutter Plugin] initSDK method called\n");
        [self initSDK:call.arguments result:result];
    } else if ([call.method isEqualToString:@"createBanner"]) {
        NSLog(@"[Flutter Plugin] createBanner method called");
        printf("[Flutter Plugin] createBanner method called\n");
        [self createBanner:call.arguments result:result];
    } else if ([call.method isEqualToString:@"createInterstitial"]) {
        NSLog(@"[Flutter Plugin] createInterstitial method called");
        printf("[Flutter Plugin] createInterstitial method called\n");
        [self createInterstitial:call.arguments result:result];
    } else if ([call.method isEqualToString:@"createRewarded"]) {
        NSLog(@"[Flutter Plugin] createRewarded method called");
        printf("[Flutter Plugin] createRewarded method called\n");
        [self createRewarded:call.arguments result:result];
    } else if ([call.method isEqualToString:@"createNative"]) {
        NSLog(@"[Flutter Plugin] createNative method called");
        printf("[Flutter Plugin] createNative method called\n");
        [self createNative:call.arguments result:result];
    } else if ([call.method isEqualToString:@"createMREC"]) {
        NSLog(@"[Flutter Plugin] createMREC method called");
        printf("[Flutter Plugin] createMREC method called\n");
        [self createMREC:call.arguments result:result];
    } else if ([call.method isEqualToString:@"loadAd"]) {
        NSLog(@"[Flutter Plugin] loadAd method called");
        printf("[Flutter Plugin] loadAd method called\n");
        [self loadAd:call.arguments result:result];
    } else if ([call.method isEqualToString:@"showAd"]) {
        NSLog(@"[Flutter Plugin] showAd method called");
        printf("[Flutter Plugin] showAd method called\n");
        [self showAd:call.arguments result:result];
    } else if ([call.method isEqualToString:@"hideAd"]) {
        NSLog(@"[Flutter Plugin] hideAd method called");
        printf("[Flutter Plugin] hideAd method called\n");
        [self hideAd:call.arguments result:result];
    } else if ([call.method isEqualToString:@"isAdReady"]) {
        NSLog(@"[Flutter Plugin] isAdReady method called");
        printf("[Flutter Plugin] isAdReady method called\n");
        [self isAdReady:call.arguments result:result];
    } else if ([call.method isEqualToString:@"destroyAd"]) {
        NSLog(@"[Flutter Plugin] destroyAd method called");
        printf("[Flutter Plugin] destroyAd method called\n");
        [self destroyAd:call.arguments result:result];
    } else {
        NSLog(@"[Flutter Plugin] Unknown method: %@", call.method);
        printf("[Flutter Plugin] Unknown method: %s\n", [call.method UTF8String]);
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - SDK Initialization

- (void)initSDK:(NSDictionary *)arguments result:(FlutterResult)result {
    NSString *appKey = arguments[@"appKey"];
    NSString *hashedUserID = arguments[@"hashedUserID"];
    
    if (!appKey) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"appKey is required" 
                                  details:nil]);
        return;
    }
    
    if (hashedUserID) {
        [[CloudXCore shared] initSDKWithAppKey:appKey 
                                  hashedUserID:hashedUserID 
                                    completion:^(BOOL success, NSError * _Nullable error) {
            [self handleInitResult:success error:error result:result];
        }];
    } else {
        [[CloudXCore shared] initSDKWithAppKey:appKey 
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
    NSNumber *width = arguments[@"width"];
    NSNumber *height = arguments[@"height"];
    
    NSLog(@"[Flutter Plugin] createBanner called with placement: %@, adId: %@, width: %@, height: %@", placement, adId, width, height);
    printf("[Flutter Plugin] createBanner called with placement: %s, adId: %s, width: %s, height: %s\n", [placement UTF8String], [adId UTF8String], [[width description] UTF8String], [[height description] UTF8String]);
    
    if (!placement || !adId) {
        NSLog(@"[Flutter Plugin] createBanner ERROR - placement and adId are required");
        printf("[Flutter Plugin] createBanner ERROR - placement and adId are required\n");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"placement and adId are required" 
                                  details:nil]);
        return;
    }
    
    UIViewController *viewController = [self getTopViewController];
    NSLog(@"[Flutter Plugin] createBanner - got viewController: %@", viewController);
    printf("[Flutter Plugin] createBanner - got viewController: %s\n", [[viewController description] UTF8String]);
    
    NSLog(@"[Flutter Plugin] createBanner - About to create banner with delegate: %@", self);
    printf("[Flutter Plugin] createBanner - About to create banner with delegate: %s\n", [[self description] UTF8String]);
    
    // Match the working Objective-C app exactly: createBannerWithPlacement:viewController:delegate:tmax:
    NSLog(@"🔴🔴🔴 [Flutter Plugin] About to create banner with delegate: %@", self);
    printf("🔴🔴🔴 [Flutter Plugin] About to create banner with delegate: %s\n", [[self description] UTF8String]);
    CLXBannerAdView *bannerAd = [[CloudXCore shared] createBannerWithPlacement:placement
                                                                      viewController:viewController
                                                                          delegate:self
                                                                              tmax:nil];
    
    NSLog(@"[Flutter Plugin] createBanner: bannerAd created: %@", bannerAd);
    printf("[Flutter Plugin] createBanner: bannerAd created: %s\n", [[bannerAd description] UTF8String]);
    
    if (bannerAd) {
        NSLog(@"🔴🔴🔴 [Flutter Plugin] createBanner - bannerAd created: %@, class: %@", bannerAd, NSStringFromClass([bannerAd class]));
        printf("🔴🔴🔴 [Flutter Plugin] createBanner - bannerAd created: %s, class: %s\n", [[bannerAd description] UTF8String], [NSStringFromClass([bannerAd class]) UTF8String]);
        NSLog(@"🔴🔴🔴 [Flutter Plugin] createBanner - bannerAd conforms to CLXAd: %@", [bannerAd conformsToProtocol:@protocol(CLXAd)] ? @"YES" : @"NO");
        printf("🔴🔴🔴 [Flutter Plugin] createBanner - bannerAd conforms to CLXAd: %s\n", [bannerAd conformsToProtocol:@protocol(CLXAd)] ? "YES" : "NO");
        
        NSLog(@"[Flutter Plugin] createBanner - Storing banner instance in adInstances for adId: %@", adId);
        printf("[Flutter Plugin] createBanner - Storing banner instance in adInstances for adId: %s\n", [adId UTF8String]);
        
        self.adInstances[adId] = bannerAd;
        [self setAdId:adId forInstance:bannerAd];
        
        // Note: Banner does NOT call load() here - that happens when showing, following the working app pattern
        NSLog(@"[Flutter Plugin] createBanner - Banner created successfully, load() will be called when showing");
        printf("[Flutter Plugin] createBanner - Banner created successfully, load() will be called when showing\n");
        
        NSLog(@"[Flutter Plugin] createBanner - Returning success to Flutter");
        printf("[Flutter Plugin] createBanner - Returning success to Flutter\n");
        result(@YES);
    } else {
        NSLog(@"[Flutter Plugin] createBanner: FAILED to create banner ad");
        printf("[Flutter Plugin] createBanner: FAILED to create banner ad\n");
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
    
    id<CLXInterstitial> interstitialAd = [[CloudXCore shared] createInterstitialWithPlacement:placement
                                                                                        delegate:self];
    
    NSLog(@"[Flutter Plugin] createInterstitial: interstitialAd created: %@", interstitialAd);
    printf("[Flutter Plugin] createInterstitial: interstitialAd created: %s\n", [[interstitialAd description] UTF8String]);
    
    if (interstitialAd) {
        NSLog(@"[Flutter Plugin] createInterstitial - Storing interstitial instance in adInstances for adId: %@", adId);
        printf("[Flutter Plugin] createInterstitial - Storing interstitial instance in adInstances for adId: %s\n", [adId UTF8String]);
        
        self.adInstances[adId] = interstitialAd;
        [self setAdId:adId forInstance:interstitialAd];
        
        // Call load() on the interstitial instance, following the working Objective-C app pattern
        NSLog(@"[Flutter Plugin] createInterstitial - Calling load() on interstitial instance");
        printf("[Flutter Plugin] createInterstitial - Calling load() on interstitial instance\n");
        [interstitialAd load];
        
        NSLog(@"[Flutter Plugin] createInterstitial - Returning success to Flutter");
        printf("[Flutter Plugin] createInterstitial - Returning success to Flutter\n");
        result(@YES);
    } else {
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
    
    id<CLXRewardedInterstitial> rewardedAd = [[CloudXCore shared] createRewardedWithPlacement:placement
                                                                                        delegate:self];
    
    NSLog(@"[Flutter Plugin] createRewarded: rewardedAd created: %@", rewardedAd);
    printf("[Flutter Plugin] createRewarded: rewardedAd created: %s\n", [[rewardedAd description] UTF8String]);
    
    if (rewardedAd) {
        NSLog(@"[Flutter Plugin] createRewarded - Storing rewarded instance in adInstances for adId: %@", adId);
        printf("[Flutter Plugin] createRewarded - Storing rewarded instance in adInstances for adId: %s\n", [adId UTF8String]);
        
        self.adInstances[adId] = rewardedAd;
        [self setAdId:adId forInstance:rewardedAd];
        
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
    
    NSLog(@"🔴🔴🔴 [Flutter Plugin] loadAd START - adId: %@", adId);
    printf("🔴🔴🔴 [Flutter Plugin] loadAd START - adId: %s\n", [adId UTF8String]);
    
    if (!adId) {
        NSLog(@"🔴🔴🔴 [Flutter Plugin] loadAd ERROR - adId is nil");
        printf("🔴🔴🔴 [Flutter Plugin] loadAd ERROR - adId is nil\n");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adId is required" 
                                  details:nil]);
        return;
    }
    
    id adInstance = self.adInstances[adId];
    NSLog(@"🔴🔴🔴 [Flutter Plugin] loadAd - adInstance: %@, class: %@", adInstance, NSStringFromClass([adInstance class]));
    printf("🔴🔴🔴 [Flutter Plugin] loadAd - adInstance: %s, class: %s\n", [[adInstance description] UTF8String], [NSStringFromClass([adInstance class]) UTF8String]);
    
    if (!adInstance) {
        NSLog(@"🔴🔴🔴 [Flutter Plugin] loadAd ERROR - adInstance not found for adId: %@", adId);
        printf("🔴🔴🔴 [Flutter Plugin] loadAd ERROR - adInstance not found for adId: %s\n", [adId UTF8String]);
        result([FlutterError errorWithCode:@"AD_NOT_FOUND" 
                                  message:@"Ad instance not found" 
                                  details:nil]);
        return;
    }
    
    // Store the result to be called when the ad loads
    self.pendingResults[adId] = result;
    NSLog(@"🔴🔴🔴 [Flutter Plugin] loadAd - Stored pending result for adId: %@", adId);
    printf("🔴🔴🔴 [Flutter Plugin] loadAd - Stored pending result for adId: %s\n", [adId UTF8String]);
    
    if ([adInstance conformsToProtocol:@protocol(CLXAd)]) {
        NSLog(@"🔴🔴🔴 [Flutter Plugin] loadAd - adInstance conforms to CLXAd, calling load()");
        printf("🔴🔴🔴 [Flutter Plugin] loadAd - adInstance conforms to CLXAd, calling load()\n");
        [(CLXAd *)adInstance load];
        NSLog(@"🔴🔴🔴 [Flutter Plugin] loadAd - load() called successfully");
        printf("🔴🔴🔴 [Flutter Plugin] loadAd - load() called successfully\n");
    } else {
        NSLog(@"🔴🔴🔴 [Flutter Plugin] loadAd - adInstance does not conform to CLXAd protocol");
        printf("🔴🔴🔴 [Flutter Plugin] loadAd - adInstance does not conform to CLXAd protocol\n");
        result([FlutterError errorWithCode:@"INVALID_AD_TYPE" 
                                  message:@"Ad instance does not support loading" 
                                  details:nil]);
    }
    
    NSLog(@"🔴🔴🔴 [Flutter Plugin] loadAd END");
    printf("🔴🔴🔴 [Flutter Plugin] loadAd END\n");
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
    NSLog(@"[CloudXFlutterSdkPlugin] destroyAd called with adId: %@", adId);
    printf("[CloudXFlutterSdkPlugin] destroyAd called with adId: %s\n", [adId UTF8String]);
    
    if (!adId) {
        result([FlutterError errorWithCode:@"INVALID_ARGUMENTS" 
                                  message:@"adId is required" 
                                  details:nil]);
        return;
    }
    
    id adInstance = self.adInstances[adId];
    if (adInstance) {
        // Clean up internal banner mapping
        if ([adInstance respondsToSelector:@selector(banner)]) {
            id internalBanner = [adInstance performSelector:@selector(banner)];
            if (internalBanner) {
                objc_setAssociatedObject(internalBanner, "adId", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                NSLog(@"🔴 [Flutter Plugin] destroyAd - removed internal banner mapping for adId: %@", adId);
                printf("🔴 [Flutter Plugin] destroyAd - removed internal banner mapping for adId: %s\n", [adId UTF8String]);
            }
        }
        
        if ([adInstance respondsToSelector:@selector(destroy)]) {
            [adInstance destroy];
        }
        // Clean up associated object
        objc_setAssociatedObject(adInstance, "adId", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    return objc_getAssociatedObject(instance, "adId");
}

- (void)setAdId:(NSString *)adId forInstance:(id)instance {
    objc_setAssociatedObject(instance, "adId", adId, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    
    // Find the ad instance that contains this banner
    NSString *adId = nil;
    for (NSString *key in self.adInstances) {
        id instance = self.adInstances[key];
        if ([instance respondsToSelector:@selector(banner)] && [instance performSelector:@selector(banner)] == banner) {
            adId = key;
            break;
        }
    }
    
    if (adId) {
        NSLog(@"🔍 [Flutter Plugin] didLoadBanner - Found adId: %@, sending event to Flutter", adId);
        printf("🔍 [Flutter Plugin] didLoadBanner - Found adId: %s, sending event to Flutter\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"didLoad" adId:adId data:nil];
        
        NSLog(@"🔍 [Flutter Plugin] didLoadBanner - Event sent to Flutter");
        printf("🔍 [Flutter Plugin] didLoadBanner - Event sent to Flutter\n");
    } else {
        NSLog(@"🔍 [Flutter Plugin] didLoadBanner ERROR - could not find adId for banner: %@", banner);
        printf("🔍 [Flutter Plugin] didLoadBanner ERROR - could not find adId for banner: %s\n", [[banner description] UTF8String]);
        NSLog(@"🔍 [Flutter Plugin] didLoadBanner - Current adInstances: %@", self.adInstances);
        NSString *instancesDescription = [self.adInstances description] ?: @"nil";
        printf("🔍 [Flutter Plugin] didLoadBanner - Current adInstances: %s\n", [instancesDescription UTF8String]);
    }
    
    NSLog(@"🔍 [Flutter Plugin] didLoadBanner END");
    printf("🔍 [Flutter Plugin] didLoadBanner END\n");
}

- (void)failToLoadBanner:(id<CLXAdapterBanner>)banner error:(NSError *)error {
    NSLog(@"🔴🔴🔴 [Flutter Plugin] failToLoadBanner called for banner: %@, error: %@", banner, error.localizedDescription);
    printf("🔴🔴🔴 [Flutter Plugin] failToLoadBanner called for banner: %s, error: %s\n", [[banner description] UTF8String], [error.localizedDescription UTF8String]);
    
    // Find the ad instance that contains this banner
    NSString *adId = nil;
    for (NSString *key in self.adInstances) {
        id instance = self.adInstances[key];
        if ([instance respondsToSelector:@selector(banner)] && [instance performSelector:@selector(banner)] == banner) {
            adId = key;
            break;
        }
    }
    
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
    NSLog(@"🔴🔴🔴 [Flutter Plugin] didLoadWithAd called for ad: %@", ad);
    printf("🔴🔴🔴 [Flutter Plugin] didLoadWithAd called for ad: %s\n", [[ad description] UTF8String]);
    NSString *adId = [self getAdIdForInstance:ad];
    NSLog(@"🔍 [Flutter Plugin] didLoadWithAd START - ad: %@, adId: %@", ad, adId);
    printf("🔍 [Flutter Plugin] didLoadWithAd START - ad: %s, adId: %s\n", [[ad description] UTF8String], [adId UTF8String]);
    NSLog(@"🔍 [Flutter Plugin] didLoadWithAd - Ad object class: %@", NSStringFromClass([(NSObject *)ad class]));
    printf("🔍 [Flutter Plugin] didLoadWithAd - Ad object class: %s\n", [NSStringFromClass([(NSObject *)ad class]) UTF8String]);
    NSLog(@"🔍 [Flutter Plugin] didLoadWithAd - Ad object isKindOfClass PublisherBanner: %@", [(NSObject *)ad isKindOfClass:NSClassFromString(@"PublisherBanner")] ? @"YES" : @"NO");
    printf("🔍 [Flutter Plugin] didLoadWithAd - Ad object isKindOfClass PublisherBanner: %s\n", [(NSObject *)ad isKindOfClass:NSClassFromString(@"PublisherBanner")] ? "YES" : "NO");
    NSLog(@"🔍 [Flutter Plugin] didLoadWithAd - Ad object isKindOfClass CloudXBannerAdView: %@", [(NSObject *)ad isKindOfClass:NSClassFromString(@"CloudXBannerAdView")] ? @"YES" : @"NO");
    printf("🔍 [Flutter Plugin] didLoadWithAd - Ad object isKindOfClass CloudXBannerAdView: %s\n", [(NSObject *)ad isKindOfClass:NSClassFromString(@"CloudXBannerAdView")] ? "YES" : "NO");
    
    if (adId) {
        NSLog(@"🔍 [Flutter Plugin] didLoadWithAd - Found adId: %@, sending event to Flutter", adId);
        printf("🔍 [Flutter Plugin] didLoadWithAd - Found adId: %s, sending event to Flutter\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"didLoad" adId:adId data:nil];
        
        NSLog(@"🔍 [Flutter Plugin] didLoadWithAd - Event sent to Flutter");
        printf("🔍 [Flutter Plugin] didLoadWithAd - Event sent to Flutter\n");
    } else {
        NSLog(@"🔍 [Flutter Plugin] didLoadWithAd ERROR - could not find adId for ad: %@", ad);
        printf("🔍 [Flutter Plugin] didLoadWithAd ERROR - could not find adId for ad: %s\n", [[ad description] UTF8String]);
        NSLog(@"🔍 [Flutter Plugin] didLoadWithAd - Current adInstances: %@", self.adInstances);
        NSString *instancesDescription = [self.adInstances description] ?: @"nil";
        printf("🔍 [Flutter Plugin] didLoadWithAd - Current adInstances: %s\n", [instancesDescription UTF8String]);
    }
    
    NSLog(@"🔍 [Flutter Plugin] didLoadWithAd END");
    printf("🔍 [Flutter Plugin] didLoadWithAd END\n");
}

- (void)failToLoadWithAd:(CLXAd *)ad error:(NSError *)error {
    NSLog(@"🔴🔴🔴 [Flutter Plugin] failToLoadWithAd called for ad: %@, error: %@", ad, error.localizedDescription);
    printf("🔴🔴🔴 [Flutter Plugin] failToLoadWithAd called for ad: %s, error: %s\n", [[ad description] UTF8String], [error.localizedDescription UTF8String]);
    NSString *adId = [self getAdIdForInstance:ad];
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] failToLoadWithAd - adId: %@, error: %@", adId, error.localizedDescription);
        printf("🔴 [Flutter Plugin] failToLoadWithAd - adId: %s, error: %s\n", [adId UTF8String], [error.localizedDescription UTF8String]);
        
        NSDictionary *data = @{@"error": error.localizedDescription ?: @"Unknown error"};
        [self sendEventToFlutter:@"failToLoad" adId:adId data:data];
    } else {
        NSLog(@"🔴 [Flutter Plugin] failToLoadWithAd - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] failToLoadWithAd - could not find adId for ad: %s\n", [[ad description] UTF8String]);
    }
}

- (void)didShowWithAd:(CLXAd *)ad {
    NSString *adId = [self getAdIdForInstance:ad];
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
    NSString *adId = [self getAdIdForInstance:ad];
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
    NSString *adId = [self getAdIdForInstance:ad];
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
    NSString *adId = [self getAdIdForInstance:ad];
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
    NSString *adId = [self getAdIdForInstance:ad];
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
    NSString *adId = [self getAdIdForInstance:ad];
    if (adId) {
        NSLog(@"🔴 [Flutter Plugin] closedByUserActionWithAd - adId: %@", adId);
        printf("🔴 [Flutter Plugin] closedByUserActionWithAd - adId: %s\n", [adId UTF8String]);
        
        [self sendEventToFlutter:@"closedByUserAction" adId:adId data:nil];
    } else {
        NSLog(@"🔴 [Flutter Plugin] closedByUserActionWithAd - could not find adId for ad: %@", ad);
        printf("🔴 [Flutter Plugin] closedByUserActionWithAd - could not find adId for ad: %s\n", [[ad description] UTF8String]);
    }
}



#pragma mark - CLXInterstitialDelegate (inherits from BaseAdDelegate, so same methods)

#pragma mark - CLXNativeDelegate (inherits from BaseAdDelegate, so same methods)

#pragma mark - CLXRewardedDelegate (Rewarded-specific methods)

- (void)userRewarded:(CLXAd *)ad {
    NSString *adId = [self getAdIdForInstance:ad];
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
    NSString *adId = [self getAdIdForInstance:ad];
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
    NSString *adId = [self getAdIdForInstance:ad];
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
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    NSLog(@"🔴 [Flutter Plugin] onCancelWithArguments called");
    printf("🔴 [Flutter Plugin] onCancelWithArguments called\n");
    self.eventSink = nil;
    return nil;
}

@end 