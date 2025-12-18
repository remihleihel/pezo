# Deploy Worker via Cloudflare Dashboard

## Step 1: Create the Worker Application

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select your account
3. Click **Workers & Pages** in the left sidebar
4. Click **Create application**
5. Click **Create Worker** (or "Deploy from Wrangler" if you see it)
6. Name it: `pezo-ai-worker`
7. Click **Deploy**

## Step 2: Add Your Code

1. After deployment, click on your worker (`pezo-ai-worker`)
2. Go to the **Settings** tab
3. Scroll down to **Quick Edit** or click **Edit code**
4. Delete the default code
5. Copy and paste the contents from `src/index.js` into the editor
6. Click **Save and deploy**

## Step 3: Add KV Namespace Binding

1. Still in your worker's **Settings** tab
2. Scroll to **Variables** section
3. Find **KV Namespace Bindings**
4. Click **Add binding**
5. Set:
   - **Variable name**: `RATE_LIMIT_KV`
   - **KV namespace**: Select your existing `RATE_LIMIT_KV` namespace (or create new)
6. Click **Save**

## Step 4: Add OpenAI API Key Secret

1. In the same **Settings** → **Variables** section
2. Scroll to **Secrets** (or **Environment Variables**)
3. Click **Add secret** or **Encrypt**
4. Set:
   - **Variable name**: `OPENAI_API_KEY`
   - **Value**: Paste your OpenAI API key
5. Click **Encrypt** or **Save**

## Step 5: Get Your Worker URL

1. Go back to the **Overview** tab of your worker
2. You'll see your worker URL, something like:
   ```
   https://pezo-ai-worker.your-username.workers.dev
   ```
3. Copy this URL

## Step 6: Update Flutter App

In `lib/screens/should_i_buy_screen.dart`, line 71, update:

```dart
static const String _workerBaseUrl = 'https://pezo-ai-worker.your-username.workers.dev';
```

Replace with your actual worker URL from Step 5.

## Testing

Test your worker endpoint:

```bash
curl -X POST https://pezo-ai-worker.your-username.workers.dev/should-i-buy \
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

## Notes

- The dashboard editor is great for quick edits
- For production, consider using Wrangler CLI for version control
- Secrets are encrypted and never exposed to the client
- KV namespace must be created first (you already did this)


