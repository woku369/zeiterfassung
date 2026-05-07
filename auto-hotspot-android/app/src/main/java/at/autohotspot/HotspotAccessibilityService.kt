package at.autohotspot

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class HotspotAccessibilityService : AccessibilityService() {

    companion object {
        const val ACTION_ENABLE_HOTSPOT = "at.autohotspot.ACTION_ENABLE_HOTSPOT"
        private const val TAG = "AutoHotspot"

        // Tile label fragments in all languages HyperOS might show
        private val HOTSPOT_KEYWORDS = listOf(
            "hotspot", "tethering", "mobiler hotspot", "mobile hotspot",
            "wlan-hotspot", "persönlicher hotspot", "internet sharing"
        )
    }

    private var pendingEnable = false
    private var retryCount = 0
    private val handler = Handler(Looper.getMainLooper())

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_ENABLE_HOTSPOT) {
                Log.d(TAG, "Enable hotspot requested")
                pendingEnable = true
                retryCount = 0
                openQuickSettings()
            }
        }
    }

    override fun onServiceConnected() {
        val flags = if (Build.VERSION.SDK_INT >= 34) RECEIVER_NOT_EXPORTED else 0
        if (Build.VERSION.SDK_INT >= 26) {
            registerReceiver(receiver, IntentFilter(ACTION_ENABLE_HOTSPOT), flags)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(receiver, IntentFilter(ACTION_ENABLE_HOTSPOT))
        }
        Log.d(TAG, "Accessibility service connected")
    }

    private fun openQuickSettings() {
        // GLOBAL_ACTION_QUICK_SETTINGS expands the full quick settings panel directly
        performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)

        // Give the panel time to animate open, then scan
        handler.postDelayed({ scanAndClick() }, 800)
    }

    private fun scanAndClick() {
        if (!pendingEnable) return

        val root = rootInActiveWindow
        if (root != null && findAndClickHotspot(root)) {
            pendingEnable = false
            retryCount = 0
            Log.d(TAG, "Hotspot tile clicked successfully")
            // Close quick settings again
            handler.postDelayed({ performGlobalAction(GLOBAL_ACTION_BACK) }, 500)
            return
        }

        retryCount++
        if (retryCount < 5) {
            Log.d(TAG, "Tile not found yet, retry $retryCount")
            handler.postDelayed({ scanAndClick() }, 600)
        } else {
            Log.w(TAG, "Hotspot tile not found after $retryCount attempts")
            pendingEnable = false
            retryCount = 0
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Passive scan on window changes — catches cases where QS was already open
        if (!pendingEnable) return
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) {
            val root = rootInActiveWindow ?: return
            if (findAndClickHotspot(root)) {
                pendingEnable = false
                retryCount = 0
                handler.removeCallbacksAndMessages(null)
                handler.postDelayed({ performGlobalAction(GLOBAL_ACTION_BACK) }, 500)
            }
        }
    }

    private fun findAndClickHotspot(node: AccessibilityNodeInfo): Boolean {
        val text = node.text?.toString()?.lowercase()?.trim() ?: ""
        val desc = node.contentDescription?.toString()?.lowercase()?.trim() ?: ""

        if (HOTSPOT_KEYWORDS.any { text.contains(it) || desc.contains(it) }) {
            // Walk up to find a clickable ancestor (tile containers are often not the text node)
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

    override fun onInterrupt() {}

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        unregisterReceiver(receiver)
    }
}
