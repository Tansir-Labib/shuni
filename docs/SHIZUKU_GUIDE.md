# Shizuku Configuration Guide — Shuni Call Recorder

To record voice calls on Android 16 without rooting your device, Shuni requires **Shizuku**. Shizuku binds to Android's internal debugging ports, allowing Shuni to execute operations with Developer ADB privileges.

---

## 📋 Step-by-Step Configuration

### Step 1: Install Shizuku
1. Open the **Google Play Store** on your phone.
2. Search for **Shizuku** (developed by Rikka).
3. Download and install it. It is entirely free and open-source.

### Step 2: Enable Developer Options
1. On your phone, open **Settings** → **About phone**.
2. Scroll to the bottom and find the **Build number**.
3. Tap **Build number 7 times** until a popup says *"You are now a developer!"*.
4. Enter your lock screen PIN if prompted.

### Step 3: Enable Wireless Debugging
1. Go back to main **Settings** → **System** → **Developer options**.
2. Scroll down to find **USB Debugging** and toggle it **ON**.
3. Scroll down further to find **Wireless Debugging** and toggle it **ON**.
   - *Note: You must be connected to a WiFi network to enable Wireless Debugging.*
4. Tap directly on the text "Wireless Debugging" to enter its details screen.

### Step 4: Pair Shizuku
1. Open the **Shizuku** app.
2. Under the "Start via Wireless Debugging" section, tap **Pairing**.
3. Tap **Developer options** to return to the Wireless Debugging screen.
4. On the Wireless Debugging screen, tap **Pair device with pairing code**.
5. A popup will show a 6-digit pairing code. Note it down.
6. A system notification from Shizuku will appear saying *"Enter pairing code"*.
7. Swipe down your notification panel, tap the Shizuku notification, enter the 6-digit code, and tap submit.
8. The notification will show *"Pairing successful"*!

### Step 5: Start the Shizuku Service
1. Open the **Shizuku** app.
2. Go back to its main screen.
3. Under the "Start via Wireless Debugging" section, tap **Start**.
4. A terminal overlay will execute commands. In a few seconds, the top of the Shizuku app will display **"Shizuku is running"** in green!

### Step 6: Authorize Shuni
1. Open the **Shuni** app.
2. During onboarding (or on the settings screen), it will detect Shizuku and display a status badge.
3. Tap **Request Access** or **Authorize**.
4. A Shizuku system overlay prompt will appear asking to authorize Shuni.
5. Select **Allow always** (or **Allow**).
6. The status badge in Shuni will immediately change to **Shizuku: Active** (Green).
7. You are ready to record calls!

---

## ⚠️ What Happens on Reboot?
Whenever you reboot/restart your phone, Android kills all active debugging ports. This means Shizuku will stop running.
1. When your phone turns back on, connect to WiFi.
2. Open the **Shizuku** app.
3. Tap **Start**.
4. You do **NOT** need to pair it again. The service will start in ~5 seconds.
5. Shuni will automatically re-detect the connection and start recording calls.

---

## 🔍 Troubleshooting

### 1. Wireless Debugging turns off automatically
On some battery configurations, Android disables Wireless Debugging if you disconnect from WiFi. Make sure you are connected to a stable WiFi network while launching.

### 2. "Starting service..." hangs on Shizuku
If the terminal command hangs when starting:
1. Turn Wireless Debugging **OFF** in developer options.
2. Turn it back **ON**.
3. Open Shizuku and tap **Start** again.
