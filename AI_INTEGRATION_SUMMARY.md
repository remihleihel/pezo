# AI Integration Summary

## Overview

A secure OpenAI integration has been added to the "Should I Buy It?" feature using a Cloudflare Worker as a serverless relay. The implementation is minimal, isolated, and fails gracefully.

## Files Created

### 1. Cloudflare Worker
- `cloudflare_worker/wrangler.toml` - Worker configuration
- `cloudflare_worker/src/index.js` - Worker implementation
- `cloudflare_worker/README.md` - Setup instructions

### 2. Flutter Service
- `lib/services/ai_should_i_buy_service.dart` - AI service with caching

### 3. Integration
- Modified `lib/screens/should_i_buy_screen.dart` - Minimal changes to hook in AI

## Features

### Security
- ✅ No direct OpenAI calls from Flutter
- ✅ API key stored as Cloudflare Worker secret
- ✅ App header verification (`X-PEZO-APP: pezo_v1`)
- ✅ Client ID-based rate limiting (3 requests/day)

### Rate Limiting
- Uses Cloudflare KV for persistent rate limiting
- 3 requests per day per client ID
- Falls back to in-memory if KV unavailable

### Caching
- Local caching in Flutter using SharedPreferences
- Cache key: SHA-256 hash of (item + price + currency + financial snapshot)
- Cache TTL: 7 days
- Prevents redundant API calls

### Graceful Failure
- Returns `null` on errors (no crashes)
- Falls back to local rule-based decision
- Shows unobtrusive "AI unavailable" message
- 10-second timeout on requests

### UI Integration
- AI decision shown only for borderline cases (score 40-80)
- AI badge with confidence percentage
- AI reasoning bullets (max 3)
- AI suggestion displayed
- Non-blocking: local decision shown immediately, AI updates when ready

## Setup Instructions

### 1. Deploy Cloudflare Worker

See `cloudflare_worker/README.md` for detailed steps:

1. Create KV namespace: `wrangler kv:namespace create "RATE_LIMIT_KV"`
2. Set secret: `wrangler secret put OPENAI_API_KEY`
3. Update `wrangler.toml` with KV namespace IDs
4. Deploy: `wrangler deploy`

### 2. Update Flutter App

In `lib/screens/should_i_buy_screen.dart`, line 71:

```dart
static const String _workerBaseUrl = 'https://your-worker.workers.dev';
```

Replace with your actual worker URL.

### 3. Test

The AI service will automatically:
- Check cache first
- Call worker for borderline decisions
- Display AI insights when available
- Fall back gracefully on errors

## How It Works

1. **User analyzes purchase** → Local rule-based decision computed immediately
2. **If borderline (score 40-80)** → AI service called in background
3. **AI service**:
   - Checks local cache (7-day TTL)
   - If cache miss, calls Cloudflare Worker
   - Worker validates, rate limits, calls OpenAI
   - Response cached locally
4. **UI updates** when AI decision arrives (non-blocking)

## API Response Format

```json
{
  "decision": "BUY" | "WAIT" | "NO",
  "confidence": 0-100,
  "reasoning": ["bullet 1", "bullet 2", "bullet 3"],
  "suggestion": "one short action sentence"
}
```

## Notes

- AI only triggers for borderline cases (score 40-80) to reduce API calls
- Worker uses `gpt-4o-mini` model (cost-effective)
- Temperature set to 0.2 for consistent responses
- Structured JSON output enforced
- All errors are caught and handled gracefully

## Cost Considerations

- Cloudflare Worker: Free tier (100,000 requests/day)
- OpenAI API: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
- With rate limiting (3/day/user) and caching, costs are minimal

