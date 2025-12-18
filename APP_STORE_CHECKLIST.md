# App Store Submission Checklist

## ✅ Already Completed

- [x] App icons (Android & iOS)
- [x] Launch screens
- [x] Privacy Policy (in-app)
- [x] Terms and Conditions (in-app)
- [x] Terms acceptance flow
- [x] Version numbers configured (1.0.0+1)
- [x] App permissions configured
- [x] Dark mode support
- [x] AI integration with rate limiting
- [x] Error handling
- [x] **iOS TestFlight setup** ✅
- [x] **Apple Developer Account** ✅
- [x] **iOS Code Signing** ✅
- [x] **App Store Connect app created** ✅

## 🔴 CRITICAL - Must Fix Before Submission

### 1. Android Release Signing ⚠️
**Current Issue:** Using debug signing (`signingConfig signingConfigs.debug`)

**Required:**
- [ ] Create release keystore
- [ ] Configure release signing in `android/app/build.gradle`
- [ ] Create `android/key.properties` file (add to `.gitignore`)
- [ ] Update `build.gradle` to use release signing

**Steps:**
```bash
# Generate keystore
keytool -genkey -v -keystore ~/pezo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pezo

# Create key.properties (DO NOT COMMIT THIS FILE)
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=pezo
storeFile=<path-to-keystore>
```

### 2. iOS Code Signing & Certificates ✅
**Status:** Already done (app is on TestFlight)

- [x] Apple Developer Account ($99/year)
- [x] App ID registered in Apple Developer Portal
- [x] Distribution certificate created
- [x] Provisioning profile created
- [x] Configure signing in Xcode

### 3. Privacy Policy URL 🔴
**Current:** Privacy policy is only in-app

**Required:**
- [ ] Host privacy policy on a public URL (GitHub Pages, your website, etc.)
- [ ] Update app to include privacy policy URL
- [ ] Add URL to App Store Connect (iOS)
- [ ] Add URL to Google Play Console (Android)

**Options:**
- GitHub Pages (free)
- Your own domain
- Firebase Hosting (free)

### 4. App Store Listings 📱

#### Google Play Store:
- [ ] App name (max 50 chars)
- [ ] Short description (max 80 chars)
- [ ] Full description (max 4000 chars)
- [ ] App icon (512x512 PNG, no transparency)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots:
  - Phone: At least 2, up to 8 (16:9 or 9:16)
  - Tablet (optional): At least 2, up to 8
- [ ] Category selection
- [ ] Content rating questionnaire
- [ ] Data safety section (privacy practices)
- [ ] Target audience
- [ ] Contact email: `developpers.applications@gmail.com`

#### Apple App Store:
**Status:** Partially done (TestFlight setup), but need to complete store listing:
- [ ] App name (max 30 chars) - Check if set in App Store Connect
- [ ] Subtitle (max 30 chars)
- [ ] Description (max 4000 chars) - **Required for App Store release**
- [ ] Keywords (max 100 chars, comma-separated)
- [ ] App icon (1024x1024 PNG) - Check if uploaded
- [ ] Screenshots: **REQUIRED for App Store release**
  - iPhone: 6.7", 6.5", 5.5" displays
  - iPad (if supported): 12.9" display
- [ ] App preview video (optional but recommended)
- [ ] Category selection
- [ ] Age rating questionnaire - **Complete if not done**
- [ ] Privacy policy URL - **CRITICAL - Need public URL**
- [ ] Support URL (can be same as privacy policy or GitHub)
- [ ] Contact email: `developpers.applications@gmail.com`
- [ ] App Privacy questionnaire - **Complete in App Store Connect**

### 5. iOS Privacy Manifest (Required for AI) ⚠️
**Current:** Using OpenAI via Cloudflare Worker

**Status:** May already be configured if TestFlight submission was successful, but verify:
- [ ] Check if `PrivacyInfo.xcprivacy` exists in `ios/Runner/`
- [ ] Verify it declares data collection practices
- [ ] Ensure it lists third-party SDKs (Google ML Kit, etc.)
- [ ] Update if needed for AI data sharing

**File location:** `ios/Runner/PrivacyInfo.xcprivacy`

**Note:** If TestFlight was approved, this might already be done, but double-check for production release.

### 6. Android Data Safety Section 🔴
**Required in Google Play Console:**
- [ ] Declare data collection practices
- [ ] List data types collected (financial data, images)
- [ ] Explain data usage (AI analysis)
- [ ] Specify data sharing (OpenAI via Cloudflare)
- [ ] Security practices

### 7. Build Configuration 🔴

#### Android:
- [ ] Remove debug signing from release build
- [ ] Set `minifyEnabled true` (already done)
- [ ] Configure ProGuard rules (check `proguard-rules.pro`)
- [ ] Test release build: `flutter build appbundle --release`

