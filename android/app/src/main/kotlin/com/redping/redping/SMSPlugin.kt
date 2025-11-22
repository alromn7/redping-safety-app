package com.redping.redping

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.telephony.SmsManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine

/**
 * SMS Plugin for RedPing Emergency App
 * Sends SMS automatically without user interaction
 * Requires SEND_SMS permission
 */
class SMSPlugin(private val activity: Activity) {
    companion object {
        private const val CHANNEL = "com.redping.redping/sms"
        private const val TAG = "RedpingSMSPlugin"
        private const val SMS_PERMISSION_REQUEST = 1001
    }

    private var methodChannel: MethodChannel? = null
    private var pendingSMSResult: MethodChannel.Result? = null
    private var pendingSMSData: Pair<String, String>? = null

    fun setupChannels(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSMS" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    
                    if (phoneNumber == null || message == null) {
                        result.error("INVALID_ARGUMENTS", "Phone number and message required", null)
                        return@setMethodCallHandler
                    }
                    
                    sendSMS(phoneNumber, message, result)
                }
                
                "hasSMSPermission" -> {
                    result.success(hasSMSPermission())
                }
                
                "requestSMSPermission" -> {
                    requestSMSPermission(result)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        Log.i(TAG, "SMS Plugin initialized")
    }

    /**
     * Send SMS using Android SmsManager
     */
    private fun sendSMS(phoneNumber: String, message: String, result: MethodChannel.Result) {
        Log.i(TAG, "Attempting to send SMS to $phoneNumber")
        
        // Check permission
        if (!hasSMSPermission()) {
            Log.w(TAG, "SMS permission not granted")
            
            // Store pending request
            pendingSMSResult = result
            pendingSMSData = Pair(phoneNumber, message)
            
            // Request permission
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.SEND_SMS),
                SMS_PERMISSION_REQUEST
            )
            return
        }
        
        try {
            val smsManager = SmsManager.getDefault()
            
            // For long messages, divide into multiple parts
            val parts = smsManager.divideMessage(message)
            
            if (parts.size == 1) {
                // Single SMS
                smsManager.sendTextMessage(
                    phoneNumber,
                    null,
                    message,
                    null,
                    null
                )
                Log.i(TAG, "SMS sent successfully to $phoneNumber")
            } else {
                // Multi-part SMS
                smsManager.sendMultipartTextMessage(
                    phoneNumber,
                    null,
                    parts,
                    null,
                    null
                )
                Log.i(TAG, "Multi-part SMS (${parts.size} parts) sent successfully to $phoneNumber")
            }
            
            result.success(true)
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send SMS: ${e.message}", e)
            result.error("SMS_FAILED", "Failed to send SMS: ${e.message}", null)
        }
    }

    /**
     * Check if SMS permission is granted
     */
    private fun hasSMSPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            activity,
            Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    /**
     * Request SMS permission
     */
    private fun requestSMSPermission(result: MethodChannel.Result) {
        if (hasSMSPermission()) {
            result.success(true)
            return
        }
        
        pendingSMSResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.SEND_SMS),
            SMS_PERMISSION_REQUEST
        )
    }

    /**
     * Handle permission request result
     * Call this from MainActivity.onRequestPermissionsResult
     */
    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == SMS_PERMISSION_REQUEST) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            
            Log.i(TAG, "SMS permission result: $granted")
            
            // Handle pending SMS send if permission was just granted
            if (granted && pendingSMSData != null) {
                val (phoneNumber, message) = pendingSMSData!!
                pendingSMSData = null
                
                val tempResult = pendingSMSResult
                pendingSMSResult = null
                
                if (tempResult != null) {
                    sendSMS(phoneNumber, message, tempResult)
                }
            } else if (pendingSMSResult != null) {
                // Permission denied
                pendingSMSResult?.success(granted)
                pendingSMSResult = null
                pendingSMSData = null
            }
        }
    }
}
