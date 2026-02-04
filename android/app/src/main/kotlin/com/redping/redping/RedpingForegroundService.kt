package com.redping.redping

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import android.Manifest
import androidx.core.app.ServiceCompat

class RedpingForegroundService : Service() {

    companion object {
        private const val CHANNEL_ID = "redping_fg"
        private const val CHANNEL_NAME = "REDP!NG Foreground"
        private const val NOTIFICATION_ID = 991001
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra("title") ?: "REDP!NG Running"
        val text = intent?.getStringExtra("text") ?: "Monitoring for SOS delivery"
        val notification = buildNotification(title, text)
        
        // For Android 14+ (API 34+), must specify foreground service type.
        // Use LOCATION type only if location permissions are granted; otherwise fall back to DATA_SYNC only
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val hasFine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED
            val hasCoarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == android.content.pm.PackageManager.PERMISSION_GRANTED
            val hasLocation = hasFine || hasCoarse

            val fgsType = if (hasLocation) {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION or ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            } else {
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            }

            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                fgsType
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        
        return START_STICKY
    }

    private fun buildNotification(title: String, text: String): Notification {
        val notificationIntent = packageManager?.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setColor(Color.parseColor("#E53935"))
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance)
            channel.enableLights(false)
            channel.enableVibration(false)
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}

