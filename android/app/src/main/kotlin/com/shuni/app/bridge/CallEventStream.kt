package com.shuni.app.bridge

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * # CallEventStream
 * 
 * Manages the [EventChannel] stream link back to Flutter, enabling real-time call
 * event broadcasting from native Android code.
 * 
 * ## Thread Safety (For Learning)
 * Flutter engine interactions MUST run on the Main UI Thread.
 * Because call detection events originate on background system threads, we wrap the EventSink
 * call in a `Handler(Looper.getMainLooper()).post(...)` closure to safely push details
 * onto Flutter's main event loop, preventing app crashes.
 */
object CallEventStream : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /**
     * Broadcasts an event map to the active Dart listeners on the Flutter side.
     */
    fun broadcastEvent(eventMap: Map<String, Any?>) {
        mainHandler.post {
            try {
                eventSink?.success(eventMap)
            } catch (e: Exception) {
                // Occurs if the engine is not attached or stream is closed
            }
        }
    }
}
