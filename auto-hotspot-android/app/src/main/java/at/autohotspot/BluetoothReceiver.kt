package at.autohotspot

import android.bluetooth.BluetoothDevice
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BluetoothReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("autohotspot", Context.MODE_PRIVATE)
        val targetAddress = prefs.getString("target_device_address", null) ?: return

        val device: BluetoothDevice? = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }

        if (device?.address != targetAddress) return

        when (intent.action) {
            BluetoothDevice.ACTION_ACL_CONNECTED -> {
                Log.d("AutoHotspot", "Target device connected → enable hotspot")
                context.sendBroadcast(Intent(HotspotAccessibilityService.ACTION_ENABLE_HOTSPOT))
            }
            BluetoothDevice.ACTION_ACL_DISCONNECTED -> {
                Log.d("AutoHotspot", "Target device disconnected → disable hotspot")
                context.sendBroadcast(Intent(HotspotAccessibilityService.ACTION_DISABLE_HOTSPOT))
            }
        }
    }
}
