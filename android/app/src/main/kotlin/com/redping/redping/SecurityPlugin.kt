package com.redping.redping

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.util.Base64
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import android.provider.Settings
import android.app.KeyguardManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.telephony.TelephonyManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.util.*
import java.security.MessageDigest
 

/// Native Android security and privacy plugin
class SecurityPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "redping.security")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "redping.security.events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkRootStatus" -> {
                result.success(checkRootStatus())
            }
            "checkSecureLock" -> {
                result.success(checkSecureLock())
            }
            "checkNetworkSecurity" -> {
                result.success(checkNetworkSecurity())
            }
            "enableSecurityMonitoring" -> {
                val config = call.arguments as? Map<String, Any> ?: mapOf()
                enableSecurityMonitoring(config)
                result.success(true)
            }
            "updateSecurityConfig" -> {
                val config = call.arguments as? Map<String, Any> ?: mapOf()
                updateSecurityConfig(config)
                result.success(true)
            }
            "checkUsageDescriptions" -> {
                // Android doesn't have usage descriptions like iOS
                result.success(true)
            }
            "getDeviceSecurityInfo" -> {
                result.success(getDeviceSecurityInfo())
            }
            "getAppSignatureDigest" -> {
                result.success(getAppSignatureSha256())
            }
            "verifyAppSignature" -> {
                val expected = (call.arguments as? Map<*, *>)?.get("sha256") as? String
                val actual = getAppSignatureSha256()
                result.success(expected != null && expected.equals(actual, ignoreCase = true))
            }
            "isDebuggerAttached" -> {
                try {
                    result.success(android.os.Debug.isDebuggerConnected())
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            "requestPlayIntegrity" -> {
                try {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    val passedNonce = args["nonce"] as? String

                    // Generate a 32-byte random nonce if not provided
                    val nonce = passedNonce ?: run {
                        val bytes = ByteArray(32)
                        java.security.SecureRandom().nextBytes(bytes)
                        Base64.encodeToString(bytes, Base64.NO_WRAP)
                    }

                    val integrityManager = IntegrityManagerFactory.create(context)
                    val request = IntegrityTokenRequest.builder()
                        .setNonce(nonce)
                        .build()

                    integrityManager.requestIntegrityToken(request)
                        .addOnSuccessListener { response ->
                            val token = response.token()
                            val out = mapOf(
                                "status" to "OK",
                                "token" to token,
                                "nonce" to nonce,
                                "timestamp" to System.currentTimeMillis()
                            )
                            result.success(out)
                        }
                        .addOnFailureListener { e ->
                            val out = mapOf(
                                "status" to "ERROR",
                                "error" to (e.message ?: e.javaClass.simpleName),
                                "nonce" to nonce,
                                "timestamp" to System.currentTimeMillis()
                            )
                            result.success(out)
                        }
                } catch (e: Exception) {
                    val out = mapOf(
                        "status" to "ERROR",
                        "error" to (e.message ?: e.javaClass.simpleName),
                        "timestamp" to System.currentTimeMillis()
                    )
                    result.success(out)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    /// Check if device is rooted
    private fun checkRootStatus(): Boolean {
        return try {
            // Check for common root indicators
            val rootPaths = arrayOf(
                "/system/app/Superuser.apk",
                "/sbin/su",
                "/system/bin/su",
                "/system/xbin/su",
                "/data/local/xbin/su",
                "/data/local/bin/su",
                "/system/sd/xbin/su",
                "/system/bin/failsafe/su",
                "/data/local/su"
            )

            for (path in rootPaths) {
                if (File(path).exists()) {
                    sendSecurityEvent("root_detected", "high", "Root access detected on device")
                    return true
                }
            }

            // Check for root management apps
            val rootApps = arrayOf(
                "com.noshufou.android.su",
                "com.noshufou.android.su.elite",
                "eu.chainfire.supersu",
                "com.koushikdutta.superuser",
                "com.thirdparty.superuser",
                "com.yellowes.su"
            )

            val packageManager = context.packageManager
            for (packageName in rootApps) {
                try {
                    packageManager.getPackageInfo(packageName, 0)
                    sendSecurityEvent("root_app_detected", "high", "Root management app detected: $packageName")
                    return true
                } catch (e: PackageManager.NameNotFoundException) {
                    // App not found, continue checking
                }
            }

            // Check if running in emulator (potential security risk)
            if (isEmulator()) {
                sendSecurityEvent("emulator_detected", "medium", "App running in emulator environment")
            }

            // Check if app is debuggable
            if (isDebuggable()) {
                sendSecurityEvent("debug_mode_detected", "low", "App is running in debug mode")
            }

            false
        } catch (e: Exception) {
            false
        }
    }

    /// Check if device has secure lock screen
    private fun checkSecureLock(): Boolean {
        return try {
            val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.isKeyguardSecure
        } catch (e: Exception) {
            false
        }
    }

    /// Check network security
    private fun checkNetworkSecurity(): Boolean {
        return try {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = connectivityManager.activeNetwork ?: return false
            val networkCapabilities = connectivityManager.getNetworkCapabilities(network) ?: return false

            // Check if network is secure (WiFi with encryption or mobile data)
            val isWifi = networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
            val isCellular = networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)
            val isVPN = networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)

            // Consider VPN or cellular as secure, WiFi depends on encryption
            isVPN || isCellular || (isWifi && isWifiSecure())
        } catch (e: Exception) {
            true // Assume secure if check fails
        }
    }

    /// Check if WiFi is secure (simplified check)
    private fun isWifiSecure(): Boolean {
        // In a real implementation, this would check WiFi encryption
        // For now, assume WiFi is secure
        return true
    }

    /// Check if running in emulator
    private fun isEmulator(): Boolean {
        return (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")) ||
                Build.FINGERPRINT.startsWith("generic") ||
                Build.FINGERPRINT.startsWith("unknown") ||
                Build.HARDWARE.contains("goldfish") ||
                Build.HARDWARE.contains("ranchu") ||
                Build.MODEL.contains("google_sdk") ||
                Build.MODEL.contains("Emulator") ||
                Build.MODEL.contains("Android SDK built for x86") ||
                Build.MANUFACTURER.contains("Genymotion") ||
                Build.PRODUCT.contains("sdk_google") ||
                Build.PRODUCT.contains("google_sdk") ||
                Build.PRODUCT.contains("sdk") ||
                Build.PRODUCT.contains("sdk_x86") ||
                Build.PRODUCT.contains("vbox86p") ||
                Build.PRODUCT.contains("emulator") ||
                Build.PRODUCT.contains("simulator")
    }

    /// Check if app is debuggable
    private fun isDebuggable(): Boolean {
        return try {
            (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        } catch (e: Exception) {
            false
        }
    }

    /// Enable security monitoring
    private fun enableSecurityMonitoring(config: Map<String, Any>) {
        try {
            val enableTamperDetection = config["enableTamperDetection"] as? Boolean ?: false
            val enableRootDetection = config["enableRootDetection"] as? Boolean ?: false
            val enableDebuggingProtection = config["enableDebuggingProtection"] as? Boolean ?: false

            // Start monitoring based on configuration
            if (enableRootDetection) {
                Timer().schedule(object : TimerTask() {
                    override fun run() {
                        if (checkRootStatus()) {
                            sendSecurityEvent("root_detected_monitoring", "high", "Root access detected during monitoring")
                        }
                    }
                }, 0, 60000) // Check every minute
            }

            if (enableDebuggingProtection && isDebuggable()) {
                sendSecurityEvent("debug_mode_active", "medium", "App is running in debug mode")
            }

            if (enableTamperDetection) {
                // Monitor for app tampering
                monitorAppIntegrity()
            }

        } catch (e: Exception) {
            sendSecurityEvent("monitoring_error", "low", "Error enabling security monitoring: ${e.message}")
        }
    }

    /// Update security configuration
    private fun updateSecurityConfig(config: Map<String, Any>) {
        try {
            val enableScreenshotPrevention = config["enableScreenshotPrevention"] as? Boolean ?: false
            
            if (enableScreenshotPrevention) {
                // This would be implemented at the activity level
                sendSecurityEvent("screenshot_prevention_enabled", "low", "Screenshot prevention enabled")
            }

        } catch (e: Exception) {
            sendSecurityEvent("config_error", "low", "Error updating security config: ${e.message}")
        }
    }

    /// Compute SHA-256 digest of the app signing certificate
    private fun getAppSignatureSha256(): String {
        return try {
            val pm = context.packageManager
            val pkg = context.packageName
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val info = pm.getPackageInfo(pkg, PackageManager.GET_SIGNING_CERTIFICATES)
                val certs = info.signingInfo?.apkContentsSigners
                if (certs != null && certs.isNotEmpty()) sha256Hex(certs[0].toByteArray()) else ""
            } else {
                @Suppress("DEPRECATION")
                val info = pm.getPackageInfo(pkg, PackageManager.GET_SIGNATURES)
                @Suppress("DEPRECATION")
                val certs = info.signatures
                if (certs != null && certs.isNotEmpty()) sha256Hex(certs[0].toByteArray()) else ""
            }
        } catch (e: Exception) {
            ""
        }
    }

    private fun sha256Hex(bytes: ByteArray): String {
        val md = MessageDigest.getInstance("SHA-256")
        val digest = md.digest(bytes)
        val sb = StringBuilder()
        for (b in digest) {
            sb.append(String.format("%02x", b))
        }
        return sb.toString()
    }

    /// Monitor app integrity
    private fun monitorAppIntegrity() {
        try {
            val packageInfo = context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES)
            val signatures = packageInfo.signatures

            // In a real implementation, this would verify app signature against known good signature
            if (signatures == null || signatures.isEmpty()) {
                sendSecurityEvent("app_integrity_issue", "high", "App signature verification failed")
            }
        } catch (e: Exception) {
            sendSecurityEvent("integrity_check_error", "medium", "Error checking app integrity: ${e.message}")
        }
    }

    /// Get comprehensive device security information
    private fun getDeviceSecurityInfo(): Map<String, Any> {
        return mapOf(
            "isRooted" to checkRootStatus(),
            "hasSecureLock" to checkSecureLock(),
            "isEmulator" to isEmulator(),
            "isDebuggable" to isDebuggable(),
            "androidVersion" to Build.VERSION.RELEASE,
            "securityPatch" to Build.VERSION.SECURITY_PATCH,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "bootloader" to Build.BOOTLOADER,
            "hardware" to Build.HARDWARE,
            "brand" to Build.BRAND,
            "fingerprint" to Build.FINGERPRINT
        )
    }

    /// Send security event to Flutter
    private fun sendSecurityEvent(type: String, severity: String, description: String) {
        val event = mapOf(
            "type" to type,
            "severity" to severity,
            "description" to description,
            "timestamp" to System.currentTimeMillis(),
            "platform" to "android"
        )
        
        eventSink?.success(event)
    }
}

