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
import android.database.sqlite.SQLiteDatabase
import java.io.File

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

        // IMMEDIATE FOREGROUND PROMOTION
        // Must call this within 5 seconds of startForegroundService or Android will crash the app!
        val initialNotification = _buildRecordingNotification("0s", true)
        startForeground(NOTIFICATION_ID, initialNotification)

        // Resolve contact name on a background thread
        serviceScope.launch {
            name = ContactResolver.resolve(applicationContext, number)
            
            if (action == "START_RECORDING" && !isRecordingStarted) {
                _startRecording()
            } else if (action == "STOP_RECORDING") {
                _stopRecordingAndService()
            }
        }

        return START_STICKY
    }

    private fun _startRecording() {
        isRecordingStarted = true

        // Update the notification with the resolved name
        val notification = _buildRecordingNotification("0s", false)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)

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
                    manager.notify(NOTIFICATION_ID, _buildRecordingNotification(durationStr, false))
                }
            }
        }, 1000, 1000)
    }

    private fun _buildRecordingNotification(duration: String, isInitializing: Boolean): Notification {
        val title = if (isInitializing) "Connecting to call..." else "Recording call: $name"
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText("Duration: $duration ($direction)")
            .setSmallIcon(android.R.drawable.presence_video_busy) // Red icon
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setFullScreenIntent(null, true) // Force Heads-Up display
            .build()
    }

    private fun _createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Shuni Call Recorder Service",
                NotificationManager.IMPORTANCE_HIGH // Changed to HIGH for Heads-up Push Notification
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
        // 1. Save metadata directly to SQLite from Kotlin to avoid losing logs if the Flutter app is dead
        _saveRecordToSQLite(result, lat, lng)

        // 2. Broadcast to Flutter for active UI refresh
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

    private fun _saveRecordToSQLite(result: RecordingResult, lat: Double?, lng: Double?) {
        try {
            val dbFile = File("/storage/emulated/0/Shuni/.shuni_db/shuni.db")
            if (!dbFile.parentFile.exists()) {
                dbFile.parentFile.mkdirs()
            }
            val db = SQLiteDatabase.openOrCreateDatabase(dbFile, null)
            
            // Ensure table exists
            db.execSQL("""
                CREATE TABLE IF NOT EXISTS call_records(
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    phone_number TEXT NOT NULL,
                    contact_name TEXT NOT NULL,
                    date_time_ms INTEGER NOT NULL,
                    duration_seconds INTEGER NOT NULL,
                    direction TEXT NOT NULL,
                    audio_file_path TEXT NOT NULL,
                    file_size_bytes INTEGER NOT NULL,
                    latitude REAL,
                    longitude REAL,
                    address TEXT,
                    is_bookmarked INTEGER DEFAULT 0,
                    notes TEXT,
                    is_voip INTEGER DEFAULT 0
                )
            """)

            val values = android.content.ContentValues().apply {
                put("phone_number", number)
                put("contact_name", name)
                put("date_time_ms", System.currentTimeMillis() - (result.durationSeconds * 1000))
                put("duration_seconds", result.durationSeconds)
                put("direction", direction)
                put("audio_file_path", result.filePath)
                put("file_size_bytes", result.fileSizeBytes)
                if (lat != null) put("latitude", lat)
                if (lng != null) put("longitude", lng)
                put("is_bookmarked", 0)
                put("is_voip", 0)
            }

            db.insert("call_records", null, values)
            db.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        notificationTimer?.cancel()
        audioRecorder.stop()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