#### iOS:
- [ ] Set build number appropriately
- [ ] Configure release scheme in Xcode
- [ ] Archive build: `flutter build ipa --release`
- [ ] Test on physical device

### 8. Version & Build Numbers 📝
**Current:** `version: 1.0.0+1`

**Check:**
- [ ] Version name: `1.0.0` (semantic versioning)
- [ ] Build number: `1` (increment for each submission)
- [ ] iOS CFBundleVersion matches build number
- [ ] Android versionCode matches build number

## ⚠️ IMPORTANT - Should Complete

### 9. Testing Checklist ✅
- [ ] Test on physical Android device
- [ ] Test on physical iOS device
- [ ] Test all core features:
  - [ ] Add transactions
  - [ ] Receipt scanning
  - [ ] Budget management
  - [ ] Analytics
  - [ ] AI "Should I Buy It?" feature
  - [ ] Data export
- [ ] Test offline mode
- [ ] Test dark mode
- [ ] Test on different screen sizes
- [ ] Test permissions (camera, storage)

### 10. Content Guidelines 📋
- [ ] App name doesn't violate trademarks
- [ ] Screenshots show actual app functionality
- [ ] Description is accurate and clear
- [ ] No placeholder text in app
- [ ] All features mentioned work correctly

### 11. Legal Requirements ⚖️
- [ ] Privacy Policy URL accessible
- [ ] Terms of Service accessible
- [ ] Contact email working: `developpers.applications@gmail.com`
- [ ] Age rating appropriate (likely 4+ or 12+)
- [ ] No prohibited content

### 12. App Store Optimization (ASO) 📈
- [ ] Research keywords
- [ ] Optimize app name and description
- [ ] Use relevant screenshots
- [ ] Add app preview video (optional but recommended)

## 💡 Nice to Have (Can Add Later)

### 13. Additional Features
- [ ] App Store screenshots generator tool
- [ ] Beta testing program (TestFlight for iOS, Internal Testing for Android)
- [ ] Analytics integration (Firebase Analytics, etc.)
- [ ] Crash reporting (Firebase Crashlytics, Sentry)

### 14. Marketing Materials
- [ ] App preview video
- [ ] Promotional images
- [ ] Social media assets
- [ ] Press kit

## 🚀 Submission Steps

### Google Play Store:
1. Create Google Play Developer account ($25 one-time)
2. Create new app in Play Console
3. Fill out store listing
4. Upload app bundle: `flutter build appbundle --release`
5. Complete content rating questionnaire
6. Complete data safety section
7. Set pricing (free/paid)
8. Submit for review

### Apple App Store:
1. ✅ Create Apple Developer account ($99/year) - **DONE**
2. ✅ Create app in App Store Connect - **DONE**
3. ⚠️ Fill out app information - **IN PROGRESS** (TestFlight done, need store listing)
4. ✅ Upload build via Xcode or Transporter - **DONE** (TestFlight)
5. ⚠️ Complete App Privacy questionnaire - **VERIFY COMPLETION**
6. ⚠️ Set pricing and availability - **VERIFY**
7. ⚠️ Submit for review - **READY AFTER COMPLETING ABOVE**

## 📋 Quick Reference

### Required Files:
- ✅ `android/app/build.gradle` - Update signing config
- ✅ `android/key.properties` - Create (DO NOT COMMIT)
- ✅ `ios/Runner/PrivacyInfo.xcprivacy` - Create privacy manifest
- ✅ Privacy Policy URL - Host publicly

### Required Accounts:
- [ ] Google Play Developer Account ($25)
- [x] Apple Developer Account ($99/year) ✅ **DONE**

### Contact Information:
- Email: `developpers.applications@gmail.com`
- App Name: Pezo
- Package: `com.pezo.app`

## ⏱️ Estimated Timeline

- **Android:** 1-3 days (after fixing signing)
- **iOS:** **1-2 days** (TestFlight already done, just need to complete store listing and submit)
- **Review Time:** 
  - Google Play: 1-3 days
  - Apple App Store: 1-7 days (usually 24-48 hours for updates)

## 🎯 Priority Order

### For iOS App Store Release (You're almost there!):
1. **Host privacy policy URL** (30 min) - **CRITICAL**
2. **Complete App Store listing** (1-2 hours):
   - App description
   - Screenshots (REQUIRED)
   - Keywords
   - Category
3. **Complete App Privacy questionnaire** (15 min)
4. **Submit for App Store review** (5 min)

### For Android:
1. **Fix Android signing** (30 min) - **CRITICAL**
2. **Create Google Play listing** (2-3 hours)
3. **Take screenshots** (1 hour)
4. **Submit for review**

---

**Next Steps:** Start with Android signing configuration, then move to iOS setup.

