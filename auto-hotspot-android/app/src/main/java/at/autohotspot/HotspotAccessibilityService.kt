package at.autohotspot

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class HotspotAccessibilityService : AccessibilityService() {

    companion object {
        const val ACTION_ENABLE_HOTSPOT = "at.autohotspot.ACTION_ENABLE_HOTSPOT"
        const val ACTION_DISABLE_HOTSPOT = "at.autohotspot.ACTION_DISABLE_HOTSPOT"
        private const val PREF_WE_ENABLED_IT = "we_enabled_hotspot"
    }

    private enum class PendingAction { NONE, ENABLE, DISABLE }

    private var pendingAction = PendingAction.NONE
    private var retryCount = 0
    private val handler = Handler(Looper.getMainLooper())

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                ACTION_ENABLE_HOTSPOT -> {
                    AppLog.add(this@HotspotAccessibilityService, "Trigger empfangen: ENABLE")
                    val hotspotOn = isHotspotEnabled()
                    AppLog.add(this@HotspotAccessibilityService, "Hotspot-Status: ${if (hotspotOn) "AN" else "AUS"}")
                    if (hotspotOn) {
                        AppLog.add(this@HotspotAccessibilityService, "→ Bereits aktiv, nichts zu tun")
                        return
                    }
                    // Try direct reflection first (works on some HyperOS versions)
                    if (startTetheringViaReflection(true)) {
                        val prefs = getSharedPreferences("autohotspot", MODE_PRIVATE)
                        prefs.edit().putBoolean(PREF_WE_ENABLED_IT, true).apply()
                        AppLog.add(this@HotspotAccessibilityService, "✓ Reflection erfolgreich")
                        return
                    }
                    AppLog.add(this@HotspotAccessibilityService, "Reflection nicht verfügbar, nutze QS-Tile")
                    pendingAction = PendingAction.ENABLE
                    retryCount = 0
                    openQuickSettings()
                }
                ACTION_DISABLE_HOTSPOT -> {
                    AppLog.add(this@HotspotAccessibilityService, "Trigger empfangen: DISABLE")
                    val prefs = getSharedPreferences("autohotspot", MODE_PRIVATE)
                    if (!prefs.getBoolean(PREF_WE_ENABLED_IT, false)) {
                        AppLog.add(this@HotspotAccessibilityService, "→ Nicht von uns aktiviert, ignoriere")
                        return
                    }
                    if (!isHotspotEnabled()) {
                        AppLog.add(this@HotspotAccessibilityService, "→ Hotspot bereits aus")
                        prefs.edit().putBoolean(PREF_WE_ENABLED_IT, false).apply()
                        return
                    }
                    if (startTetheringViaReflection(false)) {
                        val prefs2 = getSharedPreferences("autohotspot", MODE_PRIVATE)
                        prefs2.edit().putBoolean(PREF_WE_ENABLED_IT, false).apply()
                        AppLog.add(this@HotspotAccessibilityService, "✓ Reflection stop erfolgreich")
                        return
                    }
                    pendingAction = PendingAction.DISABLE
                    retryCount = 0
                    openQuickSettings()
                }
            }
        }
    }

    override fun onServiceConnected() {
        AppLog.add(this, "Accessibility Service verbunden")
        val filter = IntentFilter().apply {
            addAction(ACTION_ENABLE_HOTSPOT)
            addAction(ACTION_DISABLE_HOTSPOT)
        }
        if (Build.VERSION.SDK_INT >= 26) {
            registerReceiver(receiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(receiver, filter)
        }
    }

    private fun openQuickSettings() {
        AppLog.add(this, "Öffne Quick Settings...")
        performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
        handler.postDelayed({ scanAndClick() }, 800)
    }

    private fun scanAndClick() {
        if (pendingAction == PendingAction.NONE) return

        val root = rootInActiveWindow
        if (root != null) {
            if (findAndClickHotspot(root)) {
                onTileClicked()
                return
            }
        }

        retryCount++
        if (retryCount < 5) {
            AppLog.add(this, "Tile nicht gefunden, Retry $retryCount...")
            handler.postDelayed({ scanAndClick() }, 600)
        } else {
            AppLog.add(this, "FEHLER: Tile nach $retryCount Versuchen nicht gefunden")
            // Log all visible node labels so we know what the tile is actually called
            root?.let {
                val labels = mutableListOf<String>()
                collectNodeLabels(it, labels)
                AppLog.add(this, "Sichtbare Beschriftungen: ${labels.take(30).joinToString(" | ")}")
            }
            pendingAction = PendingAction.NONE
        }
    }

    private fun onTileClicked() {
        val prefs = getSharedPreferences("autohotspot", MODE_PRIVATE)
        when (pendingAction) {
            PendingAction.ENABLE -> {
                prefs.edit().putBoolean(PREF_WE_ENABLED_IT, true).apply()
                AppLog.add(this, "✓ Hotspot aktiviert")
            }
            PendingAction.DISABLE -> {
                prefs.edit().putBoolean(PREF_WE_ENABLED_IT, false).apply()
                AppLog.add(this, "✓ Hotspot deaktiviert")
            }
            PendingAction.NONE -> {}
        }
        pendingAction = PendingAction.NONE
        retryCount = 0
        handler.postDelayed({ performGlobalAction(GLOBAL_ACTION_BACK) }, 500)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (pendingAction == PendingAction.NONE) return
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) {
            val root = rootInActiveWindow ?: return
            if (findAndClickHotspot(root)) {
                handler.removeCallbacksAndMessages(null)
                onTileClicked()
            }
        }
    }

    private fun findAndClickHotspot(root: AccessibilityNodeInfo): Boolean {
        // Use findAccessibilityNodeInfosByText() — same approach as the original Auto Hotspot app.
        // It searches all nodes including content descriptions, much faster than manual traversal.
        val searchTerms = listOf("Hotspot", "hotspot", "Tethering", "tethering")
        for (term in searchTerms) {
            val nodes = root.findAccessibilityNodeInfosByText(term)
            if (!nodes.isNullOrEmpty()) {
                for (node in nodes) {
                    val text = node.text?.toString() ?: ""
                    val desc = node.contentDescription?.toString() ?: ""
                    var target: AccessibilityNodeInfo? = node
                    while (target != null && !target.isClickable) {
                        target = target.parent
                    }
                    if (target?.performAction(AccessibilityNodeInfo.ACTION_CLICK) == true) {
                        AppLog.add(this, "Tile geklickt via '$term' (text='$text' desc='$desc')")
                        return true
                    }
                }
            }
        }
        return false
    }

    private fun collectNodeLabels(node: AccessibilityNodeInfo, labels: MutableList<String>) {
        val text = node.text?.toString()?.trim()
        val desc = node.contentDescription?.toString()?.trim()
        val label = when {
            !text.isNullOrEmpty() -> text
            !desc.isNullOrEmpty() -> desc
            else -> null
        }
        if (label != null) labels.add(label)
        for (i in 0 until node.childCount) {
            node.getChild(i)?.let { collectNodeLabels(it, labels) }
        }
    }

    private fun isHotspotEnabled(): Boolean {
        return try {
            val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
            val method = wifiManager.javaClass.getDeclaredMethod("isWifiApEnabled")
            method.isAccessible = true
            method.invoke(wifiManager) as Boolean
        } catch (e: Exception) {
            AppLog.add(this, "isHotspotEnabled Fehler: ${e.message}")
            false
        }
    }

    private fun startTetheringViaReflection(enable: Boolean): Boolean {
        return try {
            val cm = applicationContext.getSystemService(CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
            if (enable) {
                val method = cm.javaClass.getDeclaredMethod(
                    "startTethering", Int::class.java, Boolean::class.java,
                    Class.forName("android.net.ConnectivityManager\$OnStartTetheringCallback"),
                    android.os.Handler::class.java
                )
                method.isAccessible = true
                method.invoke(cm, 0 /* TETHERING_WIFI */, false, null, null)
                AppLog.add(this, "startTethering via reflection aufgerufen")
            } else {
                val method = cm.javaClass.getDeclaredMethod("stopTethering", Int::class.java)
                method.isAccessible = true
                method.invoke(cm, 0 /* TETHERING_WIFI */)
                AppLog.add(this, "stopTethering via reflection aufgerufen")
            }
            true
        } catch (e: Exception) {
            AppLog.add(this, "Reflection fehlgeschlagen: ${e.javaClass.simpleName}: ${e.message?.take(80)}")
            false
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        AppLog.add(this, "Accessibility Service gestoppt")
        handler.removeCallbacksAndMessages(null)
        unregisterReceiver(receiver)
    }
}
