package io.cloudx.flutter

import android.util.Log

/**
 * Centralized logging utility for CloudX Flutter Plugin.
 *
 * All logging respects the global logging flag set via CloudX.setLoggingEnabled().
 * Logging is disabled by default for production builds.
 */
internal object CloudXLogger {
    @Volatile
    private var isLoggingEnabled = false

    fun setLoggingEnabled(enabled: Boolean) {
        isLoggingEnabled = enabled
    }

    fun isLoggingEnabled(): Boolean {
        return isLoggingEnabled
    }

    /** Debug log */
    fun d(tag: String, message: String) {
        if (isLoggingEnabled) {
            Log.d(tag, message)
        }
    }

    /** Warning log */
    fun w(tag: String, message: String) {
        if (isLoggingEnabled) {
            Log.w(tag, message)
        }
    }

    /** Error log */
    fun e(tag: String, message: String) {
        if (isLoggingEnabled) {
            Log.e(tag, message)
        }
    }

    /** Error log with throwable */
    fun e(tag: String, message: String, throwable: Throwable) {
        if (isLoggingEnabled) {
            Log.e(tag, message, throwable)
        }
    }
}
