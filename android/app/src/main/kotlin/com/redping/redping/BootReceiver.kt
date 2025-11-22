package com.redping.redping

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Boot Receiver - Auto-starts sensor monitoring after device reboot
 * Ensures REDP!NG continues 24/7 monitoring even after restart
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "RedpingBootReceiver"
        // Manufacturer-specific quick boot intent (HTC devices)
        private const val ACTION_QUICKBOOT_POWERON = "android.intent.action.QUICKBOOT_POWERON"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            ACTION_QUICKBOOT_POWERON -> {
                Log.d(TAG, "Device boot completed - starting REDP!NG service")
                
                try {
                    // Start foreground service after boot
                    val serviceIntent = Intent(context, RedpingForegroundService::class.java).apply {
                        putExtra("title", "REDP!NG Safety Active")
                        putExtra("text", "Monitoring restarted after reboot")
                    }
                    
                    // Use startForegroundService for Android 8+
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                    
                    Log.i(TAG, "REDP!NG service restarted successfully after boot")
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to restart REDP!NG service after boot", e)
                }
            }
        }
    }
}
