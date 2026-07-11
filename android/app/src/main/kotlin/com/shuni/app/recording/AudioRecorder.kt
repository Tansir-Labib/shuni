package com.shuni.app.recording

import android.media.MediaRecorder
import android.os.Build
import android.os.SystemClock
import java.io.File

/**
 * # AudioRecorder
 * 
 * High-performance wrapper around Android's [MediaRecorder] to handle voice call recording.
 * 
 * ## Error Recovery Fallback (For Learning)
 * If we start recording using `VOICE_CALL` and Android throws a security/permission error
 * (e.g. if Shizuku stopped or permissions got revoked), this class catches the exception
 * and automatically retries using `MIC` (microphone) as a fallback. This guarantees we
 * capture *something* (at least the user's voice) rather than dropping the call archive.
 */
class AudioRecorder {

    private var recorder: MediaRecorder? = null
    private var isRecording = false
    private var startTime: Long = 0
    private var currentFile: File? = null

    /**
     * Starts recording a call.
     * Retries using MIC if VOICE_CALL fails.
     */
    fun start(config: RecordingConfig, filename: String): String {
        if (isRecording) stop()

        val destDir = File(config.outputDir)
        if (!destDir.exists()) {
            destDir.mkdirs()
        }

        val file = File(destDir, filename)
        currentFile = file

        try {
            // Attempt to start using primary configuration (VOICE_CALL via Shizuku)
            _initAndStartRecorder(config.audioSource, config, file)
        } catch (e: Exception) {
            // Fallback: If VOICE_CALL fails, retry using the Microphone
            if (config.audioSource == MediaRecorder.AudioSource.VOICE_CALL) {
                try {
                    _initAndStartRecorder(MediaRecorder.AudioSource.MIC, config, file)
                } catch (fallbackEx: Exception) {
                    throw fallbackEx
                }
            } else {
                throw e
            }
        }

        return file.absolutePath
    }

    private fun _initAndStartRecorder(source: Int, config: RecordingConfig, file: File) {
        val r = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder()
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }

        r.setAudioSource(source)
        r.setOutputFormat(config.outputFormat)
        r.setAudioEncoder(config.audioEncoder)
        r.setAudioEncodingBitRate(config.bitRate)
        r.setAudioSamplingRate(config.sampleRate)
        r.setAudioChannels(config.channels)
        r.setOutputFile(file.absolutePath)

        r.prepare()
        r.start()

        recorder = r
        isRecording = true
        startTime = SystemClock.elapsedRealtime()
    }

    /**
     * Stops the active recording and releases system audio resources.
     */
    fun stop(): RecordingResult? {
        if (!isRecording) return null

        val elapsed = SystemClock.elapsedRealtime() - startTime
        val durationSec = (elapsed / 1000).toInt()

        try {
            recorder?.stop()
        } catch (e: Exception) {
            // Can occur if stopped immediately after starting
        } finally {
            recorder?.release()
            recorder = null
            isRecording = false
        }

        val file = currentFile
        currentFile = null

        if (file != null && file.exists()) {
            return RecordingResult(
                filePath = file.absolutePath,
                durationSeconds = durationSec,
                fileSizeBytes = file.length()
            )
        }
        return null
    }

    fun isRecordingActive(): Boolean = isRecording

    fun getElapsedTime(): Long {
        if (!isRecording) return 0
        return SystemClock.elapsedRealtime() - startTime
    }
}

/**
 * Result data class returned when recording finishes.
 */
data class RecordingResult(
    val filePath: String,
    val durationSeconds: Int,
    val fileSizeBytes: Long
)
