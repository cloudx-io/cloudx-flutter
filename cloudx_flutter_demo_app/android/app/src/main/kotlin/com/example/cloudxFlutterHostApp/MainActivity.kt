package com.example.cloudxFlutterHostApp

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.cloudx.sdk.CloudX
import io.cloudx.sdk.CloudXLogLevel
import io.cloudx.adapter.meta.enableMetaAudienceNetworkTestMode

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable verbose logging for CloudX SDK
        CloudX.setLoggingEnabled(true)
        CloudX.setMinLogLevel(CloudXLogLevel.VERBOSE)
        
        // Enable Meta Audience Network test mode for demo app
        enableMetaAudienceNetworkTestMode(true)
        
        super.onCreate(savedInstanceState)
    }
}
