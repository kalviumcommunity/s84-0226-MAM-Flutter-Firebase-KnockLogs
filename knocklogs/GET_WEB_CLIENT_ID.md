# 🔑 How to Get Web Client ID for Google Sign-In

## Quick Summary
Your Flutter web app needs a **Web Client ID** from Google Cloud Console to authenticate users. Without this, Google Sign-In won't work on the web platform.

---

## ✅ Complete Step-by-Step Guide

### **Step 1: Open Google Cloud Console**
- Visit: https://console.cloud.google.com/
- **Sign in with the same Google account** used for your Firebase project
- Select your project: **knocklogs** (from the dropdown at the top)

---

### **Step 2: Enable OAuth 2.0 Consent Screen**
If not already done:
1. Go to **Credentials** section (left sidebar)
2. Look for "**OAuth consent screen**" tab → Click it
3. Select **External** as User Type
4. Fill in:
   - **App name**: KnockLogs
   - **User support email**: Your email
   - **Developer contact information**: Your email
5. On Scopes screen, click **Add or Remove Scopes**
6. Search and select:
   - `email`
   - `profile`
   - `openid`
7. Continue and save

---

### **Step 3: Create Web OAuth Client ID** ⭐ MAIN STEP

1. In **Credentials** section, click **+ CREATE CREDENTIALS**
   
2. Select **OAuth client ID**

3. Choose **Application type: Web application**

4. Give it a name: `knocklogs-web`

5. **IMPORTANT - Add Authorized JavaScript Origins:**
   ```
   http://localhost:5000
   http://localhost:5001
   http://localhost
   http://127.0.0.1:5000
   ```
   *(These are for local development)*

6. **Add Authorized Redirect URIs:**
   ```
   http://localhost:5000/
   http://localhost:5001/
   http://localhost/
   http://127.0.0.1:5000/
   ```

7. Click **CREATE**

---

### **Step 4: Copy Your Web Client ID**

A popup will show your credentials:
```
Client ID: xxxxxxxxxxxxxxxx.apps.googleusercontent.com
Client Secret: xxxxxxxxxxxxxxxxxxxxx
```

**COPY THE CLIENT ID** (the one ending with `.apps.googleusercontent.com`)

---

### **Step 5: Update Your Flutter App**

Open: `lib/services/google_auth_service.dart`

Find this line (around line 12):
```dart
clientId: '218660413688-abc123.apps.googleusercontent.com', // TODO: Replace with your Web Client ID
```

Replace with your copied Client ID:
```dart
clientId: 'YOUR_ACTUAL_CLIENT_ID.apps.googleusercontent.com',
```

**Example:**
```dart
clientId: '218660413688-v2a3b5c7d9e1f3h5j7k9l1m3n5p.apps.googleusercontent.com',
```

---

### **Step 6: Run Your App**

```bash
cd knocklogs
flutter run -d chrome
```

Or if using a specific port:
```bash
flutter run -d chrome --web-port 5000
```

---

## 🚨 Important Notes

1. **For Production**: Later add your production domain:
   - Go back to Credentials
   - Edit your Web OAuth Client
   - Add authorized origins like:
     - `https://yourapp.com`
     - `www.yourapp.com`

2. **Error Messages You Might See**:
   - ❌ `plugin_google_sign_in_web: Unrecognized client 'web_client(null)'`
     → You forgot to add the clientId
   
   - ❌ `com.google.android.gms.common.api.ApiException: 10`
     → The origin isn't authorized in Google Console

3. **Testing**: The `http://localhost:5000` and similar origins ONLY work locally. Use a new origin for production.

---

## 📋 Checklist

- [ ] Go to Google Cloud Console
- [ ] Enable OAuth Consent Screen
- [ ] Create Web OAuth Client ID
- [ ] Add `http://localhost:5000` to authorized origins
- [ ] Copy the Client ID
- [ ] Update `google_auth_service.dart` with the Client ID
- [ ] Run `flutter run -d chrome`
- [ ] Test Google Sign-In button

---

## 🎯 Your Project Details (Already Configured)

- **Project**: `knocklogs`
- **Firebase API Key**: `AIzaSyC8dH8pQ9a5UZL_OLgFufYCiCeOTaU8b5A`
- **Auth Domain**: `knocklogs.firebaseapp.com`
- **App ID**: `1:218660413688:web:5d73717d39ae2530079b0d`

---

## ❓ Troubleshooting

**Q: I can't find Google Cloud Console**
A: Go to https://console.cloud.google.com/ and look for the project dropdown

**Q: My project isn't showing**
A: Make sure you're signed in with the correct Google account and selected the right project

**Q: Where do I put the Client ID?**
A: Open `lib/services/google_auth_service.dart` and replace the `clientId` parameter in the GoogleSignIn initialization

**Q: The button shows "Sign in with Google" but nothing happens**
A: You likely forgot to update the clientId. Check step 5 above.

