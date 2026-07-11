package com.shuni.app.bridge

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.shuni.app.shizuku.ShizukuBridge
import com.shuni.app.recording.CallRecordingService
import com.shuni.app.recording.RecordingConfig

/**
 * # PlatformBridge
 * 
 * Implements [MethodChannel.MethodCallHandler] to capture Dart requests and execute
 * corresponding native Android actions.
 */
class PlatformBridge(
    private val context: Context,
    private val shizukuBridge: ShizukuBridge
) : MethodChannel.MethodCallHandler {

    private val prefs = context.getSharedPreferences("shuni_prefs", Context.MODE_PRIVATE)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isShizukuReady" -> {
                val isReady = shizukuBridge.checkShizukuPermission()
                result.success(isReady)
            }
            "requestShizukuPermission" -> {
                val success = shizukuBridge.requestPermission()
                result.success(success)
            }
            "getShizukuStatus" -> {
                val statusMap = shizukuBridge.getStatus().toMap()
                result.success(statusMap)
            }
            "startRecording" -> {
                val number = call.argument<String>("phone_number") ?: "Unknown"
                val name = call.argument<String>("contact_name") ?: "Unknown"
                val direction = call.argument<String>("direction") ?: "incoming"
                
                val intent = Intent(context, CallRecordingService::class.java).apply {
                    action = "START_RECORDING"
                    putExtra("phone_number", number)
                    putExtra("contact_name", name)
                    putExtra("direction", direction)
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                result.success(true)
            }
            "stopRecording" -> {
                // To stop, we start service with stop action
                val intent = Intent(context, CallRecordingService::class.java).apply {
                    action = "STOP_RECORDING"
                }
                context.startService(intent)
                result.success(true)
            }
            "getRecordingState" -> {
                // Fallback state query
                result.success("idle")
            }
            "setAutoRecord" -> {
                val enabled = call.argument<Boolean>("enabled") ?: true
                prefs.edit().putBoolean("auto_record", enabled).apply()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
