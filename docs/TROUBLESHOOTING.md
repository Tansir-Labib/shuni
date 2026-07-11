# Shuni Troubleshooting Guide

This guide details resolutions for common runtime and configuration issues.

---

## 🔍 Issue Index

### 1. Recording is silent or only records one side
- **Cause**: Shizuku is either stopped, not connected, or lacks permission. Without Shizuku, Shuni falls back to standard microphone recording which can only capture your microphone.
- **Resolution**:
  1. Open the **Shizuku** app and confirm that it says **"Shizuku is running"** in green.
  2. Open the **Shuni** settings panel and verify that the Shizuku badge is **green (Active)**.
  3. If it displays "No Permission", tap the badge to trigger the authorization prompt and select "Allow always".
  4. If your phone recently rebooted, you must reopen the **Shizuku** app and tap **Start** again.

### 2. Location is missing from calls
- **Cause**: Device GPS was disabled, or Shuni lacks Location permissions.
- **Resolution**:
  1. Pull down your notification bar and ensure **Location (GPS)** is enabled globally.
  2. Go to **Android Settings** → **Apps** → **Shuni** → **Permissions** → **Location** and select **"Allow all the time"** (or "Allow only while using the app").

### 3. Google Drive backup fails
- **Cause**: OAuth2 token expired, or WiFi settings blocked synchronization.
- **Resolution**:
  1. Verify your internet connection.
  2. Open Shuni settings. If "WiFi Only" backup is enabled, verify you are connected to a WiFi network.
  3. If backup fails repeatedly, tap **Disconnect** under Google integration, then tap **Connect** to re-authenticate and refresh credentials.

### 4. PIN Lockout screen appears
- **Cause**: Five incorrect PIN entries triggered the brute force lockout timer.
- **Resolution**:
  1. Wait for the 30-second countdown to complete. The field will unlock automatically.
  2. If biometrics are enabled, you can bypass the PIN by tapping the fingerprint icon.
  3. If you completely forgot your PIN, you must clear the app's cache/data via Android Settings, which resets settings (recordings in `/Shuni/recordings/` will NOT be deleted, but the database list must be recovered using the Google Drive restore feature).

### 5. Recordings don't show up in standard music players
- **Cause**: Shuni automatically places a `.nomedia` file in its folders to prevent your call logs from cluttering your standard music library.
- **Resolution**: This is an intended feature. To play files externally, open your files manager app, navigate to `/Shuni/recordings/`, and open them directly using VLC or any audio player.
