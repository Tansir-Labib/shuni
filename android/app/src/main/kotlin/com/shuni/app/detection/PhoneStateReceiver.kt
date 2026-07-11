package com.shuni.app.detection

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.TelephonyManager
import com.shuni.app.recording.CallRecordingService

/**
 * # PhoneStateReceiver
 * 
 * A fallback [BroadcastReceiver] listening to system phone status alerts (`PHONE_STATE`).
 * 
 * ## Why a Fallback is Needed
 * On some custom ROMs (or specific configurations of Nothing OS), custom InCallService
 * declarations might not bind consistently. This broadcast receiver acts as a secondary
 * listener. If it detects a call state change to `OFFHOOK` (connected), it starts recording.
 * When `IDLE` (call ended), it stops recording.
 */
class PhoneStateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER) ?: "Unknown"

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                // Incoming ringing
            }
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                // Call connected (active call)
                // Note: Fallback cannot distinguish outgoing from incoming easily
                // without CALL_LOG permissions, so we default to incoming or check intent.
                _startRecording(context, number, "incoming")
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                // Call hung up
                _stopRecording(context)
            }
        }
    }

    private fun _startRecording(context: Context, phoneNumber: String, direction: String) {
        val serviceIntent = Intent(context, CallRecordingService::class.java).apply {
            action = "START_RECORDING"
            putExtra("phone_number", phoneNumber)
            putExtra("direction", direction)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    private fun _stopRecording(context: Context) {
        val serviceIntent = Intent(context, CallRecordingService::class.java).apply {
            action = "STOP_RECORDING"
        }
        context.startService(serviceIntent)
    }
}
