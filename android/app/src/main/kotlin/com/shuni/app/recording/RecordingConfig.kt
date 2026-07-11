package com.shuni.app.recording

import android.media.MediaRecorder
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * # RecordingConfig
 * 
 * Configuration parameters for the recording engine.
 * 
 * ## Bitrate & Quality Target
 * - Bitrate: 32000 bps (32 kbps mono) — ideal for clean voice records and tiny storage footprint.
 * - Sample rate: 16000 Hz (16 kHz).
 * - Codec: Opus audio encoder inside an Ogg container.
 * 
 * ## Audio Source
 * - Default: [MediaRecorder.AudioSource.VOICE_CALL]. This requires system-level permissions
 *   (which we obtain via Shizuku). If Shizuku is not running, we fall back to [MediaRecorder.AudioSource.MIC]
 *   which records microphone input only.
 */
data class RecordingConfig(
    val outputDir: String = "/storage/emulated/0/Shuni/recordings",
    val audioSource: Int = MediaRecorder.AudioSource.VOICE_CALL,
    val outputFormat: Int = 11, // MediaRecorder.OutputFormat.OGG (available in API 29+)
    val audioEncoder: Int = 7,  // MediaRecorder.AudioEncoder.OPUS (available in API 29+)
    val bitRate: Int = 32000,
    val sampleRate: Int = 16000,
    val channels: Int = 1 // Mono (perfect for voice recordings)
) {
    /**
     * Generates a filesystem-friendly, descriptive filename:
     * `{date}_{time}_{contactName}_{direction}.ogg`
     */
    fun generateFileName(contactName: String, direction: String): String {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd_HH-mm-ss", Locale.US)
        val timestamp = dateFormat.format(Date())
        
        // Clean contact name to avoid filesystem errors
        val cleanName = contactName.replace(Regex("[\\\\/:*?\"<>|\\s]"), "_")
        return "${timestamp}_${cleanName}_${direction.lowercase()}.ogg"
    }
}
