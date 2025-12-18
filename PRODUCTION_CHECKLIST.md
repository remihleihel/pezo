# Production Readiness Checklist

## ✅ Completed

- [x] AI integration with Cloudflare Worker
- [x] Rate limiting (3 requests/day)
- [x] Local caching (7-day TTL)
- [x] Graceful error handling
- [x] User choice for AI mode (Auto/Always/Never)
- [x] Security headers and validation

## 🔴 Critical - Must Fix Before Launch

### 1. Remove Debug Logging
- [ ] Remove all `print()` statements from production code
- [ ] Replace with proper logging (e.g., `debugPrint()` or logging package)
- **Files to check:**
  - `lib/services/ai_should_i_buy_service.dart` (multiple print statements)
  - `lib/screens/should_i_buy_screen.dart` (print statements)

### 2. Worker URL Configuration
- [ ] Move worker URL to environment variable or config file
- [ ] Don't hardcode in source code
- **Current:** `static const String _workerBaseUrl = 'https://pezo-ai-worker.remihleihel.workers.dev';`
- **Options:**
  - Use `flutter_dotenv` package
  - Use build flavors (dev/staging/prod)
  - Store in remote config service

### 3. Currency Hardcoding
- [ ] Fix hardcoded 'USD' currency (line 362 in should_i_buy_screen.dart)
- [ ] Get currency from user settings or device locale
- [ ] Support multiple currencies

### 4. Error Messages for Users
- [ ] Add user-friendly error messages for:
  - Rate limit exceeded (show "3 requests/day limit reached")
  - Network failures
  - AI service unavailable
- [ ] Currently just shows "AI unavailable" - be more specific

## ⚠️ Important - Should Fix

### 5. Rate Limit Feedback
- [ ] Show remaining AI requests count to user
- [ ] Display when rate limit is reached
- [ ] Maybe show countdown to reset

### 6. Privacy Policy & Terms
- [ ] Add Privacy Policy (required for app stores)
- [ ] Mention AI data usage:
  - Financial data sent to OpenAI via Cloudflare Worker
  - Data not stored by OpenAI (per their policy)
  - Rate limiting and caching
- [ ] Add Terms of Service
- [ ] Link from app settings/about screen

### 7. App Store Requirements
- [ ] **iOS:**
  - App Store Connect setup
  - Privacy manifest (if using AI)
  - App Store screenshots
  - App description mentioning AI feature
- [ ] **Android:**
  - Google Play Console setup
  - Privacy policy URL
  - App description
  - Screenshots

### 8. Testing
- [ ] Test rate limiting (make 4 requests, verify 4th fails)
- [ ] Test offline mode (airplane mode)
- [ ] Test with zero transactions
- [ ] Test with very large amounts
- [ ] Test cache expiration (7 days)
- [ ] Test all 3 AI modes (Auto/Always/Never)
- [ ] Test error scenarios (worker down, invalid response)

### 9. Monitoring & Analytics
- [ ] Add error tracking (Sentry, Firebase Crashlytics)
- [ ] Monitor Cloudflare Worker logs
- [ ] Track AI usage metrics
- [ ] Monitor rate limit hits

### 10. Build Configuration
- [ ] Set up release build configuration
- [ ] Configure signing (Android keystore, iOS certificates)
- [ ] Set version numbers appropriately
- [ ] Configure ProGuard/R8 rules (Android)
- [ ] Test release builds

## 💡 Nice to Have

### 11. User Experience
- [ ] Add loading indicator when AI is fetching
- [ ] Show "AI analyzing..." message
- [ ] Better visual distinction between local vs AI decisions
- [ ] Allow users to see cached AI decisions

### 12. Performance
- [ ] Optimize image loading (if using images)
- [ ] Review database queries
- [ ] Check for memory leaks

### 13. Documentation
- [ ] User guide/documentation
- [ ] API documentation (for future developers)
- [ ] Deployment guide

## 🔒 Security Checklist

- [x] API keys not in source code (Cloudflare secrets)
- [x] No direct OpenAI calls from app
- [x] Rate limiting in place
- [ ] Verify HTTPS only
- [ ] Review data sent to AI (ensure no PII)
- [ ] Add input validation/sanitization

## 📋 Quick Fixes Needed

### Priority 1 (Before Launch):
1. Remove debug print statements
2. Move worker URL to config
3. Fix currency hardcoding
4. Add privacy policy

### Priority 2 (Soon After):
5. Better error messages
6. Rate limit feedback
7. Testing

### Priority 3 (Future):
8. Monitoring
9. UX improvements
10. Performance optimization

## 🚀 Deployment Steps

1. **Remove debug code** (print statements)
2. **Configure production worker URL**
3. **Test release build** thoroughly
4. **Add privacy policy** to app
5. **Submit to app stores**
6. **Monitor** for issues

## 📝 Notes

- The AI feature gracefully degrades (falls back to local calculations)
- Rate limiting prevents abuse
- Caching reduces API costs
- Worker is already deployed and working

