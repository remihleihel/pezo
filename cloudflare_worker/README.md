# Pezo AI Worker - Setup Instructions

This Cloudflare Worker securely proxies OpenAI API requests for the "Should I Buy It?" feature.

## Prerequisites

1. Cloudflare account
2. Wrangler CLI installed: `npm install -g wrangler` (or use `npx wrangler`)
3. OpenAI API key

**Important:** Make sure you have the latest version of wrangler:
```bash
npm install -g wrangler@latest
# Or check version
wrangler --version
```

## Setup Steps

### Option A: With KV Namespace (Recommended for Production)

#### 1. Create KV Namespace

```bash
# Update wrangler first if needed
npm install -g wrangler@latest

# Create KV namespace for rate limiting
wrangler kv:namespace create "RATE_LIMIT_KV"
```

**If you get an error**, try:
```bash
# Using npx (always uses latest version)
npx wrangler kv:namespace create "RATE_LIMIT_KV"
```

Copy the `id` from the output and update `wrangler.toml`:

```toml
[[kv_namespaces]]
binding = "RATE_LIMIT_KV"
id = "your-kv-namespace-id-here"
```

**Note:** The ID has already been added to `wrangler.toml` - you're ready to deploy!

### Option B: Without KV (Simpler, In-Memory Rate Limiting)

If you want to skip KV setup for now, the worker will use in-memory rate limiting (not persistent across worker restarts, but works for testing).

**The KV namespace section is already commented out in `wrangler.toml`**, so you can deploy immediately without KV.

The worker code already handles KV being unavailable gracefully.

### Option C: Create KV via Cloudflare Dashboard

**Note:** In the Cloudflare dashboard, you might only see "Create Application" (which creates a Worker). KV namespaces are managed separately.

**To create KV namespace via dashboard:**

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select your account
3. Navigate to **Workers & Pages** (in the left sidebar)
4. Look for **KV** tab at the top, or scroll down to find **KV** section
5. If you see **KV**, click it, then **Create a namespace**
6. If you don't see KV option, you may need to:
   - First deploy your Worker (see Step 3 below)
   - Then go to your Worker's settings → **Variables** → **KV Namespace Bindings** → **Add binding**
   - Or use the command line method (Option A) instead

**Alternative: Use Command Line (Recommended)**

Since the dashboard UI can vary, the command line is more reliable:

```bash
# Update wrangler first
npm install -g wrangler@latest

# Or use npx (no installation needed)
npx wrangler kv:namespace create "RATE_LIMIT_KV"
```

Then copy the ID from the output and update `wrangler.toml` (already done - ID is in the file).

### 2. Set OpenAI API Key Secret

**Required for both options:**

```bash
wrangler secret put OPENAI_API_KEY
```

When prompted, paste your OpenAI API key.

### 3. Deploy Worker

```bash
wrangler deploy
```

### 4. Update Flutter App

In `lib/screens/should_i_buy_screen.dart`, update the `_workerBaseUrl` constant:

```dart
static const String _workerBaseUrl = 'https://your-worker-name.your-subdomain.workers.dev';
```

Replace with your actual worker URL from the deploy output.

## Troubleshooting

### "Unknown arguments: kv:namespace" Error

This means your wrangler version is outdated. Try:

```bash
# Update to latest version
npm install -g wrangler@latest

# Or use npx (no installation needed)
npx wrangler kv:namespace create "RATE_LIMIT_KV"
```

### Skip KV for Now

If you want to test without KV setup, the worker already supports in-memory rate limiting:

1. In `wrangler.toml`, keep the KV namespace section commented out (it's already commented)
2. Deploy normally - the worker will work, just with in-memory rate limiting

### Alternative: Create KV After Deploying Worker

1. Deploy your Worker first (see Step 3 below)
2. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
3. Navigate to **Workers & Pages** → Your Worker (`pezo-ai-worker`)
4. Go to **Settings** → **Variables** → **KV Namespace Bindings**
5. Click **Add binding** → **Create new namespace**
6. Name it: `RATE_LIMIT_KV`
7. Copy the namespace ID shown
8. Update `wrangler.toml` with the ID
9. Redeploy: `wrangler deploy`

## Testing

Test the worker endpoint:

```bash
curl -X POST https://your-worker.workers.dev/should-i-buy \
  -H "Content-Type: application/json" \
  -H "X-PEZO-APP: pezo_v1" \
  -H "X-CLIENT-ID: test-client-123" \
  -d '{
    "item": "Test item",
    "price": 100,
    "currency": "USD",
    "category": "Shopping",
    "snapshot": {
      "balance": 1000,
      "monthlyIncome": 3000,
      "avgDailySpending": 50,
      "recurringExpenses": 500,
      "daysLeftInMonth": 15,
      "savingsGoal": 500,
      "last30DaySpend": 1500,
      "avgMonthlySpend": 1500,
      "categoryTotals": {}
    }
  }'
```

## Rate Limiting

- 3 requests per day per `client_id`
- Rate limit is stored in KV with 24-hour TTL
- Each client gets a unique ID stored in Flutter SharedPreferences

## Security

- Requires `X-PEZO-APP: pezo_v1` header
- Requires `X-CLIENT-ID` header for rate limiting
- OpenAI API key is stored as a Worker secret (never exposed to client)

