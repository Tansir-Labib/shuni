package com.shuni.app.detection

import android.content.Context
import android.net.Uri
import android.provider.ContactsContract
import java.util.concurrent.ConcurrentHashMap

/**
 * # ContactResolver
 * 
 * Helper module that queries Android's `ContactsContract` database to resolve raw phone numbers
 * to contact names.
 * 
 * ## Memory Cache (For Learning)
 * querying database records takes a few milliseconds and consumes CPU power.
 * We store resolved numbers in a thread-safe `ConcurrentHashMap` in memory. If a call starts
 * and we already resolved the contact name previously, we fetch it instantly from the cache,
 * reducing latency.
 */
object ContactResolver {
    
    private val nameCache = ConcurrentHashMap<String, String>()

    /**
     * Resolves a phone number to a display name. Returns "Unknown" if not found.
     */
    fun resolve(context: Context, phoneNumber: String): String {
        if (phoneNumber.isEmpty() || phoneNumber == "Unknown") return "Unknown"
        
        // Check cache first
        nameCache[phoneNumber]?.let { return it }

        var contactName = "Unknown"
        val uri = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
            Uri.encode(phoneNumber)
        )

        val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
        
        try {
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                    if (index >= 0) {
                        contactName = cursor.getString(index)
                    }
                }
            }
        } catch (e: Exception) {
            // Fail silently, falls back to "Unknown"
        }

        // Cache resolved value
        nameCache[phoneNumber] = contactName
        return contactName
    }

    fun clearCache() {
        nameCache.clear()
    }
}
