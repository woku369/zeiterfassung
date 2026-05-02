package com.example.zeiterfassung

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class UsageStatsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "zeiterfassung/activity")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasUsagePermission" -> result.success(hasUsagePermission())
            "openUsageSettings" -> openUsageSettings(result)
            "queryUsageStats" -> {
                val dateMs = call.argument<Long>("dateMs") ?: System.currentTimeMillis()
                result.success(queryUsageStats(dateMs))
            }
            else -> result.notImplemented()
        }
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("SETTINGS_ERROR", e.message, null)
        }
    }

    private fun queryUsageStats(dayStartMs: Long): List<Map<String, Any>> {
        if (!hasUsagePermission()) return emptyList()
        val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val dayEndMs = dayStartMs + 24 * 60 * 60 * 1000L

        val events = usm.queryEvents(dayStartMs, minOf(dayEndMs, System.currentTimeMillis()))
        val pm = context.packageManager

        // Build sessions from FOREGROUND events
        val sessions = mutableListOf<Map<String, Any>>()
        val activeStart = mutableMapOf<String, Long>() // pkg → foreground start ms

        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            val pkg = event.packageName ?: continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    activeStart[pkg] = event.timeStamp
                }
                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val start = activeStart.remove(pkg) ?: continue
                    val end = event.timeStamp
                    if (end > start) {
                        sessions.add(buildSession(pm, pkg, start, end))
                    }
                }
            }
        }
        // Close any still-open sessions at current time
        val now = System.currentTimeMillis()
        for ((pkg, start) in activeStart) {
            if (now > start) {
                sessions.add(buildSession(pm, pkg, start, now))
            }
        }
        return sessions
    }

    private fun buildSession(
        pm: PackageManager,
        pkg: String,
        startMs: Long,
        endMs: Long
    ): Map<String, Any> {
        val label = try {
            pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
        } catch (_: Exception) {
            pkg
        }
        return mapOf(
            "package" to pkg,
            "label" to label,
            "startMs" to startMs,
            "endMs" to endMs
        )
    }
}
