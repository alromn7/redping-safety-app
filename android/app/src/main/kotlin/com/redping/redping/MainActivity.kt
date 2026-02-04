package com.redping.redping

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import android.os.Build
import android.util.Log
import android.telephony.TelephonyManager
import java.util.HashMap

class MainActivity : FlutterFragmentActivity() {
    
    private companion object {
        const val BATTERY_CHANNEL = "com.redping.redping/battery"
        const val TAG = "RedpingMainActivity"
    }
    
    private lateinit var satellitePlugin: SatellitePlugin
    private lateinit var securityPlugin: SecurityPlugin
    private lateinit var foregroundServicePlugin: ForegroundServicePlugin
    private lateinit var inCallAudioPlugin: InCallAudioPlugin
    private lateinit var batteryTemperaturePlugin: BatteryTemperaturePlugin
    private lateinit var smsPlugin: SMSPlugin
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize satellite plugin
        satellitePlugin = SatellitePlugin(this)
        satellitePlugin.setupChannels(flutterEngine)
        
        // Initialize security plugin
        securityPlugin = SecurityPlugin()
        flutterEngine.plugins.add(securityPlugin)

        // Initialize foreground service plugin
        foregroundServicePlugin = ForegroundServicePlugin(this)
        foregroundServicePlugin.setupChannels(flutterEngine)
        
        // Initialize in-call audio plugin for emergency AI calls
        inCallAudioPlugin = InCallAudioPlugin(this)
        inCallAudioPlugin.setupChannels(flutterEngine)
        
        // Initialize battery temperature plugin
        batteryTemperaturePlugin = BatteryTemperaturePlugin()
        flutterEngine.plugins.add(batteryTemperaturePlugin)
        
        // Initialize SMS plugin for emergency notifications
        smsPlugin = SMSPlugin(this)
        smsPlugin.setupChannels(flutterEngine)

        // Setup Phone AI channel to deliver intents/transcripts to Dart
        phoneAIChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "phone_ai"
        )
        
        // Setup battery optimization channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestBatteryExemption" -> {
                        val isExempt = requestBatteryExemption()
                        result.success(isExempt)
                    }
                    "checkBatteryExemption" -> {
                        val isExempt = checkBatteryExemption()
                        result.success(isExempt)
                    }
                    "openBatterySettings" -> {
                        openBatterySettings()
                        result.success(null)
                    }
                    "getManufacturer" -> {
                        val manufacturer = Build.MANUFACTURER
                        result.success(manufacturer)
                    }
                    "getCarrierName" -> {
                        try {
                            val telephony = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                            val name = telephony.networkOperatorName ?: telephony.simOperatorName ?: ""
                            result.success(name)
                        } catch (e: Exception) {
                            Log.w(TAG, "Error getting carrier name", e)
                            result.success("")
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    /**
     * Check if battery optimization is disabled for this app
     */
    private fun checkBatteryExemption(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val packageName = packageName
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(packageName)
        } else {
            true // Not needed for Android < 6.0
        }
    }
    
    /**
     * Request battery optimization exemption
     * Opens system settings dialog
     */
    private fun requestBatteryExemption(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val packageName = packageName
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                try {
                    val intent = Intent().apply {
                        action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                    Log.i(TAG, "Opened battery optimization exemption dialog")
                    false // Will become true after user grants
                } catch (e: Exception) {
                    Log.e(TAG, "Error opening battery exemption dialog", e)
                    false
                }
            } else {
                Log.i(TAG, "Battery optimization already disabled")
                true
            }
        } else {
            true // Not needed for Android < 6.0
        }
    }
    
    /**
     * Open battery settings page directly
     */
    private fun openBatterySettings() {
        try {
            val intent = Intent().apply {
                action = Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
            }
            startActivity(intent)
            Log.i(TAG, "Opened battery optimization settings")
        } catch (e: Exception) {
            Log.e(TAG, "Error opening battery settings", e)
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        // Forward to SMS plugin for permission handling
        if (::smsPlugin.isInitialized) {
            smsPlugin.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (::satellitePlugin.isInitialized) {
            satellitePlugin.dispose()
        }
        if (::securityPlugin.isInitialized) {
            // SecurityPlugin doesn't need explicit disposal
        }
        if (::foregroundServicePlugin.isInitialized) {
            // No explicit disposal required
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle voice command deep links (redping://command/*)
        if (intent.action == Intent.ACTION_VIEW && intent.data != null) {
            val uri = intent.data!!
            if (uri.scheme == "redping" && uri.host == "command") {
                val command = uri.pathSegments.firstOrNull() ?: return
                val text = mapCommandToText(command)
                if (text.isNotEmpty() && ::phoneAIChannel.isInitialized) {
                    deliverIncomingIntent(
                        type = "voice_command",
                        text = text,
                        slots = mapOf("command" to command),
                        confidence = 1.0
                    )
                }
            }
        }
    }
    
    private fun mapCommandToText(command: String): String {
        return when (command) {
            "status" -> "check my safety status"
            "sos" -> "start emergency SOS"
            "hazards" -> "check hazard alerts"
            "location" -> "share my location"
            "battery" -> "check battery level"
            else -> ""
        }
    }
    
    // Channel to deliver OS assistant inputs to Dart
    private lateinit var phoneAIChannel: MethodChannel

    // Helpers to forward events to Dart (can be called from other native components)
    fun deliverTranscriptFinal(text: String) {
        try {
            phoneAIChannel.invokeMethod("transcript_final", mapOf("text" to text))
        } catch (e: Exception) {
            Log.e(TAG, "deliverTranscriptFinal error", e)
        }
    }

    fun deliverIncomingIntent(type: String, text: String, slots: Map<String, Any>?, confidence: Double?) {
        try {
            val payload = HashMap<String, Any?>()
            payload["type"] = type
            payload["text"] = text
            payload["slots"] = slots ?: emptyMap<String, Any>()
            payload["confidence"] = confidence ?: 0.0
            phoneAIChannel.invokeMethod("incoming_intent", payload)
        } catch (e: Exception) {
            Log.e(TAG, "deliverIncomingIntent error", e)
        }
    }
}

