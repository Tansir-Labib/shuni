package com.shuni.app.recording

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import androidx.core.app.NotificationCompat
import com.shuni.app.bridge.CallEventStream
import com.shuni.app.detection.ContactResolver
import com.shuni.app.recording.AudioRecorder
import java.util.Timer
import java.util.TimerTask
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import android.location.Location
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

/**
 * # CallRecordingService
 * 
 * An Android [Service] running in the foreground to execute call recording tasks.
 * 
 * ## Foreground Service (For Learning)
 * Android aggressively kills background tasks to conserve battery.
 * To keep recording during calls when Shuni is closed, we promote this service to
 * the **Foreground**. This displays a persistent notification, assuring the Android OS
 * that the background audio capturing is user-consented.
 */
class CallRecordingService : Service() {

    private val audioRecorder = AudioRecorder()
    private val serviceScope = CoroutineScope(Dispatchers.IO)
    
    private var number: String = "Unknown"
    private var name: String = "Unknown"
    private var direction: String = "incoming"
    private var isRecordingStarted = false
    
    private var notificationTimer: Timer? = null
    private val NOTIFICATION_ID = 8881
    private val CHANNEL_ID = "shuni_call_recorder"

    override fun onCreate() {
        super.onCreate();
        _createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        val action = intent.action
        number = intent.getStringExtra("phone_number") ?: "Unknown"
        direction = intent.getStringExtra("direction") ?: "incoming"

        // Resolve contact name on a background thread
        serviceScope.launch {
            name = ContactResolver.resolve(applicationContext, number)
            
            if (action == "START_RECORDING" && !isRecordingStarted) {
                _startRecordingAndForeground()
            } else if (action == "STOP_RECORDING") {
                _stopRecordingAndService()
            }
        }

        return START_STICKY
    }

    private fun _startRecordingAndForeground() {
        isRecordingStarted = true

        // 1. Build and show the active recording notification
        val notification = _buildRecordingNotification("0s")
        startForeground(NOTIFICATION_ID, notification)

        // 2. Start audio recording
        val config = RecordingConfig()
        val filename = config.generateFileName(name, direction)
        
        try {
            audioRecorder.start(config, filename)
            
            // Broadcast event back to Flutter
            CallEventStream.broadcastEvent(
                mapOf(
                    "event" to "recording_started",
                    "phone_number" to number,
                    "contact_name" to name,
                    "direction" to direction,
                    "duration_seconds" to 0
                )
            )

            _startNotificationUpdateLoop()
        } catch (e: Exception) {
            _stopRecordingAndService()
        }
    }

    private fun _startNotificationUpdateLoop() {
        notificationTimer?.cancel()
        notificationTimer = Timer()
        notificationTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                if (audioRecorder.isRecordingActive()) {
                    val seconds = (audioRecorder.getElapsedTime() / 1000).toInt()
                    val durationStr = "%dm %ds".format(seconds / 60, seconds % 60)
                    
                    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    manager.notify(NOTIFICATION_ID, _buildRecordingNotification(durationStr))
                }
            }
        }, 1000, 1000)
    }

    private fun _buildRecordingNotification(duration: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Recording call with $name")
            .setContentText("Duration: $duration ($direction)")
            .setSmallIcon(android.R.drawable.presence_video_busy) // Red icon
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun _createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Shuni Call Recorder Service",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Displays ongoing call recording alerts"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun _stopRecordingAndService() {
        notificationTimer?.cancel()
        notificationTimer = null

        val result = audioRecorder.stop()
        
        if (result != null) {
            // Retrieve location coordinates before broadcasting
            _fetchLocationAndBroadcast(result)
        }

        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    /**
     * Fetches current GPS coordinates asynchronously using FusedLocationProvider
     * and broadcasts the call finished metadata to Flutter.
     */
    private fun _fetchLocationAndBroadcast(result: RecordingResult) {
        val fusedLocationClient = LocationServices.getFusedLocationProviderClient(applicationContext)
        
        val hasFine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val hasCoarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED

        if (hasFine || hasCoarse) {
            try {
                fusedLocationClient.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, null)
                    .addOnSuccessListener { location: Location? ->
                        _broadcastEndedEvent(result, location?.latitude, location?.longitude)
                    }
                    .addOnFailureListener {
                        _broadcastEndedEvent(result, null, null)
                    }
            } catch (e: SecurityException) {
                _broadcastEndedEvent(result, null, null)
            }
        } else {
            _broadcastEndedEvent(result, null, null)
        }
    }

    private fun _broadcastEndedEvent(result: RecordingResult, lat: Double?, lng: Double?) {
        CallEventStream.broadcastEvent(
            mapOf(
                "event" to "recording_stopped",
                "phone_number" to number,
                "contact_name" to name,
                "direction" to direction,
                "duration_seconds" to result.durationSeconds,
                "audio_path" to result.filePath,
                "file_size_bytes" to result.fileSizeBytes.toInt(),
                "latitude" to lat,
                "longitude" to lng
            )
        )
    }

    override fun onDestroy() {
        notificationTimer?.cancel()
        audioRecorder.stop()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
