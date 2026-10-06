package com.example.zeiterfassung

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log
import id.flutter.flutter_background_service.BackgroundService

/**
 * Periodische Wiederbelebung des Geofencing-Services.
 *
 * HyperOS (und andere aggressive OEMs) killen Foreground-Services irgendwann
 * stillschweigend, selbst wenn in den Akkueinstellungen „Keine Einschränkungen"
 * gesetzt ist. Der BootReceiver startet den Dienst erst beim nächsten
 * Geräteneustart neu. Dieser Watchdog schiebt dazwischen alle ~15 Minuten
 * einen `startForegroundService()`-Aufruf nach: läuft der Dienst, ist der Call
 * ein No-Op. Läuft er nicht mehr, wird er lautlos wiederbelebt — ohne dass
 * der Nutzer die App öffnen muss.
 *
 * `setAndAllowWhileIdle` überlebt Doze (vs. `setInexactRepeating`), die
 * Reschedule-Logik in `onReceive` sorgt für den periodischen Lauf.
 */
class ZeiterfassungWatchdogReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )
        val wasActive = prefs.getBoolean("flutter.geofencing_active", false)
        if (!wasActive) {
            Log.i(TAG, "Watchdog: geofencing_active=false, kein Restart")
            return
        }

        // Service (re)starten — idempotent wenn er schon läuft.
        try {
            val svcIntent = Intent(context, BackgroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(svcIntent)
            } else {
                context.startService(svcIntent)
            }
            Log.i(TAG, "Watchdog: startForegroundService() ausgelöst")
        } catch (t: Throwable) {
            Log.w(TAG, "Watchdog: Service-Start fehlgeschlagen", t)
        }

        // Nächsten Alarm scharfschalten
        schedule(context)
    }

    companion object {
        private const val TAG = "ZE-Watchdog"
        private const val REQUEST_CODE = 4711
        private const val INTERVAL_MS = 15L * 60L * 1000L

        private fun pendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, ZeiterfassungWatchdogReceiver::class.java)
            return PendingIntent.getBroadcast(
                context, REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        /** Nächsten Watchdog-Tick in ~15 min einplanen. */
        fun schedule(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val trigger = SystemClock.elapsedRealtime() + INTERVAL_MS
            val pi = pendingIntent(context)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    am.setAndAllowWhileIdle(
                        AlarmManager.ELAPSED_REALTIME_WAKEUP, trigger, pi
                    )
                } else {
                    am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, trigger, pi)
                }
                Log.i(TAG, "Watchdog: nächster Tick in 15 min")
            } catch (t: Throwable) {
                Log.w(TAG, "Watchdog: Alarm-Scheduling fehlgeschlagen", t)
            }
        }

        /** Watchdog deaktivieren (vom Nutzer explizit gestoppt). */
        fun cancel(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(pendingIntent(context))
            Log.i(TAG, "Watchdog: Alarm abgebrochen")
        }
    }
}
