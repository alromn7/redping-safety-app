package com.redping.redping

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class ForegroundServicePlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "redping/foreground_service"
    }

    private var methodChannel: MethodChannel? = null

    fun setupChannels(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "start" -> {
                val title = call.argument<String>("title") ?: "REDP!NG Running"
                val text = call.argument<String>("text") ?: "Monitoring for SOS delivery"
                startService(title, text)
                result.success(true)
            }
            "stop" -> {
                stopService()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun startService(title: String, text: String) {
        val intent = Intent(context, RedpingForegroundService::class.java).apply {
            putExtra("title", title)
            putExtra("text", text)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private fun stopService() {
        val intent = Intent(context, RedpingForegroundService::class.java)
        context.stopService(intent)
    }
}

