# 📱 Install Inquira on Your Real Phone

## ✅ What's Done
- IQ.png is now set as your app icon and launch logo
- App icons generated for both Android and iOS

---

## 🤖 For Android Phone

### Step 1: Enable Developer Mode
1. Go to **Settings** → **About Phone**
2. Find **Build Number** (usually under Software Information)
3. Tap **Build Number** 7 times until you see "You are now a developer!"

### Step 2: Enable USB Debugging
1. Go to **Settings** → **Developer Options** (should now be visible)
2. Turn on **USB Debugging**
3. Turn on **Install via USB** (if available)

### Step 3: Connect Phone to Computer
1. Connect your phone to computer with USB cable
2. On your phone, you'll see a popup asking "Allow USB debugging?"
3. Check "Always allow from this computer" and tap **OK**

### Step 4: Verify Connection
In VS Code terminal, run:
```bash
flutter devices
```
You should see your phone listed!

### Step 5: Install & Run App
```bash
flutter run
```
Or in VS Code: Press **F5** and select your phone from the device list

---

## 🍎 For iPhone

### Step 1: Install on Mac
1. Connect iPhone to Mac with cable
2. Trust the computer on iPhone when prompted
3. Run: `flutter run`

### Step 2: Trust Developer Certificate
1. On iPhone, go to **Settings** → **General** → **VPN & Device Management**
2. Find your developer profile and tap **Trust**

---

## 🚀 Quick Commands

### Check Connected Devices
```bash
cd /c/Users/Admin/OneDrive/Documents/5-Web-Development/4-Projects/inquira
flutter devices
```

### Build Release APK (to share with others)
```bash
flutter build apk --release
```
APK will be in: `build/app/outputs/flutter-apk/app-release.apk`

### Install Directly on Phone
```bash
flutter install
```

### Run in Release Mode (faster performance)
```bash
flutter run --release
```

---

## 🔧 Troubleshooting

### Phone Not Detected?
1. Make sure USB debugging is enabled
2. Try different USB cable (some cables are charge-only)
3. Try different USB port on computer
4. Restart both phone and computer
5. Run: `adb devices` to check connection

### "Waiting for device to be available"?
- Unlock your phone screen
- Accept USB debugging prompt on phone

### Build Failed?
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📦 Build for Distribution

### Android APK
```bash
# Build release APK
flutter build apk --release

# Find APK at:
# build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```

---

## 🎉 That's It!
Your app now has the IQ.png logo and is ready to install on your phone!
