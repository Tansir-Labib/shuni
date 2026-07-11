package com.shuni.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.shuni.app.bridge.PlatformBridge
import com.shuni.app.bridge.CallEventStream
import com.shuni.app.shizuku.ShizukuBridge

/**
 * # MainActivity
 * 
 * The main Android entry point of the Shuni application.
 * Extends [FlutterActivity] to configure Platform Channels on startup.
 * 
 * ## Core Responsibilities
 * 1. Bootstraps the Flutter Engine and registers Platform Channels.
 * 2. Connects [MethodChannel] calls to the [PlatformBridge].
 * 3. Registers [EventChannel] streams via [CallEventStream] for asynchronous phone event feeds.
 * 4. Manages Shizuku lifecycle binding states.
 */
class MainActivity : FlutterActivity() {
    private lateinit var shizukuBridge: ShizukuBridge
    private lateinit var platformBridge: PlatformBridge

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        shizukuBridge = ShizukuBridge(applicationContext)
        shizukuBridge.bindService() // Connect to Shizuku background binders
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Configure the EventChannel (Android -> Flutter streams)
        val eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.shuni/call_events"
        )
        eventChannel.setStreamHandler(CallEventStream)

        // 2. Configure the MethodChannel (Flutter -> Android calls)
        val methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.shuni/core"
        )
        
        platformBridge = PlatformBridge(applicationContext, shizukuBridge)
        methodChannel.setMethodCallHandler(platformBridge)
    }

    override fun onDestroy() {
        shizukuBridge.unbindService() // Clean up binding links
        super.onDestroy()
    }
}
