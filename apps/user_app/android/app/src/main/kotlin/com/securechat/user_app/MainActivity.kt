package com.securechat.user_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Push notifications arrive on this channel (sound + heads-up).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("messages", "Messages", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "New 1-to-1 and group messages"
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Secure viewer: block screenshots / screen recording / recent-apps preview (FLAG_SECURE).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "securechat/screen").setMethodCallHandler { call, result ->
            when (call.method) {
                "protect" -> {
                    window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                "unprotect" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
