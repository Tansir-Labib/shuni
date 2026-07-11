package com.shuni.app.detection

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

/**
 * # BootReceiver
 * 
 * Re-registers call listeners after phone reboot.
 * Ensures call recording will work seamlessly without the user needing to manually
 * launch the Shuni app after turning on their phone.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Android automatically registers declared Manifest services (like InCallService)
            // and Receivers. We can log or trigger a light initialization.
            // Under Android 14+ background launch limitations, just receiving this
            // triggers OS verification checks.
            Toast.makeText(context, "Shuni Call Recorder Ready", Toast.LENGTH_SHORT).show()
        }
    }
}
