package com.shuni.app.detection

import android.content.Intent
import android.os.Build
import android.telecom.Call
import android.telecom.InCallService
import android.telephony.TelephonyManager
import com.shuni.app.bridge.CallEventStream
import com.shuni.app.recording.CallRecordingService

/**
 * # CallDetectorService
 * 
 * Extends Android's [InCallService] to detect call state changes dynamically on Android 12+.
 * 
 * ## How it works
 * When a call connects (ringing or dialing), the Android Telecom subsystem binds to this service.
 * - `onCallAdded` is called. We attach a state listener.
 * - When call state changes to [Call.STATE_ACTIVE] (call answered), we trigger the recorder.
 * - When call state changes to [Call.STATE_DISCONNECTED] (call ended), we stop the service.
 */
class CallDetectorService : InCallService() {

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            _handleCallState(call, state)
        }
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        call.registerCallback(callCallback)
        _handleCallState(call, call.state)
    }

    override fun onCallRemoved(call: Call) {
        call.unregisterCallback(callCallback)
        _stopRecording()
        super.onCallRemoved(call)
    }

    private fun _handleCallState(call: Call, state: Int) {
        val details = call.details ?: return
        
        // Extract raw number
        var rawNumber = details.handle?.schemeSpecificPart ?: "Unknown"
        if (rawNumber.isEmpty()) {
            rawNumber = "Unknown"
        }

        // Determine direction
        val isIncoming = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            details.callDirection == Call.Details.DIRECTION_INCOMING
        } else {
            // Fallback estimation
            state == Call.STATE_RINGING
        }
        val directionStr = if (isIncoming) "incoming" else "outgoing"

        when (state) {
            Call.STATE_RINGING -> {
                // incoming call ringing
                CallEventStream.broadcastEvent(
                    mapOf(
                        "event" to "ringing",
                        "phone_number" to rawNumber,
                        "contact_name" to ContactResolver.resolve(applicationContext, rawNumber),
                        "direction" to directionStr,
                        "duration_seconds" to 0
                    )
                )
            }
            Call.STATE_ACTIVE -> {
                // call connected / answered, start recording!
                _startRecording(rawNumber, directionStr)
            }
            Call.STATE_DISCONNECTED -> {
                // call ended
                _stopRecording()
            }
        }
    }

    private fun _startRecording(phoneNumber: String, direction: String) {
        val intent = Intent(this, CallRecordingService::class.java).apply {
            action = "START_RECORDING"
            putExtra("phone_number", phoneNumber)
            putExtra("direction", direction)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun _stopRecording() {
        val intent = Intent(this, CallRecordingService::class.java).apply {
            action = "STOP_RECORDING"
        }
        startService(intent)
    }
}
