package com.shuni.app.shizuku

/**
 * # ShizukuStatus
 * 
 * Sealed class representing all possible connection and permission states of the Shizuku bridge.
 * Exposes a helper `toMap()` method to easily serialize states across Platform Channels to Flutter.
 */
sealed class ShizukuStatus {
    abstract val status: String

    object Ready : ShizukuStatus() {
        override val status: String = "ready"
    }

    object NotInstalled : ShizukuStatus() {
        override val status: String = "not_installed"
    }

    object NotRunning : ShizukuStatus() {
        override val status: String = "not_running"
    }

    object NoPermission : ShizukuStatus() {
        override val status: String = "no_permission"
    }

    fun toMap(): Map<String, String> {
        return mapOf("status" to status)
    }
}
