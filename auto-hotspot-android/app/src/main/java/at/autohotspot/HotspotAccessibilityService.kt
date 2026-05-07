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
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class HotspotAccessibilityService : AccessibilityService() {

    companion object {
        const val ACTION_ENABLE_HOTSPOT = "at.autohotspot.ACTION_ENABLE_HOTSPOT"
        const val ACTION_DISABLE_HOTSPOT = "at.autohotspot.ACTION_DISABLE_HOTSPOT"
        private const val TAG = "AutoHotspot"
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
                    if (isHotspotEnabled()) {
                        Log.d(TAG, "Hotspot already on, nothing to do")
                        return
                    }
                    Log.d(TAG, "Enable requested")
                    pendingAction = PendingAction.ENABLE
                    retryCount = 0
                    openQuickSettings()
                }
                ACTION_DISABLE_HOTSPOT -> {
                    val prefs = getSharedPreferences("autohotspot", MODE_PRIVATE)
                    if (!prefs.getBoolean(PREF_WE_ENABLED_IT, false)) {
                        Log.d(TAG, "We didn't enable it, leaving hotspot alone")
                        return
                    }
                    if (!isHotspotEnabled()) {
                        Log.d(TAG, "Hotspot already off")
                        prefs.edit().putBoolean(PREF_WE_ENABLED_IT, false).apply()
                        return
                    }
                    Log.d(TAG, "Disable requested")
                    pendingAction = PendingAction.DISABLE
                    retryCount = 0
                    openQuickSettings()
                }
            }
        }
    }

    override fun onServiceConnected() {
        val flags = if (Build.VERSION.SDK_INT >= 34) RECEIVER_NOT_EXPORTED else 0
        if (Build.VERSION.SDK_INT >= 26) {
            registerReceiver(receiver, IntentFilter().apply {
                addAction(ACTION_ENABLE_HOTSPOT)
                addAction(ACTION_DISABLE_HOTSPOT)
            }, flags)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(receiver, IntentFilter().apply {
                addAction(ACTION_ENABLE_HOTSPOT)
                addAction(ACTION_DISABLE_HOTSPOT)
            })
        }
        Log.d(TAG, "Accessibility service connected")
    }

    private fun openQuickSettings() {
        performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
        handler.postDelayed({ scanAndClick() }, 800)
    }

    private fun scanAndClick() {
        if (pendingAction == PendingAction.NONE) return

        val root = rootInActiveWindow
        if (root != null && findAndClickHotspot(root)) {
            onTileClicked()
            return
        }

        retryCount++
        if (retryCount < 5) {
            Log.d(TAG, "Tile not found, retry $retryCount")
            handler.postDelayed({ scanAndClick() }, 600)
        } else {
            Log.w(TAG, "Hotspot tile not found after $retryCount retries")
            pendingAction = PendingAction.NONE
        }
    }

    private fun onTileClicked() {
        val prefs = getSharedPreferences("autohotspot", MODE_PRIVATE)
        when (pendingAction) {
            PendingAction.ENABLE -> {
                prefs.edit().putBoolean(PREF_WE_ENABLED_IT, true).apply()
                Log.d(TAG, "Hotspot enabled by us")
            }
            PendingAction.DISABLE -> {
                prefs.edit().putBoolean(PREF_WE_ENABLED_IT, false).apply()
                Log.d(TAG, "Hotspot disabled by us")
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

    private fun findAndClickHotspot(node: AccessibilityNodeInfo): Boolean {
        val text = node.text?.toString()?.lowercase()?.trim() ?: ""
        val desc = node.contentDescription?.toString()?.lowercase()?.trim() ?: ""

        // "Hotspot" is the confirmed label; keep common variants as fallback
        if (text == "hotspot" || desc == "hotspot" ||
            text.contains("hotspot") || desc.contains("hotspot")
        ) {
            var target: AccessibilityNodeInfo? = node
            while (target != null && !target.isClickable) {
                target = target.parent
            }
            if (target?.performAction(AccessibilityNodeInfo.ACTION_CLICK) == true) {
                return true
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (findAndClickHotspot(child)) return true
        }
        return false
    }

    private fun isHotspotEnabled(): Boolean {
        return try {
            val wifiManager = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
            val method = wifiManager.javaClass.getDeclaredMethod("isWifiApEnabled")
            method.isAccessible = true
            method.invoke(wifiManager) as Boolean
        } catch (e: Exception) {
            Log.w(TAG, "Cannot check hotspot state: ${e.message}")
            false
        }
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        unregisterReceiver(receiver)
    }
}
