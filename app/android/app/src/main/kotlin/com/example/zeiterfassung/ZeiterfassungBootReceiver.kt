package com.example.zeiterfassung

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import id.flutter.flutter_background_service.BackgroundService

/**
 * Startet den Geofencing-Service nach einem Geräteneustart.
 *
 * Ersetzt den built-in BootReceiver von flutter_background_service, damit
 * die Notification-Channels IMMER vor startForeground() existieren –
 * das ist auf Android 8+ Pflicht und auf Android 14 strikt erzwungen.
 *
 * Das Flag "flutter.geofencing_active" wird von GeofencingService.dart
 * gesetzt/gelöscht; so wird der Service nur neu gestartet, wenn er vor
 * dem Neustart tatsächlich aktiv war.
 */
class ZeiterfassungBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON") return

        // War Geofencing aktiv? Flutter-SharedPreferences auslesen.
        val flutterPrefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        val wasActive = flutterPrefs.getBoolean("flutter.geofencing_active", false)
        if (!wasActive) return

        // Channels anlegen (idempotent – kein-op wenn schon vorhanden)
        createChannels(context)

        // Foreground-Service starten
        val serviceIntent = Intent(context, BackgroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    private fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager

        if (nm.getNotificationChannel(FG_CHANNEL_ID) == null) {
            nm.createNotificationChannel(NotificationChannel(
                FG_CHANNEL_ID,
                "Standort-Erkennung (Hintergrund)",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Dauerhafter Hintergrundservice für Standort-Geofencing"
                setSound(null, null)
                enableVibration(false)
            })
        }

        if (nm.getNotificationChannel(EV_CHANNEL_ID) == null) {
            nm.createNotificationChannel(NotificationChannel(
                EV_CHANNEL_ID,
                "Geofence-Ereignisse",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Benachrichtigungen beim Betreten/Verlassen von Standorten"
            })
        }
    }

    companion object {
        const val FG_CHANNEL_ID = "geofence_service"
        const val EV_CHANNEL_ID = "geofence_events"
    }
}
