package com.example.cloudxFlutterHostApp

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
        
        // Force test mode. Demo apps need this because Flutter builds in release mode by default.
        // Without this: no test:1 → no test ads → confused developers.
        CloudX.setTestMode(true)
        
        // Meta SDK test mode (separate from CloudX test mode)
        enableMetaAudienceNetworkTestMode(true)
        
        super.onCreate(savedInstanceState)
    }
}
