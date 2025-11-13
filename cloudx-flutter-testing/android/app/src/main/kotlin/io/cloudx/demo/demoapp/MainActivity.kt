package io.cloudx.demo.demoapp

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.cloudx.sdk.CloudX
import io.cloudx.sdk.CloudXLogLevel
import io.cloudx.adapter.meta.enableMetaAudienceNetworkTestMode

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Verbose logging for SDK debugging
        CloudX.setLoggingEnabled(true)
        CloudX.setMinLogLevel(CloudXLogLevel.VERBOSE)

        // Meta SDK test mode (separate from CloudX test mode)
        enableMetaAudienceNetworkTestMode(true)
        
        super.onCreate(savedInstanceState)
    }
}
