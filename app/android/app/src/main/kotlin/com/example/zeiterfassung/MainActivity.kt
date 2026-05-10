package com.example.zeiterfassung

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val navChannel = "zeiterfassung/navigation"
    private val btChannel  = "zeiterfassung/bluetooth"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(UsageStatsPlugin())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, btChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getPairedDevices") {
                    result.success(getPairedDevices())
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun getPairedDevices(): List<Map<String, String>> {
        return try {
            val adapter: BluetoothAdapter? =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    (getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
                } else {
                    @Suppress("DEPRECATION")
                    BluetoothAdapter.getDefaultAdapter()
                }
            adapter?.bondedDevices?.map { device ->
                mapOf("name" to (device.name ?: "Unbekannt"), "address" to device.address)
            } ?: emptyList()
        } catch (_: SecurityException) {
            emptyList()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == ActivityTrackingTileService.ACTION_OPEN_TIMELINE) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, navChannel).invokeMethod("openTimeline", null)
            }
        }
    }
}
