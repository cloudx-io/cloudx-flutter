package com.example.cloudx_flutter_demo_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.cloudx.sdk.CloudX
import io.cloudx.sdk.CloudXLogLevel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable verbose logging for CloudX SDK
        CloudX.setLoggingEnabled(true)
        CloudX.setMinLogLevel(CloudXLogLevel.VERBOSE)
        
        super.onCreate(savedInstanceState)
    }
}
