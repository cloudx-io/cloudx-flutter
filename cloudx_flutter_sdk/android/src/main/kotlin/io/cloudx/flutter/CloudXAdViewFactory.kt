package io.cloudx.flutter

import android.content.Context
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import io.cloudx.sdk.CloudXAdView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

enum class AdViewType {
    BANNER,
    NATIVE,
    MREC
}

/** Factory for creating CloudXAdView platform views */
class CloudXAdViewFactory(
    private val plugin: CloudXFlutterSdkPlugin,
    private val adViewType: AdViewType
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    companion object {
        private const val TAG = "CloudXAdViewFactory"
    }
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<*, *>
        val adId = creationParams?.get("adId") as? String
        
        Log.d(TAG, "Creating ${adViewType.name} view for adId: $adId")
        
        return CloudXAdPlatformView(context, plugin, adId, adViewType)
    }
}

/** PlatformView implementation that wraps CloudXAdView */
class CloudXAdPlatformView(
    context: Context,
    private val plugin: CloudXFlutterSdkPlugin,
    private val adId: String?,
    private val adViewType: AdViewType
) : PlatformView {
    
    companion object {
        private const val TAG = "CloudXAdPlatformView"
    }
    
    private val containerView: FrameLayout = FrameLayout(context)
    
    init {
        Log.d(TAG, "Initializing ${adViewType.name} view for adId: $adId")
        
        if (adId != null) {
            val adInstance = plugin.getAdInstance(adId)
            
            if (adInstance is CloudXAdView) {
                Log.d(TAG, "Found CloudXAdView instance for adId: $adId")
                
                // Remove from any existing parent
                (adInstance.parent as? android.view.ViewGroup)?.removeView(adInstance)
                
                // Add to container
                containerView.addView(
                    adInstance,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.WRAP_CONTENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT
                    )
                )
                
                Log.d(TAG, "Successfully added CloudXAdView to container")
            } else {
                Log.e(TAG, "Ad instance not found or wrong type for adId: $adId")
            }
        } else {
            Log.e(TAG, "adId is null")
        }
    }
    
    override fun getView(): View {
        return containerView
    }
    
    override fun dispose() {
        Log.d(TAG, "Disposing ${adViewType.name} view for adId: $adId")
        containerView.removeAllViews()
    }
}


