package at.autohotspot

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.*
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat

class MainActivity : AppCompatActivity() {

    private val btAdapter: BluetoothAdapter? by lazy {
        (getSystemService(BLUETOOTH_SERVICE) as BluetoothManager).adapter
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        requestBtPermissionIfNeeded()
    }

    override fun onResume() {
        super.onResume()
        refreshUI()
    }

    private fun refreshUI() {
        val prefs = getSharedPreferences("autohotspot", MODE_PRIVATE)
        val savedName = prefs.getString("target_device_name", null)
        val accessibilityActive = isAccessibilityServiceEnabled()

        findViewById<TextView>(R.id.tvStatus).text = buildString {
            appendLine("Accessibility Service: ${if (accessibilityActive) "✓ Aktiv" else "✗ Nicht aktiv"}")
            append("Ziel-Gerät: ${savedName ?: "— noch nicht gewählt"}")
        }

        val btnAccessibility = findViewById<Button>(R.id.btnAccessibility)
        btnAccessibility.text = if (accessibilityActive) "Service ist aktiv ✓" else "Accessibility Service aktivieren"
        btnAccessibility.isEnabled = !accessibilityActive
        btnAccessibility.setOnClickListener {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }

        findViewById<Button>(R.id.btnTest).setOnClickListener {
            AppLog.add(this, "--- Manueller Test ---")
            sendBroadcast(Intent(HotspotAccessibilityService.ACTION_ENABLE_HOTSPOT))
            Toast.makeText(this, "Trigger gesendet — Log prüfen", Toast.LENGTH_SHORT).show()
        }

        findViewById<Button>(R.id.btnLog).setOnClickListener {
            showLogDialog()
        }

        loadPairedDevices()
    }

    private fun showLogDialog() {
        val log = AppLog.get(this)
        val scrollView = ScrollView(this)
        val tv = TextView(this).apply {
            text = log
            setPadding(32, 24, 32, 24)
            textSize = 11f
            typeface = android.graphics.Typeface.MONOSPACE
        }
        scrollView.addView(tv)
        // Scroll to bottom to show latest entries
        scrollView.post { scrollView.fullScroll(ScrollView.FOCUS_DOWN) }

        AlertDialog.Builder(this)
            .setTitle("Debug Log")
            .setView(scrollView)
            .setPositiveButton("Schließen", null)
            .setNeutralButton("Löschen") { _, _ ->
                AppLog.clear(this)
                Toast.makeText(this, "Log gelöscht", Toast.LENGTH_SHORT).show()
            }
            .show()
    }

    private fun loadPairedDevices() {
        val permission = if (Build.VERSION.SDK_INT >= 31) {
            Manifest.permission.BLUETOOTH_CONNECT
        } else {
            Manifest.permission.BLUETOOTH
        }
        if (ActivityCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
            return
        }

        val devices = btAdapter?.bondedDevices?.sortedBy { it.name }?.toList() ?: emptyList()
        val prefs = getSharedPreferences("autohotspot", MODE_PRIVATE)
        val savedAddress = prefs.getString("target_device_address", null)

        val names = devices.map { device ->
            val marker = if (device.address == savedAddress) "✓ " else "   "
            "$marker${device.name ?: "Unbekannt"}  (${device.address})"
        }

        val listView = findViewById<ListView>(R.id.lvDevices)
        listView.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, names)
        listView.setOnItemClickListener { _, _, position, _ ->
            val device: BluetoothDevice = devices[position]
            prefs.edit()
                .putString("target_device_address", device.address)
                .putString("target_device_name", device.name ?: device.address)
                .apply()
            AppLog.add(this, "Zielgerät gesetzt: ${device.name} (${device.address})")
            Toast.makeText(this, "Gespeichert: ${device.name}", Toast.LENGTH_SHORT).show()
            refreshUI()
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.contains("${packageName}/${HotspotAccessibilityService::class.java.name}")
    }

    private fun requestBtPermissionIfNeeded() {
        val perms = buildList {
            if (Build.VERSION.SDK_INT >= 31) add(Manifest.permission.BLUETOOTH_CONNECT)
            if (Build.VERSION.SDK_INT >= 33) add(Manifest.permission.POST_NOTIFICATIONS)
        }
        val missing = perms.filter {
            ActivityCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), 1)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        refreshUI()
    }
}
