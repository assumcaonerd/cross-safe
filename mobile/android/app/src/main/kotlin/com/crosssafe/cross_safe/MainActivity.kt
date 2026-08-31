package com.crosssafe.cross_safe

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.crosssafe.app/overlay"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> result.success(Settings.canDrawOverlays(this))
                    "requestPermission" -> {
                        startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName"),
                            ),
                        )
                        result.success(true)
                    }
                    "startOverlay" -> {
                        if (!Settings.canDrawOverlays(this)) {
                            result.error(
                                "PERMISSION_DENIED",
                                "Overlay permission not granted",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        val intent = Intent(this, BackgroundOverlayService::class.java).apply {
                            putExtra(
                                "distance",
                                call.argument<Number>("distance")?.toDouble() ?: 40.0,
                            )
                            putExtra("crosswalkId", call.argument<String>("crosswalkId") ?: "")
                            putExtra(
                                "crosswalkName",
                                call.argument<String>("crosswalkName") ?: "Faixa",
                            )
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "stopOverlay" -> {
                        stopService(Intent(this, BackgroundOverlayService::class.java))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
