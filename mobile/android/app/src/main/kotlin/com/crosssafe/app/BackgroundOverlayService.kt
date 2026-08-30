package com.crosssafe.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class BackgroundOverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: android.view.View? = null
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(42, buildNotification())
        showOverlay(intent?.getDoubleExtra("distance", 40.0) ?: 40.0, intent?.getStringExtra("crosswalkName") ?: "Faixa")
        return START_STICKY
    }
    private fun showOverlay(distance: Double, name: String) {
        if (overlayView != null) return
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED,
            PixelFormat.TRANSLUCENT,
        ).apply { gravity = Gravity.CENTER }
        val view = LayoutInflater.from(this).inflate(R.layout.pedestrian_occlusion_layout, null)
        view.findViewById<TextView>(R.id.overlay_title)?.text = "OLHE PARA CIMA"
        view.findViewById<TextView>(R.id.overlay_distance)?.text = "${name.uppercase()} · ${distance.toInt()} m"
        view.findViewById<Button>(R.id.btn_dismiss_hold)?.setOnLongClickListener { stopSelf(); true }
        overlayView = view
        windowManager?.addView(view, params)
    }
    private fun buildNotification(): Notification {
        val channelId = "crosssafe_overlay"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(channelId, "CrossSafe faixa", NotificationManager.IMPORTANCE_HIGH)
            )
        }
        return Notification.Builder(this, channelId)
            .setContentTitle("CrossSafe")
            .setContentText("Faixa a frente. Olhe para cima.")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .build()
    }
    override fun onDestroy() {
        super.onDestroy()
        overlayView?.let { windowManager?.removeView(it) }
        overlayView = null
    }
}
