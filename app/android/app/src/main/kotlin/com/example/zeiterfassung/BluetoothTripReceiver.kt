package com.example.zeiterfassung

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Lauscht auf Bluetooth ACL-Connect/Disconnect-Events und schreibt
 * das Ergebnis in FlutterSharedPreferences, wo der Dart-Hintergrunddienst
 * es beim nächsten GPS-Tick ausliest.
 *
 * Registriert im AndroidManifest für:
 *   ACTION_ACL_CONNECTED / ACTION_ACL_DISCONNECTED
 */
class BluetoothTripReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val device: BluetoothDevice? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
                intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
            else
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)

        val address = device?.address ?: return

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        // Read the user-selected BT device addresses (JSON array stored by Dart)
        val watchlistJson = prefs.getString("flutter.$BT_WATCHLIST_KEY", "[]") ?: "[]"
        if (!watchlistJson.contains(address)) return   // not a watched device

        when (action) {
            BluetoothDevice.ACTION_ACL_CONNECTED -> {
                prefs.edit()
                    .putString("flutter.$BT_EVENT_KEY", "connect:$address")
                    .apply()
            }
            BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                prefs.edit()
                    .putString("flutter.$BT_EVENT_KEY", "disconnect:$address")
                    .apply()
            }
        }
    }

    companion object {
        const val BT_WATCHLIST_KEY = "bt_trip_devices"   // JSON array of MAC addresses
        const val BT_EVENT_KEY     = "bt_trip_event"     // "connect:<mac>" | "disconnect:<mac>"
    }
}
