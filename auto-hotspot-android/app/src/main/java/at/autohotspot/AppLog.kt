package at.autohotspot

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object AppLog {
    private val timeFormat = SimpleDateFormat("HH:mm:ss", Locale.getDefault())

    fun add(context: Context, message: String) {
        val prefs = context.getSharedPreferences("autohotspot", Context.MODE_PRIVATE)
        val entry = "${timeFormat.format(Date())}  $message"
        val existing = (prefs.getString("log", "") ?: "").trimEnd()
        val lines = if (existing.isEmpty()) emptyList() else existing.split("\n")
        val updated = (lines + entry).takeLast(200).joinToString("\n")
        prefs.edit().putString("log", updated).apply()
    }

    fun get(context: Context): String {
        val prefs = context.getSharedPreferences("autohotspot", Context.MODE_PRIVATE)
        return prefs.getString("log", "").orEmpty().ifEmpty { "(noch keine Ereignisse)" }
    }

    fun clear(context: Context) {
        context.getSharedPreferences("autohotspot", Context.MODE_PRIVATE)
            .edit().remove("log").apply()
    }
}
