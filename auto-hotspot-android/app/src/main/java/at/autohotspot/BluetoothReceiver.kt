package at.autohotspot

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BluetoothReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != BluetoothDevice.ACTION_ACL_CONNECTED) return

        val prefs = context.getSharedPreferences("autohotspot", Context.MODE_PRIVATE)
        val targetAddress = prefs.getString("target_device_address", null) ?: return

        val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }

        if (device?.address == targetAddress) {
            Log.d("AutoHotspot", "Target device connected: ${device.address}")
            val trigger = Intent(HotspotAccessibilityService.ACTION_ENABLE_HOTSPOT)
            context.sendBroadcast(trigger)
        }
    }
}
