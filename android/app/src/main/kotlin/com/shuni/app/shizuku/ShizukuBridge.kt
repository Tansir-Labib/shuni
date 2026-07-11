package com.shuni.app.shizuku

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import rikka.shizuku.Shizuku
import rikka.shizuku.ShizukuProvider
import java.util.concurrent.CountDownLatch

/**
 * # ShizukuBridge
 * 
 * Manages the connection, binding status, and permission requests for the Shizuku framework.
 * 
 * ## How Shizuku Bypasses OS Restrictions (For Learning)
 * Normally, the Android OS blocks third-party apps from capturing phone call streams
 * using safety policies. ADB (Android Debug Bridge) shell users, however, are granted
 * developer privileges which bypass these blocks.
 * Shizuku acts as a system binder that lets our app execute commands under ADB shell privileges.
 * 
 * ## API References
 * - rikka.shizuku.Shizuku : The official Shizuku client package.
 */
class ShizukuBridge(private val context: Context) {

    private val permissionListener = Shizuku.OnRequestPermissionResultListener { _, grantResult ->
        // Callback when user responds to Shizuku permission dialog
        isPermissionGranted = (grantResult == PackageManager.PERMISSION_GRANTED)
    }

    private val binderListener = Shizuku.OnBinderReceivedListener {
        // Callback when Shizuku service binds to our process
        isBinderReceived = true
    }

    private val deadListener = Shizuku.OnBinderDeadListener {
        // Callback when Shizuku service dies or gets killed
        isBinderReceived = false
    }

    private var isBinderReceived = false
    private var isPermissionGranted = false

    init {
        isBinderReceived = Shizuku.pingBinder()
        isPermissionGranted = checkShizukuPermission()
    }

    /**
     * Registers connection status listeners.
     */
    fun bindService() {
        Shizuku.addBinderReceivedListener(binderListener)
        Shizuku.addBinderDeadListener(deadListener)
        Shizuku.addRequestPermissionResultListener(permissionListener)
    }

    /**
     * Unregisters listeners to prevent memory leaks.
     */
    fun unbindService() {
        Shizuku.removeBinderReceivedListener(binderListener)
        Shizuku.removeBinderDeadListener(deadListener)
        Shizuku.removeRequestPermissionResultListener(permissionListener)
    }

    /**
     * Verifies if the Shizuku app is installed on the phone.
     */
    fun isInstalled(): Boolean {
        return try {
            context.packageManager.getPackageInfo("moe.shizuku.privileged.api", 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    /**
     * Verifies if Shizuku's background service is running.
     */
    fun isRunning(): Boolean {
        return Shizuku.pingBinder()
    }

    /**
     * Verifies if Shizuku has granted permission to Shuni.
     */
    fun checkShizukuPermission(): Boolean {
        if (!isRunning()) return false
        return try {
            if (Shizuku.isPreV11()) {
                // Legacy support
                false
            } else {
                Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED
            }
        } catch (e: Throwable) {
            false
        }
    }

    /**
     * Resolves the current connection state of Shizuku.
     */
    fun getStatus(): ShizukuStatus {
        if (!isInstalled()) return ShizukuStatus.NotInstalled
        if (!isRunning()) return ShizukuStatus.NotRunning
        if (!checkShizukuPermission()) return ShizukuStatus.NoPermission
        return ShizukuStatus.Ready
    }

    /**
     * Triggers the native Shizuku permission dialog.
     */
    fun requestPermission(): Boolean {
        if (!isRunning()) return false
        return try {
            if (Shizuku.isPreV11()) {
                false
            } else {
                Shizuku.requestPermission(1001)
                true
            }
        } catch (e: Throwable) {
            false
        }
    }
}
