package io.cloudx.flutter

import android.app.Activity
import android.content.Context
import android.preference.PreferenceManager
import android.util.Log
import android.view.View
import io.cloudx.sdk.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformViewRegistry
import java.lang.ref.WeakReference

/** CloudXFlutterSdkPlugin - Kotlin implementation for Android */
class CloudXFlutterSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var activityRef: WeakReference<Activity>? = null
    private var context: Context? = null
    
    // Storage for ad instances
    private val adInstances = mutableMapOf<String, Any>()
    
    // Storage for pending results (for async operations)
    private val pendingResults = mutableMapOf<String, Result>()

    companion object {
        private const val TAG = "CloudXFlutter"
        private const val METHOD_CHANNEL = "cloudx_flutter_sdk"
        private const val EVENT_CHANNEL = "cloudx_flutter_sdk_events"
        private const val BANNER_VIEW_TYPE = "cloudx_banner_view"
        private const val NATIVE_VIEW_TYPE = "cloudx_native_view"
        private const val MREC_VIEW_TYPE = "cloudx_mrec_view"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
        // Setup method channel
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        
        // Setup event channel
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
        
        // Register platform views for banner/native/MREC ads
        binding.platformViewRegistry.registerViewFactory(
            BANNER_VIEW_TYPE,
            CloudXAdViewFactory(this, AdViewType.BANNER)
        )
        binding.platformViewRegistry.registerViewFactory(
            NATIVE_VIEW_TYPE,
            CloudXAdViewFactory(this, AdViewType.NATIVE)
        )
        binding.platformViewRegistry.registerViewFactory(
            MREC_VIEW_TYPE,
            CloudXAdViewFactory(this, AdViewType.MREC)
        )
        
        Log.d(TAG, "Plugin attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
        Log.d(TAG, "Plugin detached from engine")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityRef = WeakReference(binding.activity)
        Log.d(TAG, "Plugin attached to activity")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityRef = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityRef = WeakReference(binding.activity)
    }

    override fun onDetachedFromActivity() {
        activityRef = null
    }

    // EventChannel.StreamHandler implementation
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Log.d(TAG, "Event stream listener attached")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.d(TAG, "Event stream listener cancelled")
    }

    // MethodCallHandler implementation
    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d(TAG, "Method call: ${call.method}")
        
        when (call.method) {
            // Core SDK Methods
            "initSDK" -> initSDK(call, result)
            "isSDKInitialized" -> result.success(false) // TODO: Track initialization state
            "getSDKVersion" -> result.success("0.0.1") // TODO: Get from SDK
            "getUserID" -> result.success(null) // TODO: Implement user ID getter
            "setUserID" -> {
                val userID = call.argument<String>("userID")
                userID?.let { CloudX.setHashedUserId(it) }
                result.success(true)
            }
            "getLogsData" -> result.success(emptyMap<String, String>())
            "trackSDKError" -> {
                val error = call.argument<String>("error") ?: "Unknown error"
                Log.e(TAG, "SDK Error tracked: $error")
                result.success(true)
            }
            "setEnvironment" -> {
                val environment = call.argument<String>("environment")
                Log.d(TAG, "setEnvironment called with: $environment")
                
                // Map environment string to CloudXInitializationServer
                initializationServer = when (environment?.lowercase()) {
                    "dev", "development" -> CloudXInitializationServer.Development
                    "staging" -> CloudXInitializationServer.Staging
                    "production", "prod" -> CloudXInitializationServer.Production
                    else -> {
                        Log.w(TAG, "Unknown environment: $environment, defaulting to Production")
                        CloudXInitializationServer.Production
                    }
                }
                
                Log.d(TAG, "Environment set to: $initializationServer")
                result.success(true)
            }
            "setLoggingEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                CloudX.setLoggingEnabled(enabled)
                Log.d(TAG, "Logging enabled set to: $enabled")
                result.success(true)
            }
            
            // Privacy & Compliance Methods
            "setCCPAPrivacyString" -> setCCPAPrivacyString(call, result)
            "setIsUserConsent" -> setIsUserConsent(call, result)
            "setIsAgeRestrictedUser" -> setIsAgeRestrictedUser(call, result)
            "setGPPString" -> setGPPString(call, result)
            "getGPPString" -> getGPPString(call, result)
            "setGPPSid" -> setGPPSid(call, result)
            "getGPPSid" -> getGPPSid(call, result)

            // Targeting Methods
            "setUserKeyValue" -> {
                val key = call.argument<String>("key")
                val value = call.argument<String>("value")
                if (key != null && value != null) {
                    CloudX.setUserKeyValue(key, value)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "key and value are required", null)
                }
            }
            "setAppKeyValue" -> {
                val key = call.argument<String>("key")
                val value = call.argument<String>("value")
                if (key != null && value != null) {
                    CloudX.setAppKeyValue(key, value)
                    result.success(true)
                } else {
                    result.error("INVALID_ARGUMENTS", "key and value are required", null)
                }
            }
            "clearAllKeyValues" -> {
                CloudX.clearAllKeyValues()
                result.success(true)
            }
            
            // Ad Creation Methods
            "createBanner" -> createBanner(call, result)
            "createInterstitial" -> createInterstitial(call, result)
            "createRewarded" -> createRewarded(call, result)
            "createNative" -> createNative(call, result)
            "createMREC" -> createMREC(call, result)
            
            // Ad Operation Methods
            "loadAd" -> loadAd(call, result)
            "showAd" -> showAd(call, result)
            "hideAd" -> hideAd(call, result)
            "isAdReady" -> isAdReady(call, result)
            "destroyAd" -> destroyAd(call, result)
            
            else -> result.notImplemented()
        }
    }

    // ============================================================================
    // MARK: - SDK Initialization
    // ============================================================================

    // Store the environment setting to use during initialization
    private var initializationServer: CloudXInitializationServer = CloudXInitializationServer.Production

    private fun initSDK(call: MethodCall, result: Result) {
        val appKey = call.argument<String>("appKey")

        if (appKey == null) {
            result.error("INVALID_ARGUMENTS", "appKey is required", null)
            return
        }

        Log.d(TAG, "Initializing CloudX SDK with appKey: $appKey, server: $initializationServer")

        val initParams = CloudXInitializationParams(
            appKey = appKey,
            initServer = initializationServer
        )
        
        CloudX.initialize(initParams, object : CloudXInitializationListener {
            override fun onInitialized() {
                Log.d(TAG, "CloudX SDK initialized successfully")
                result.success(true)
            }
            
            override fun onInitializationFailed(cloudXError: CloudXError) {
                Log.e(TAG, "CloudX SDK initialization failed: ${cloudXError.effectiveMessage}")
                result.error(
                    "INIT_FAILED",
                    cloudXError.effectiveMessage,
                    cloudXError.code.name
                )
            }
        })
    }

    // ============================================================================
    // MARK: - Privacy & Compliance
    // ============================================================================

    private fun setCCPAPrivacyString(call: MethodCall, result: Result) {
        val ccpaString = call.argument<String>("ccpaString")
        context?.let { ctx ->
            @Suppress("DEPRECATION")
            val prefs = PreferenceManager.getDefaultSharedPreferences(ctx)
            prefs.edit().apply {
                if (ccpaString != null) {
                    putString("IABUSPrivacy_String", ccpaString)
                } else {
                    remove("IABUSPrivacy_String")
                }
                apply()
            }
        }
        result.success(true)
    }

    private fun setIsUserConsent(call: MethodCall, result: Result) {
        val isUserConsent = call.argument<Boolean>("isUserConsent") ?: false
        CloudX.setPrivacy(CloudXPrivacy(isUserConsent = isUserConsent))
        result.success(true)
    }

    private fun setIsAgeRestrictedUser(call: MethodCall, result: Result) {
        val isAgeRestricted = call.argument<Boolean>("isAgeRestrictedUser") ?: false
        CloudX.setPrivacy(CloudXPrivacy(isAgeRestrictedUser = isAgeRestricted))
        result.success(true)
    }

    private fun setGPPString(call: MethodCall, result: Result) {
        val gppString = call.argument<String>("gppString")
        context?.let { ctx ->
            @Suppress("DEPRECATION")
            val prefs = PreferenceManager.getDefaultSharedPreferences(ctx)
            prefs.edit().apply {
                if (gppString != null) {
                    putString("IABGPP_HDR_GppString", gppString)
                } else {
                    remove("IABGPP_HDR_GppString")
                }
                apply()
            }
        }
        result.success(true)
    }

    private fun getGPPString(call: MethodCall, result: Result) {
        context?.let { ctx ->
            @Suppress("DEPRECATION")
            val prefs = PreferenceManager.getDefaultSharedPreferences(ctx)
            val gppString = prefs.getString("IABGPP_HDR_GppString", null)
            result.success(gppString)
        } ?: result.success(null)
    }

    private fun setGPPSid(call: MethodCall, result: Result) {
        val gppSid = call.argument<List<Int>>("gppSid")
        context?.let { ctx ->
            @Suppress("DEPRECATION")
            val prefs = PreferenceManager.getDefaultSharedPreferences(ctx)
            prefs.edit().apply {
                if (gppSid != null) {
                    putString("IABGPP_GppSID", gppSid.joinToString("_"))
                } else {
                    remove("IABGPP_GppSID")
                }
                apply()
            }
        }
        result.success(true)
    }

    private fun getGPPSid(call: MethodCall, result: Result) {
        context?.let { ctx ->
            @Suppress("DEPRECATION")
            val prefs = PreferenceManager.getDefaultSharedPreferences(ctx)
            val gppSidString = prefs.getString("IABGPP_GppSID", null)
            val gppSidList = gppSidString?.split("_")?.mapNotNull { it.toIntOrNull() }
            result.success(gppSidList)
        } ?: result.success(null)
    }

    // ============================================================================
    // MARK: - Ad Creation
    // ============================================================================

    private fun createBanner(call: MethodCall, result: Result) {
        val placement = call.argument<String>("placement")
        val adId = call.argument<String>("adId")
        
        if (placement == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placement and adId are required", null)
            return
        }
        
        try {
            val bannerAd = CloudX.createBanner(placement)
            bannerAd.listener = createAdViewListener(adId)
            adInstances[adId] = bannerAd
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create banner", e)
            result.error("AD_CREATION_FAILED", "Failed to create banner: ${e.message}", null)
        }
    }

    private fun createInterstitial(call: MethodCall, result: Result) {
        val placement = call.argument<String>("placement")
        val adId = call.argument<String>("adId")
        
        if (placement == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placement and adId are required", null)
            return
        }
        
        try {
            val interstitialAd = CloudX.createInterstitial(placement)
            interstitialAd.listener = createInterstitialListener(adId)
            adInstances[adId] = interstitialAd
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create interstitial", e)
            result.error("AD_CREATION_FAILED", "Failed to create interstitial: ${e.message}", null)
        }
    }

    private fun createRewarded(call: MethodCall, result: Result) {
        val placement = call.argument<String>("placement")
        val adId = call.argument<String>("adId")
        
        if (placement == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placement and adId are required", null)
            return
        }
        
        try {
            val rewardedAd = CloudX.createRewardedInterstitial(placement)
            rewardedAd.listener = createRewardedListener(adId)
            adInstances[adId] = rewardedAd
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create rewarded ad", e)
            result.error("AD_CREATION_FAILED", "Failed to create rewarded ad: ${e.message}", null)
        }
    }

    private fun createNative(call: MethodCall, result: Result) {
        val placement = call.argument<String>("placement")
        val adId = call.argument<String>("adId")
        
        if (placement == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placement and adId are required", null)
            return
        }
        
        try {
            val nativeAd = CloudX.createNativeAdSmall(placement)
            nativeAd.listener = createAdViewListener(adId)
            adInstances[adId] = nativeAd
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create native ad", e)
            result.error("AD_CREATION_FAILED", "Failed to create native ad: ${e.message}", null)
        }
    }

    private fun createMREC(call: MethodCall, result: Result) {
        val placement = call.argument<String>("placement")
        val adId = call.argument<String>("adId")
        
        if (placement == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placement and adId are required", null)
            return
        }
        
        try {
            val mrecAd = CloudX.createMREC(placement)
            mrecAd.listener = createAdViewListener(adId)
            adInstances[adId] = mrecAd
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create MREC", e)
            result.error("AD_CREATION_FAILED", "Failed to create MREC: ${e.message}", null)
        }
    }

    // ============================================================================
    // MARK: - Ad Operations
    // ============================================================================

    private fun loadAd(call: MethodCall, result: Result) {
        val adId = call.argument<String>("adId")
        if (adId == null) {
            result.error("INVALID_ARGUMENTS", "adId is required", null)
            return
        }
        
        val adInstance = adInstances[adId]
        if (adInstance == null) {
            result.error("AD_NOT_FOUND", "Ad instance not found", null)
            return
        }
        
        when (adInstance) {
            is CloudXInterstitialAd -> {
                adInstance.load()
                result.success(true)
            }
            is CloudXRewardedInterstitialAd -> {
                adInstance.load()
                result.success(true)
            }
            is CloudXAdView -> {
                // Banner/MREC/Native ads load automatically when added to view
                result.success(true)
            }
            else -> {
                result.error("INVALID_AD_TYPE", "Ad type does not support loading", null)
            }
        }
    }

    private fun showAd(call: MethodCall, result: Result) {
        val adId = call.argument<String>("adId")
        if (adId == null) {
            result.error("INVALID_ARGUMENTS", "adId is required", null)
            return
        }
        
        val adInstance = adInstances[adId]
        if (adInstance == null) {
            result.error("AD_NOT_FOUND", "Ad instance not found", null)
            return
        }
        
        val activity = activityRef?.get()
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }
        
        when (adInstance) {
            is CloudXInterstitialAd -> {
                adInstance.show()
                result.success(true)
            }
            is CloudXRewardedInterstitialAd -> {
                adInstance.show()
                result.success(true)
            }
            is CloudXAdView -> {
                adInstance.visibility = View.VISIBLE
                result.success(true)
            }
            else -> {
                result.error("INVALID_AD_TYPE", "Ad type does not support showing", null)
            }
        }
    }

    private fun hideAd(call: MethodCall, result: Result) {
        val adId = call.argument<String>("adId")
        if (adId == null) {
            result.error("INVALID_ARGUMENTS", "adId is required", null)
            return
        }
        
        val adInstance = adInstances[adId]
        if (adInstance is CloudXAdView) {
            adInstance.visibility = View.GONE
            result.success(true)
        } else {
            result.success(true)
        }
    }

    private fun isAdReady(call: MethodCall, result: Result) {
        val adId = call.argument<String>("adId")
        if (adId == null) {
            result.error("INVALID_ARGUMENTS", "adId is required", null)
            return
        }
        
        val adInstance = adInstances[adId]
        when (adInstance) {
            is CloudXInterstitialAd -> result.success(adInstance.isAdReady)
            is CloudXRewardedInterstitialAd -> result.success(adInstance.isAdReady)
            else -> result.success(false)
        }
    }

    private fun destroyAd(call: MethodCall, result: Result) {
        val adId = call.argument<String>("adId")
        if (adId == null) {
            result.error("INVALID_ARGUMENTS", "adId is required", null)
            return
        }
        
        val adInstance = adInstances[adId]
        when (adInstance) {
            is CloudXInterstitialAd -> adInstance.destroy()
            is CloudXRewardedInterstitialAd -> adInstance.destroy()
            is CloudXAdView -> adInstance.destroy()
        }
        
        adInstances.remove(adId)
        result.success(true)
    }

    // ============================================================================
    // MARK: - Event Helpers
    // ============================================================================

    /**
     * Serialize CloudXAd to Map for Flutter
     */
    private fun serializeCloudXAd(ad: CloudXAd?): Map<String, Any?> {
        if (ad == null) {
            return emptyMap()
        }
        
        return mapOf(
            "placementName" to ad.placementName,
            "placementId" to ad.placementId,
            "bidder" to ad.bidderName,  // Android uses bidderName
            "externalPlacementId" to ad.externalPlacementId,
            "revenue" to ad.revenue
        )
    }

    private fun sendEventToFlutter(eventName: String, adId: String, data: Map<String, Any?>? = null) {
        val eventData = mutableMapOf<String, Any?>()
        eventData["event"] = eventName
        eventData["adId"] = adId
        if (data != null) {
            eventData["data"] = data
        }
        
        activityRef?.get()?.runOnUiThread {
            eventSink?.success(eventData)
        }
    }

    // ============================================================================
    // MARK: - Listener Factories (DRY Pattern)
    // ============================================================================

    private fun createAdViewListener(adId: String): CloudXAdViewListener {
        return object : CloudXAdViewListener {
            override fun onAdLoaded(cloudXAd: CloudXAd) {
                Log.d(TAG, "Ad loaded: $adId")
                sendEventToFlutter("didLoad", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdDisplayed(cloudXAd: CloudXAd) {
                Log.d(TAG, "Ad displayed: $adId")
                sendEventToFlutter("didShow", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdHidden(cloudXAd: CloudXAd) {
                Log.d(TAG, "Ad hidden: $adId")
                sendEventToFlutter("didHide", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdClicked(cloudXAd: CloudXAd) {
                Log.d(TAG, "Ad clicked: $adId")
                sendEventToFlutter("didClick", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdLoadFailed(cloudXError: CloudXError) {
                Log.e(TAG, "Ad load failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToLoad", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onAdDisplayFailed(cloudXError: CloudXError) {
                Log.e(TAG, "Ad display failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToShow", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onAdExpanded(cloudXAd: CloudXAd) {
                Log.d(TAG, "Ad expanded: $adId")
                sendEventToFlutter("didExpandAd", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdCollapsed(cloudXAd: CloudXAd) {
                Log.d(TAG, "Ad collapsed: $adId")
                sendEventToFlutter("didCollapseAd", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
        }
    }

    private fun createInterstitialListener(adId: String): CloudXInterstitialListener {
        return object : CloudXInterstitialListener {
            override fun onAdLoaded(cloudXAd: CloudXAd) {
                Log.d(TAG, "Interstitial loaded: $adId")
                sendEventToFlutter("didLoad", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdDisplayed(cloudXAd: CloudXAd) {
                Log.d(TAG, "Interstitial displayed: $adId")
                sendEventToFlutter("didShow", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdHidden(cloudXAd: CloudXAd) {
                Log.d(TAG, "Interstitial hidden: $adId")
                sendEventToFlutter("didHide", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdClicked(cloudXAd: CloudXAd) {
                Log.d(TAG, "Interstitial clicked: $adId")
                sendEventToFlutter("didClick", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdLoadFailed(cloudXError: CloudXError) {
                Log.e(TAG, "Interstitial load failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToLoad", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onAdDisplayFailed(cloudXError: CloudXError) {
                Log.e(TAG, "Interstitial display failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToShow", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
        }
    }

    private fun createRewardedListener(adId: String): CloudXRewardedInterstitialListener {
        return object : CloudXRewardedInterstitialListener {
            override fun onAdLoaded(cloudXAd: CloudXAd) {
                Log.d(TAG, "Rewarded loaded: $adId")
                sendEventToFlutter("didLoad", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdDisplayed(cloudXAd: CloudXAd) {
                Log.d(TAG, "Rewarded displayed: $adId")
                sendEventToFlutter("didShow", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdHidden(cloudXAd: CloudXAd) {
                Log.d(TAG, "Rewarded hidden: $adId")
                sendEventToFlutter("didHide", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdClicked(cloudXAd: CloudXAd) {
                Log.d(TAG, "Rewarded clicked: $adId")
                sendEventToFlutter("didClick", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdLoadFailed(cloudXError: CloudXError) {
                Log.e(TAG, "Rewarded load failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToLoad", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onAdDisplayFailed(cloudXError: CloudXError) {
                Log.e(TAG, "Rewarded display failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToShow", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onUserRewarded(cloudXAd: CloudXAd) {
                Log.d(TAG, "User rewarded: $adId")
                sendEventToFlutter("userRewarded", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
        }
    }

    // Getter for ad instances (used by PlatformView factories)
    fun getAdInstance(adId: String): Any? = adInstances[adId]
}

