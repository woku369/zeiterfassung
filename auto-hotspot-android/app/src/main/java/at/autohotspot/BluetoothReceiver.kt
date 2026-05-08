package at.autohotspot

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BluetoothReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("autohotspot", Context.MODE_PRIVATE)
        val targetAddress = prefs.getString("target_device_address", null)

        val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }

        val deviceAddress = try { device?.address } catch (_: SecurityException) { "??" }
        val deviceName = try { device?.name ?: deviceAddress } catch (_: SecurityException) { deviceAddress }

        when (intent.action) {
            BluetoothDevice.ACTION_ACL_CONNECTED -> {
                AppLog.add(context, "BT verbunden: $deviceName ($deviceAddress)")
                if (targetAddress == null) {
                    AppLog.add(context, "→ Kein Zielgerät konfiguriert — App öffnen und Gerät wählen")
                    return
                }
                if (deviceAddress != targetAddress) {
                    AppLog.add(context, "→ Nicht das Zielgerät (erwartet: $targetAddress)")
                    return
                }
                AppLog.add(context, "→ Zielgerät erkannt! Sende Hotspot-Trigger...")
                context.sendBroadcast(Intent(HotspotAccessibilityService.ACTION_ENABLE_HOTSPOT))
            }
            BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                AppLog.add(context, "BT getrennt: $deviceName ($deviceAddress)")
                if (deviceAddress != targetAddress) return
                AppLog.add(context, "→ Zielgerät getrennt, sende Deaktivierungs-Trigger...")
                context.sendBroadcast(Intent(HotspotAccessibilityService.ACTION_DISABLE_HOTSPOT))
            }
        }
    }
}
