#import "CloudXFlutterSdkPlugin.h"

@implementation CloudXFlutterSdkPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"cloudx_flutter_sdk"
        binaryMessenger:[registrar messenger]];
    CloudXFlutterSdkPlugin* instance = [[CloudXFlutterSdkPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];

    // Register event channel (required by Flutter plugin architecture)
    FlutterEventChannel* eventChannel = [FlutterEventChannel
        eventChannelWithName:@"cloudx_flutter_sdk_events"
        binaryMessenger:[registrar messenger]];
    [eventChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    // CloudX iOS SDK is not yet supported for production use
    // Setters succeed silently, ad operations fail clearly (return false)
    // No exceptions thrown - customers can check return values for failures

    // SDK Initialization - return false (initialization failed)
    if ([call.method isEqualToString:@"initSDK"]) {
        result(@NO);
    }
    // Version - return informative stub message
    else if ([call.method isEqualToString:@"getSDKVersion"]) {
        result(@"iOS not supported");
    }
    // Getter methods - return nil/empty
    else if ([call.method isEqualToString:@"getGPPString"] ||
             [call.method isEqualToString:@"getGPPSid"]) {
        result(nil);
    }
    // Ad operations - return false (operation failed, but no exception)
    else if ([call.method isEqualToString:@"createBanner"] ||
             [call.method isEqualToString:@"createInterstitial"] ||
             [call.method isEqualToString:@"createRewarded"] ||
             [call.method isEqualToString:@"createNative"] ||
             [call.method isEqualToString:@"createMREC"] ||
             [call.method isEqualToString:@"loadAd"] ||
             [call.method isEqualToString:@"showAd"] ||
             [call.method isEqualToString:@"hideAd"] ||
             [call.method isEqualToString:@"isAdReady"] ||
             [call.method isEqualToString:@"destroyAd"] ||
             [call.method isEqualToString:@"startAutoRefresh"] ||
             [call.method isEqualToString:@"stopAutoRefresh"]) {
        result(@NO);
    }
    // Setter methods - return success silently
    else if ([call.method isEqualToString:@"setUserID"] ||
             [call.method isEqualToString:@"setEnvironment"] ||
             [call.method isEqualToString:@"setLoggingEnabled"] ||
             [call.method isEqualToString:@"deinitialize"] ||
             [call.method isEqualToString:@"setCCPAPrivacyString"] ||
             [call.method isEqualToString:@"setIsUserConsent"] ||
             [call.method isEqualToString:@"setIsAgeRestrictedUser"] ||
             [call.method isEqualToString:@"setGPPString"] ||
             [call.method isEqualToString:@"setGPPSid"] ||
             [call.method isEqualToString:@"setUserKeyValue"] ||
             [call.method isEqualToString:@"setAppKeyValue"] ||
             [call.method isEqualToString:@"clearAllKeyValues"]) {
        result(@YES);
    }
    // Unknown method
    else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - FlutterStreamHandler Protocol

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    // No-op for iOS - event stream not supported
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    // No-op for iOS - event stream not supported
    return nil;
}

@end
