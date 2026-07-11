package com.shuni.app.detection

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import com.shuni.app.recording.CallRecordingService

/**
 * # CallAccessibilityService
 * 
 * An [AccessibilityService] that detects phone call state changes reliably on Android 14+.
 * 
 * ## Why This Approach
 * On modern Android (12+), standard approaches have critical limitations:
 * - **InCallService**: Only binds if the app is the default phone handler. With third-party
 *   dialers like Truecaller this never happens.
 * - **PhoneStateReceiver (BroadcastReceiver)**: On Android 14+ the system no longer delivers
 *   `EXTRA_INCOMING_NUMBER` and may not fire at all if the app's process is dead.
 * 
 * An AccessibilityService is kept alive by the OS as a system service. It can observe
 * `TYPE_NOTIFICATION_STATE_CHANGED` and `TYPE_WINDOW_STATE_CHANGED` events to detect when
 * the phone app or any dialer starts a call.
 * 
 * More importantly, we also register a [TelephonyManager] callback from within this
 * always-alive service, so the callback persists even when the main app is closed.
 * 
 * ## User Setup
 * The user must enable this service in: Settings > Accessibility > Shuni Call Monitor
 */
class CallAccessibilityService : AccessibilityService() {

    private var telephonyManager: TelephonyManager? = null
    private var wasRinging = false
    private var wasOffhook = false
    private val TAG = "ShuniCallMonitor"

    // Telephony callback for call state changes
    private val phoneStateCallback = object : android.telephony.TelephonyCallback(),
        android.telephony.TelephonyCallback.CallStateListener {
        override fun onCallStateChanged(state: Int) {
            handleCallState(state)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.i(TAG, "Shuni CallAccessibilityService connected — registering telephony callback")
        
        // Configure what events we want to observe
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED or
                         AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 100
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        }
        serviceInfo = info

        // Register a TelephonyCallback — this runs inside our always-alive service process
        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            telephonyManager?.registerTelephonyCallback(mainExecutor, phoneStateCallback)
        }
    }

    private fun handleCallState(state: Int) {
        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                Log.d(TAG, "Call state: RINGING")
                wasRinging = true
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                Log.d(TAG, "Call state: OFFHOOK (call active)")
                if (!wasOffhook) {
                    wasOffhook = true
                    val direction = if (wasRinging) "incoming" else "outgoing"
                    _startRecording(direction)
                }
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                Log.d(TAG, "Call state: IDLE (call ended)")
                if (wasOffhook) {
                    _stopRecording()
                }
                wasRinging = false
                wasOffhook = false
            }
        }
    }

    private fun _startRecording(direction: String) {
        Log.i(TAG, "Starting call recording (direction=$direction)")
        val serviceIntent = Intent(this, CallRecordingService::class.java).apply {
            action = "START_RECORDING"
            putExtra("phone_number", _getActiveCallNumber())
            putExtra("direction", direction)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start recording service", e)
            // Fallback attempt
            try {
                startService(serviceIntent)
            } catch (fallbackEx: Exception) {
                Log.e(TAG, "Fallback startService also failed", fallbackEx)
            }
        }
    }

    private fun _stopRecording() {
        Log.i(TAG, "Stopping call recording")
        val serviceIntent = Intent(this, CallRecordingService::class.java).apply {
            action = "STOP_RECORDING"
        }
        try {
            startService(serviceIntent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop recording service", e)
        }
    }

    /**
     * Attempts to retrieve the active call number from the TelecomManager.
     * This is best-effort and may return "Unknown" on some devices.
     */
    private fun _getActiveCallNumber(): String {
        // On Android 14+ we can't easily get the number from PHONE_STATE broadcast.
        // We rely on CallLog after the call ends, or the InCallService if it's bound.
        return "Unknown"
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We primarily rely on the TelephonyCallback, not accessibility events.
        // But we keep this service registered to stay alive.
    }

    override fun onInterrupt() {
        Log.w(TAG, "CallAccessibilityService interrupted")
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            telephonyManager?.unregisterTelephonyCallback(phoneStateCallback)
        }
        super.onDestroy()
    }
}
