package io.cloudx.flutter

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
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
import java.util.concurrent.ConcurrentHashMap

/** CloudXFlutterSdkPlugin - Kotlin implementation for Android */
class CloudXFlutterSdkPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    @Volatile private var eventSink: EventChannel.EventSink? = null
    private var activityRef: WeakReference<Activity>? = null
    private var context: Context? = null

    // Storage for ad instances (thread-safe: accessed from platform thread and UI thread)
    private val adInstances = ConcurrentHashMap<String, Any>()

    // Storage for programmatic banner containers (thread-safe: accessed from multiple threads)
    private val programmaticBannerContainers = ConcurrentHashMap<String, FrameLayout>()

    // Storage for pending results (currently unused, but thread-safe for future use)
    private val pendingResults = ConcurrentHashMap<String, Result>()

    // Track privacy state to prevent overwriting when setting individual fields
    private var currentPrivacy = CloudXPrivacy()

    companion object {
        private const val TAG = "CloudXFlutter"
        private const val METHOD_CHANNEL = "cloudx_flutter_sdk"
        private const val EVENT_CHANNEL = "cloudx_flutter_sdk_events"
        private const val BANNER_VIEW_TYPE = "cloudx_banner_view"
        private const val NATIVE_VIEW_TYPE = "cloudx_native_view"
        private const val MREC_VIEW_TYPE = "cloudx_mrec_view"
    }

    // Logging helpers
    private fun logDebug(message: String) = CloudXLogger.d(TAG, message)
    private fun logError(message: String) = CloudXLogger.e(TAG, message)
    private fun logError(message: String, throwable: Throwable) = CloudXLogger.e(TAG, message, throwable)
    private fun logWarning(message: String) = CloudXLogger.w(TAG, message)

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
        
        logDebug( "Plugin attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
        logDebug( "Plugin detached from engine")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityRef = WeakReference(binding.activity)
        logDebug( "Plugin attached to activity")
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
        logDebug("Event stream listener attached")

        // Send ready sentinel to match iOS behavior and prevent 500ms timeout on Flutter side
        events?.success(mapOf(
            "event" to "__eventChannelReady__"
        ))
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        logDebug( "Event stream listener cancelled")
    }

    // MethodCallHandler implementation
    override fun onMethodCall(call: MethodCall, result: Result) {
        logDebug( "Method call: ${call.method}")
        
        when (call.method) {
            // Core SDK Methods
            "initSDK" -> initSDK(call, result)
            "getSDKVersion" -> result.success(io.cloudx.sdk.BuildConfig.SDK_VERSION_NAME)
            "setUserID" -> {
                val userID = call.argument<String>("userID")
                userID?.let { CloudX.setHashedUserId(it) }
                result.success(true)
            }
            "setEnvironment" -> {
                val environment = call.argument<String>("environment")
                logDebug( "setEnvironment called with: $environment")
                
                // Map environment string to CloudXInitializationServer
                initializationServer = when (environment?.lowercase()) {
                    "dev", "development" -> CloudXInitializationServer.Development
                    "staging" -> CloudXInitializationServer.Staging
                    "production", "prod" -> CloudXInitializationServer.Production
                    else -> {
                        logWarning( "Unknown environment: $environment, defaulting to Production")
                        CloudXInitializationServer.Production
                    }
                }
                
                logDebug( "Environment set to: $initializationServer")
                result.success(true)
            }
            "setLoggingEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                // Set logging for both plugin and native SDK
                CloudXLogger.setLoggingEnabled(enabled)
                CloudX.setLoggingEnabled(enabled)
                logDebug("Logging enabled set to: $enabled")
                result.success(true)
            }
            "deinitialize" -> {
                CloudX.deinitialize()
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

            // Auto-refresh Methods
            "startAutoRefresh" -> startAutoRefresh(call, result)
            "stopAutoRefresh" -> stopAutoRefresh(call, result)

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

        logDebug( "Initializing CloudX SDK with appKey: $appKey, server: $initializationServer")

        val initParams = CloudXInitializationParams(
            appKey = appKey,
            initServer = initializationServer
        )
        
        CloudX.initialize(initParams, object : CloudXInitializationListener {
            override fun onInitialized() {
                logDebug( "CloudX SDK initialized successfully")
                result.success(true)
            }

            override fun onInitializationFailed(cloudXError: CloudXError) {
                logError( "CloudX SDK initialization failed: ${cloudXError.effectiveMessage}")
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
            val prefs = ctx.getDefaultSharedPreferences()
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
        // Preserve existing isAgeRestrictedUser value
        currentPrivacy = CloudXPrivacy(
            isUserConsent = isUserConsent,
            isAgeRestrictedUser = currentPrivacy.isAgeRestrictedUser
        )
        CloudX.setPrivacy(currentPrivacy)
        result.success(true)
    }

    private fun setIsAgeRestrictedUser(call: MethodCall, result: Result) {
        val isAgeRestricted = call.argument<Boolean>("isAgeRestrictedUser") ?: false
        // Preserve existing isUserConsent value
        currentPrivacy = CloudXPrivacy(
            isUserConsent = currentPrivacy.isUserConsent,
            isAgeRestrictedUser = isAgeRestricted
        )
        CloudX.setPrivacy(currentPrivacy)
        result.success(true)
    }

    private fun setGPPString(call: MethodCall, result: Result) {
        val gppString = call.argument<String>("gppString")
        context?.let { ctx ->
            val prefs = ctx.getDefaultSharedPreferences()
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
            val prefs = ctx.getDefaultSharedPreferences()
            val gppString = prefs.getString("IABGPP_HDR_GppString", null)
            result.success(gppString)
        } ?: result.success(null)
    }

    private fun setGPPSid(call: MethodCall, result: Result) {
        val gppSid = call.argument<List<Int>>("gppSid")
        context?.let { ctx ->
            val prefs = ctx.getDefaultSharedPreferences()
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
            val prefs = ctx.getDefaultSharedPreferences()
            val gppSidString = prefs.getString("IABGPP_GppSID", null)
            val gppSidList = gppSidString?.split("_")?.mapNotNull { it.toIntOrNull() }
            result.success(gppSidList)
        } ?: result.success(null)
    }

    // ============================================================================
    // MARK: - Ad Creation
    // ============================================================================

    /**
     * Convert position string to Android Gravity flags
     */
    private fun getGravityFromPosition(position: String): Int {
        return when (position) {
            "top_center" -> Gravity.TOP or Gravity.CENTER_HORIZONTAL
            "top_right" -> Gravity.TOP or Gravity.END
            "centered" -> Gravity.CENTER
            "center_left" -> Gravity.CENTER_VERTICAL or Gravity.START
            "center_right" -> Gravity.CENTER_VERTICAL or Gravity.END
            "bottom_left" -> Gravity.BOTTOM or Gravity.START
            "bottom_center" -> Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            "bottom_right" -> Gravity.BOTTOM or Gravity.END
            else -> Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL // Default to bottom center
        }
    }

    /**
     * Creates a programmatic ad view overlay at the specified position.
     * This is shared logic used by both banners and MRECs.
     *
     * @param adView The CloudXAdView instance to position
     * @param position The position string (e.g., "bottom_center")
     * @param adId The unique identifier for this ad
     * @param adType The type of ad (e.g., "banner", "MREC") for logging
     * @param result The Flutter result callback
     */
    private fun createProgrammaticAdView(
        adView: CloudXAdView,
        position: String,
        adId: String,
        adType: String,
        result: Result
    ) {
        val activity = activityRef?.get()
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity not available for programmatic $adType", null)
            return
        }

        logDebug("Creating programmatic $adType at position: $position")

        // Run on UI thread to add view to activity
        activity.runOnUiThread {
            try {
                // Create container layout that will overlay the Flutter view
                // Using FrameLayout because it supports gravity directly
                val containerLayout = FrameLayout(activity)

                // Get gravity for positioning
                val gravity = getGravityFromPosition(position)

                logDebug("Creating programmatic $adType with gravity: $gravity for position: $position")

                // Create layout params with gravity for the ad view
                val adViewLayoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    gravity  // Apply gravity directly to FrameLayout.LayoutParams
                )

                // Remove ad view from any existing parent
                (adView.parent as? ViewGroup)?.removeView(adView)

                // Add ad view to container with gravity-based positioning
                containerLayout.addView(adView, adViewLayoutParams)

                // Set initial visibility to GONE (will be shown with showAd)
                containerLayout.visibility = View.GONE

                // Add container to activity's content view
                activity.addContentView(
                    containerLayout,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    )
                )

                // Store container for show/hide operations
                programmaticBannerContainers[adId] = containerLayout

                logDebug("Successfully created programmatic $adType: $adId at position: $position")
                result.success(true)
            } catch (e: Exception) {
                logError("Failed to create programmatic $adType layout", e)
                result.error("AD_CREATION_FAILED", "Failed to create programmatic $adType: ${e.message}", null)
            }
        }
    }

    private fun createBanner(call: MethodCall, result: Result) {
        val placementName = call.argument<String>("placementName")
        val adId = call.argument<String>("adId")
        val position = call.argument<String>("position")

        if (placementName == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placementName and adId are required", null)
            return
        }

        try {
            val bannerAd = CloudX.createBanner(placementName)
            bannerAd.listener = createAdViewListener(adId)
            adInstances[adId] = bannerAd

            // If position is specified, create programmatic banner overlay
            if (position != null) {
                createProgrammaticAdView(bannerAd, position, adId, "banner", result)
            } else {
                // Widget-based banner (will be embedded via PlatformView)
                logDebug("Created widget-based banner: $adId")
                result.success(true)
            }
        } catch (e: Exception) {
            logError("Failed to create banner", e)
            result.error("AD_CREATION_FAILED", "Failed to create banner: ${e.message}", null)
        }
    }

    private fun createInterstitial(call: MethodCall, result: Result) {
        val placementName = call.argument<String>("placementName")
        val adId = call.argument<String>("adId")
        
        if (placementName == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placementName and adId are required", null)
            return
        }
        
        try {
            val interstitialAd = CloudX.createInterstitial(placementName)
            interstitialAd.listener = createInterstitialListener(adId)
            interstitialAd.revenueListener = createRevenueListener(adId)
            adInstances[adId] = interstitialAd
            result.success(true)
        } catch (e: Exception) {
            logError( "Failed to create interstitial", e)
            result.error("AD_CREATION_FAILED", "Failed to create interstitial: ${e.message}", null)
        }
    }

    private fun createRewarded(call: MethodCall, result: Result) {
        val placementName = call.argument<String>("placementName")
        val adId = call.argument<String>("adId")
        
        if (placementName == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placementName and adId are required", null)
            return
        }
        
        try {
            val rewardedAd = CloudX.createRewardedInterstitial(placementName)
            rewardedAd.listener = createRewardedListener(adId)
            rewardedAd.revenueListener = createRevenueListener(adId)
            adInstances[adId] = rewardedAd
            result.success(true)
        } catch (e: Exception) {
            logError( "Failed to create rewarded ad", e)
            result.error("AD_CREATION_FAILED", "Failed to create rewarded ad: ${e.message}", null)
        }
    }

    private fun createNative(call: MethodCall, result: Result) {
        val placementName = call.argument<String>("placementName")
        val adId = call.argument<String>("adId")
        
        if (placementName == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placementName and adId are required", null)
            return
        }
        
        try {
            val nativeAd = CloudX.createNativeAdSmall(placementName)
            nativeAd.listener = createAdViewListener(adId)
            adInstances[adId] = nativeAd
            result.success(true)
        } catch (e: Exception) {
            logError( "Failed to create native ad", e)
            result.error("AD_CREATION_FAILED", "Failed to create native ad: ${e.message}", null)
        }
    }

    private fun createMREC(call: MethodCall, result: Result) {
        val placementName = call.argument<String>("placementName")
        val adId = call.argument<String>("adId")
        val position = call.argument<String>("position")

        if (placementName == null || adId == null) {
            result.error("INVALID_ARGUMENTS", "placementName and adId are required", null)
            return
        }

        try {
            val mrecAd = CloudX.createMREC(placementName)
            mrecAd.listener = createAdViewListener(adId)
            adInstances[adId] = mrecAd

            // If position is specified, create programmatic MREC overlay
            if (position != null) {
                createProgrammaticAdView(mrecAd, position, adId, "MREC", result)
            } else {
                // Widget-based MREC (will be embedded via PlatformView)
                logDebug("Created widget-based MREC: $adId")
                result.success(true)
            }
        } catch (e: Exception) {
            logError("Failed to create MREC", e)
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
                // Check if this is a programmatic banner with container
                val container = programmaticBannerContainers[adId]
                if (container != null) {
                    // Show programmatic banner container
                    activity.runOnUiThread {
                        container.visibility = View.VISIBLE
                        logDebug("Showing programmatic banner: $adId")
                    }
                } else {
                    // Widget-based banner (visibility controlled by PlatformView)
                    adInstance.visibility = View.VISIBLE
                }
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
            // Check if this is a programmatic banner with container
            val container = programmaticBannerContainers[adId]
            if (container != null) {
                // Hide programmatic banner container
                activityRef?.get()?.runOnUiThread {
                    container.visibility = View.GONE
                    logDebug("Hiding programmatic banner: $adId")
                }
            } else {
                // Widget-based banner
                adInstance.visibility = View.GONE
            }
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
            is CloudXAdView -> {
                adInstance.destroy()

                // Clean up programmatic banner container if exists
                val container = programmaticBannerContainers[adId]
                if (container != null) {
                    activityRef?.get()?.runOnUiThread {
                        // Remove container from activity
                        val parent = container.parent as? ViewGroup
                        parent?.removeView(container)
                        logDebug("Removed programmatic banner container: $adId")
                    }
                    programmaticBannerContainers.remove(adId)
                }
            }
        }

        adInstances.remove(adId)
        result.success(true)
    }

    private fun startAutoRefresh(call: MethodCall, result: Result) {
        val adId = call.argument<String>("adId")
        if (adId == null) {
            result.error("INVALID_ARGUMENTS", "adId is required", null)
            return
        }

        val adInstance = adInstances[adId]
        if (adInstance is CloudXAdView) {
            adInstance.startAutoRefresh()
            result.success(true)
        } else {
            result.error("INVALID_AD_TYPE", "Ad is not a banner/MREC (only CloudXAdView supports auto-refresh)", null)
        }
    }

    private fun stopAutoRefresh(call: MethodCall, result: Result) {
        val adId = call.argument<String>("adId")
        if (adId == null) {
            result.error("INVALID_ARGUMENTS", "adId is required", null)
            return
        }

        val adInstance = adInstances[adId]
        if (adInstance is CloudXAdView) {
            adInstance.stopAutoRefresh()
            result.success(true)
        } else {
            result.error("INVALID_AD_TYPE", "Ad is not a banner/MREC (only CloudXAdView supports auto-refresh)", null)
        }
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

    // Helper to get default SharedPreferences (replaces deprecated PreferenceManager)
    private fun Context.getDefaultSharedPreferences(): SharedPreferences {
        return getSharedPreferences("${packageName}_preferences", Context.MODE_PRIVATE)
    }

    // ============================================================================
    // MARK: - Listener Factories (DRY Pattern)
    // ============================================================================

    private fun createAdViewListener(adId: String): CloudXAdViewListener {
        return object : CloudXAdViewListener {
            override fun onAdLoaded(cloudXAd: CloudXAd) {
                logDebug( "Ad loaded: $adId")
                sendEventToFlutter("didLoad", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdDisplayed(cloudXAd: CloudXAd) {
                logDebug( "Ad displayed: $adId")
                sendEventToFlutter("didShow", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdHidden(cloudXAd: CloudXAd) {
                logDebug( "Ad hidden: $adId")
                sendEventToFlutter("didHide", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdClicked(cloudXAd: CloudXAd) {
                logDebug( "Ad clicked: $adId")
                sendEventToFlutter("didClick", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdLoadFailed(cloudXError: CloudXError) {
                logError( "Ad load failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToLoad", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onAdDisplayFailed(cloudXError: CloudXError) {
                logError( "Ad display failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToShow", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onAdExpanded(cloudXAd: CloudXAd) {
                logDebug( "Ad expanded: $adId")
                sendEventToFlutter("didExpandAd", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdCollapsed(cloudXAd: CloudXAd) {
                logDebug( "Ad collapsed: $adId")
                sendEventToFlutter("didCollapseAd", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
        }
    }

    private fun createInterstitialListener(adId: String): CloudXInterstitialListener {
        return object : CloudXInterstitialListener {
            override fun onAdLoaded(cloudXAd: CloudXAd) {
                logDebug( "Interstitial loaded: $adId")
                sendEventToFlutter("didLoad", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdDisplayed(cloudXAd: CloudXAd) {
                logDebug( "Interstitial displayed: $adId")
                sendEventToFlutter("didShow", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdHidden(cloudXAd: CloudXAd) {
                logDebug( "Interstitial hidden: $adId")
                sendEventToFlutter("didHide", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdClicked(cloudXAd: CloudXAd) {
                logDebug( "Interstitial clicked: $adId")
                sendEventToFlutter("didClick", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdLoadFailed(cloudXError: CloudXError) {
                logError( "Interstitial load failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToLoad", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onAdDisplayFailed(cloudXError: CloudXError) {
                logError( "Interstitial display failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToShow", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
        }
    }

    private fun createRewardedListener(adId: String): CloudXRewardedInterstitialListener {
        return object : CloudXRewardedInterstitialListener {
            override fun onAdLoaded(cloudXAd: CloudXAd) {
                logDebug( "Rewarded loaded: $adId")
                sendEventToFlutter("didLoad", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdDisplayed(cloudXAd: CloudXAd) {
                logDebug( "Rewarded displayed: $adId")
                sendEventToFlutter("didShow", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdHidden(cloudXAd: CloudXAd) {
                logDebug( "Rewarded hidden: $adId")
                sendEventToFlutter("didHide", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdClicked(cloudXAd: CloudXAd) {
                logDebug( "Rewarded clicked: $adId")
                sendEventToFlutter("didClick", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
            
            override fun onAdLoadFailed(cloudXError: CloudXError) {
                logError( "Rewarded load failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToLoad", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onAdDisplayFailed(cloudXError: CloudXError) {
                logError( "Rewarded display failed: $adId - ${cloudXError.effectiveMessage}")
                sendEventToFlutter("failToShow", adId, mapOf("error" to cloudXError.effectiveMessage))
            }
            
            override fun onUserRewarded(cloudXAd: CloudXAd) {
                logDebug( "User rewarded: $adId")
                sendEventToFlutter("userRewarded", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
        }
    }

    private fun createRevenueListener(adId: String): CloudXAdRevenueListener {
        return object : CloudXAdRevenueListener {
            override fun onAdRevenuePaid(cloudXAd: CloudXAd) {
                logDebug( "Revenue paid: $adId")
                sendEventToFlutter("revenuePaid", adId, mapOf("ad" to serializeCloudXAd(cloudXAd)))
            }
        }
    }

    // Getter for ad instances (used by PlatformView factories)
    fun getAdInstance(adId: String): Any? = adInstances[adId]
}

