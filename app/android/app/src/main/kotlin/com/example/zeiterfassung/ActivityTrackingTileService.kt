package com.example.zeiterfassung

import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.N)
class ActivityTrackingTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        updateTile(active = false) // QS Tile zeigt immer "Öffnen" – Tracking läuft in-App
    }

    override fun onClick() {
        super.onClick()
        // Open app with intent to navigate to timeline
        val intent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_OPEN_TIMELINE
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(intent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private fun updateTile(active: Boolean) {
        qsTile?.apply {
            state = if (active) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
            label = "Aktivitäts-Timeline"
            updateTile()
        }
    }

    companion object {
        const val ACTION_OPEN_TIMELINE = "com.example.zeiterfassung.OPEN_TIMELINE"
    }
}
