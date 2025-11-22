package com.redping.redping

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Plugin to get battery temperature from Android BatteryManager
 * Phones detect overheating through battery temperature sensor
 */
class BatteryTemperaturePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.redping.redping/battery_temp")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getBatteryTemperature" -> {
                try {
                    val temperature = getBatteryTemperature()
                    if (temperature != null) {
                        result.success(temperature)
                    } else {
                        result.error("UNAVAILABLE", "Battery temperature not available", null)
                    }
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get battery temperature: ${e.message}", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getBatteryTemperature(): Double? {
        val batteryStatus: Intent? = context.registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )

        return batteryStatus?.let { intent ->
            // Battery temperature is in tenths of a degree Celsius
            val temp = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
            if (temp > 0) {
                temp / 10.0 // Convert to actual Celsius
            } else {
                null
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
