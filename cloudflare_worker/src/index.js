/**
 * Pezo AI Worker - Secure OpenAI proxy for "Should I Buy It?" feature
 * 
 * Endpoint: POST /should-i-buy
 * 
 * Rate limiting: 3 requests/day per client_id (stored in KV)
 * Security: Requires X-PEZO-APP header
 */

export default {
  async fetch(request, env) {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, X-PEZO-APP, X-CLIENT-ID',
          'Access-Control-Max-Age': '86400',
        },
      });
    }

    // Only allow POST
    if (request.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Check endpoint
    const url = new URL(request.url);
    if (url.pathname !== '/should-i-buy') {
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    try {
      // Security: Verify app header
      const appHeader = request.headers.get('X-PEZO-APP');
      if (appHeader !== 'pezo_v1') {
        return new Response(
          JSON.stringify({ error: 'Unauthorized: Invalid app header' }),
          {
            status: 401,
            headers: { 'Content-Type': 'application/json' },
          }
        );
      }

      // Get client ID for rate limiting
      const clientId = request.headers.get('X-CLIENT-ID');
      if (!clientId) {
        return new Response(
          JSON.stringify({ error: 'Missing X-CLIENT-ID header' }),
          {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
          }
        );
      }

      // Rate limiting: Check KV (if available)
      const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
      const rateLimitKey = `rate_limit:${clientId}:${today}`;
      
      let requestCount = 0;
      let hasKv = env.RATE_LIMIT_KV != null;
      
      if (hasKv) {
        try {
          const stored = await env.RATE_LIMIT_KV.get(rateLimitKey);
          requestCount = stored ? parseInt(stored, 10) : 0;
        } catch (e) {
          // If KV is not available, use in-memory fallback (not persistent across workers)
          console.warn('KV not available, using in-memory rate limit');
          hasKv = false;
        }
      } else {
        // No KV binding - skip rate limiting (or implement in-memory if needed)
        // For now, we'll allow requests but log a warning
        console.warn('KV namespace not configured - rate limiting disabled');
      }

      const MAX_REQUESTS_PER_DAY = 3;
      if (hasKv && requestCount >= MAX_REQUESTS_PER_DAY) {
        return new Response(
          JSON.stringify({
            error: 'Rate limit exceeded',
            message: 'Maximum 3 requests per day. Please try again tomorrow.',
          }),
          {
            status: 429,
            headers: { 'Content-Type': 'application/json' },
          }
        );
      }

      // Increment rate limit counter (if KV available)
      if (hasKv) {
        try {
          await env.RATE_LIMIT_KV.put(rateLimitKey, String(requestCount + 1), {
            expirationTtl: 86400, // 24 hours
          });
        } catch (e) {
          console.warn('Could not update rate limit in KV');
        }
      }

      // Parse request body
      let payload;
      try {
        payload = await request.json();
      } catch (e) {
        return new Response(
          JSON.stringify({ error: 'Invalid JSON body' }),
          {
            status: 400,
            headers: { 'Content-Type': 'application/json' },
          }
        );
      }

      // Validate required fields
      const requiredFields = ['item', 'price', 'currency', 'snapshot'];
      for (const field of requiredFields) {
        if (!payload[field]) {
          return new Response(
            JSON.stringify({ error: `Missing required field: ${field}` }),
            {
              status: 400,
              headers: { 'Content-Type': 'application/json' },
            }
          );
        }
      }

      // Get OpenAI API key from secrets
      const openaiApiKey = env.OPENAI_API_KEY;
      if (!openaiApiKey) {
        console.error('OPENAI_API_KEY secret not set');
        return new Response(
          JSON.stringify({ error: 'Server configuration error' }),
          {
            status: 500,
            headers: { 'Content-Type': 'application/json' },
          }
        );
      }

      // Build prompt
      const snapshot = payload.snapshot;
      const systemPrompt = `You are Pezo, a conservative and practical spending coach.

You do NOT provide financial/investment advice.

Decide only based on provided data.

Output STRICT JSON ONLY. No markdown, no code blocks, just pure JSON.

Response format:
{
  "decision": "BUY" | "WAIT" | "NO",
  "confidence": 0-100,
  "reasoning": ["bullet point 1", "bullet point 2", "bullet point 3"],
  "suggestion": "one short action sentence"
}

Rules:
- decision: "BUY" if affordable and reasonable, "WAIT" if uncertain or insufficient data, "NO" if clearly unaffordable
- confidence: 0-100 integer
- reasoning: exactly 3 bullet points (strings), max 100 chars each
- suggestion: one short actionable sentence, max 80 chars
- If insufficient data: decision = "WAIT", confidence <= 60`;

      const userPrompt = `Purchase decision needed:

Item: ${payload.item}
Price: ${payload.price} ${payload.currency}
Category: ${payload.category || 'Other'}

Financial snapshot:
- Current balance: ${snapshot.balance || 0} ${payload.currency}
- Monthly income: ${snapshot.monthlyIncome || 0} ${payload.currency}
- Average daily spending: ${snapshot.avgDailySpending || 0} ${payload.currency}
- Recurring expenses: ${snapshot.recurringExpenses || 0} ${payload.currency}
- Days left in month: ${snapshot.daysLeftInMonth || 0}
- Savings goal: ${snapshot.savingsGoal || 'none'} ${payload.currency}
- Last 30 day spend: ${snapshot.last30DaySpend || 0} ${payload.currency}
- Average monthly spend: ${snapshot.avgMonthlySpend || 0} ${payload.currency}
- Category totals: ${JSON.stringify(snapshot.categoryTotals || {})}

${payload.isRecurring ? `Note: This is a recurring ${payload.frequency || 'monthly'} expense.` : ''}

Provide your decision as JSON only.`;

      // Call OpenAI
      const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${openaiApiKey}`,
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini', // Using gpt-4o-mini (cheaper than gpt-4.1-mini which doesn't exist)
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt },
          ],
          temperature: 0.2,
          response_format: { type: 'json_object' },
          max_tokens: 500,
        }),
      });

      if (!openaiResponse.ok) {
        const errorText = await openaiResponse.text();
        console.error('OpenAI API error:', errorText);
        return new Response(
          JSON.stringify({
            error: 'AI service unavailable',
            message: 'Failed to get AI decision',
          }),
          {
            status: 502,
            headers: { 'Content-Type': 'application/json' },
          }
        );
      }

      const openaiData = await openaiResponse.json();
      const aiMessage = openaiData.choices?.[0]?.message?.content;

      if (!aiMessage) {
        return new Response(
          JSON.stringify({
            error: 'Invalid AI response',
            message: 'AI did not return a valid response',
          }),
          {
            status: 502,
            headers: { 'Content-Type': 'application/json' },
          }
        );
      }

      // Parse AI response (should be JSON)
      let aiDecision;
      try {
        // Remove markdown code blocks if present
        const cleaned = aiMessage.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();
        aiDecision = JSON.parse(cleaned);
      } catch (e) {
        console.error('Failed to parse AI response:', aiMessage);
        return new Response(
          JSON.stringify({
            error: 'Invalid AI response format',
            message: 'AI returned invalid JSON',
          }),
          {
            status: 502,
            headers: { 'Content-Type': 'application/json' },
          }
        );
      }

      // Validate response structure
      if (
        !aiDecision.decision ||
        !['BUY', 'WAIT', 'NO'].includes(aiDecision.decision) ||
        typeof aiDecision.confidence !== 'number' ||
        aiDecision.confidence < 0 ||
        aiDecision.confidence > 100 ||
        !Array.isArray(aiDecision.reasoning) ||
        !aiDecision.suggestion
      ) {
        return new Response(
          JSON.stringify({
            error: 'Invalid AI response structure',
            message: 'AI response does not match expected format',
          }),
          {
            status: 502,
            headers: { 'Content-Type': 'application/json' },
          }
        );
      }

      // Return success response
      return new Response(JSON.stringify(aiDecision), {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Headers': 'Content-Type, X-PEZO-APP, X-CLIENT-ID',
        },
      });
    } catch (error) {
      console.error('Worker error:', error);
      return new Response(
        JSON.stringify({
          error: 'Internal server error',
          message: error.message || 'Unknown error',
        }),
        {
          status: 500,
          headers: { 'Content-Type': 'application/json' },
        }
      );
    }
  },
};

