# 🚀 Release APK Build Instructions

## Prerequisites
You need to generate a signing key for your release APK.

## Step 1: Generate Keystore

Run this command in your terminal (Windows PowerShell):

```powershell
cd android/app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**You'll be asked for:**
- Keystore password (choose a strong password, you'll need it twice)
- Your name
- Organization unit
- Organization name
- City/Locality
- State/Province
- Country code (2-letter, e.g., IN for India)

**⚠️ IMPORTANT:** Save these passwords securely! You'll need them to sign future updates.

## Step 2: Create key.properties

Create a file named `key.properties` in the `android` folder with this content:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=app/upload-keystore.jks
```

Replace `YOUR_KEYSTORE_PASSWORD` and `YOUR_KEY_PASSWORD` with the passwords you used in Step 1.

**⚠️ NEVER commit this file to Git!** It's already in .gitignore.

## Step 3: Build Release APK

```powershell
# Navigate to project root
cd S:\Code\Expense-Tracker

# Clean build
flutter clean

# Build release APK
flutter build apk --release
```

Or to build an app bundle for Google Play Store:

```powershell
flutter build appbundle --release
```

## Step 4: Locate Your Release Files

**APK location:**
```
build\app\outputs\flutter-apk\app-release.apk
```

**App Bundle location:**
```
build\app\outputs\bundle\release\app-release.aab
```

## APK vs App Bundle

| Type | Size | Use Case |
|------|------|----------|
| APK | ~50-80MB | Direct installation, sharing |
| AAB (App Bundle) | Smaller | Google Play Store upload |

---

## 🔐 Security Checklist

- [x] `key.properties` is in .gitignore
- [x] `upload-keystore.jks` is in .gitignore
- [ ] Backup your keystore file securely (Google Drive, password manager)
- [ ] Store passwords in secure password manager
- [ ] Never share keystore or passwords

---

## Troubleshooting

### "keytool is not recognized"
Add Java to your PATH or use full path:
```powershell
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey ...
```

### "keystore not found"
Make sure `storeFile` path in `key.properties` is correct:
```
storeFile=app/upload-keystore.jks
```

### Build fails with signing error
Check that all 4 properties in `key.properties` are correct and passwords match.

---

## GitHub Actions Setup for Supabase

### Add Secrets to GitHub

1. Open your `.env` file (in project root) to find your Supabase credentials
2. Go to your repo: `https://github.com/YOUR_USERNAME/Expense-Tracker`
3. Click **Settings** → **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add these secrets:
   - **Name:** `SUPABASE_URL`  
     **Value:** Copy `SUPABASE_URL` value from your `.env` file
   - **Name:** `SUPABASE_ANON_KEY`  
     **Value:** Copy `SUPABASE_ANON_KEY` value from your `.env` file

### Verify Workflow

The workflow is already created at `.github/workflows/keep-supabase-active.yml`

It will:
- ✅ Run every 6 hours automatically
- ✅ Ping your Supabase database to keep it active
- ✅ Can be manually triggered from GitHub Actions tab

### Test Manually

1. Go to your GitHub repo
2. Click **Actions** tab
3. Click **Keep Supabase Active** workflow
4. Click **Run workflow** → **Run workflow**
5. Wait ~10 seconds and refresh to see results

---

## Next Steps

1. Generate keystore (if you haven't already)
2. Create `android/key.properties` file
3. Run `flutter build apk --release`
4. Add GitHub secrets for Supabase
5. Test the GitHub Action manually

**Your signed APK will be ready for distribution!** 🎉
