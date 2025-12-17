import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Payload sent to the AI service
class ShouldIBuyPayload {
  final String item;
  final double price;
  final String currency;
  final String category;
  final bool isRecurring;
  final String? frequency;
  final FinancialSnapshot snapshot;

  ShouldIBuyPayload({
    required this.item,
    required this.price,
    required this.currency,
    required this.category,
    this.isRecurring = false,
    this.frequency,
    required this.snapshot,
  });

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'price': price,
      'currency': currency,
      'category': category,
      'isRecurring': isRecurring,
      'frequency': frequency,
      'snapshot': snapshot.toJson(),
    };
  }
}

/// Financial snapshot data
class FinancialSnapshot {
  final double balance;
  final double monthlyIncome;
  final double avgDailySpending;
  final double recurringExpenses;
  final int daysLeftInMonth;
  final double? savingsGoal;
  final double last30DaySpend;
  final double avgMonthlySpend;
  final Map<String, double> categoryTotals;

  FinancialSnapshot({
    required this.balance,
    required this.monthlyIncome,
    required this.avgDailySpending,
    required this.recurringExpenses,
    required this.daysLeftInMonth,
    this.savingsGoal,
    required this.last30DaySpend,
    required this.avgMonthlySpend,
    required this.categoryTotals,
  });

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'monthlyIncome': monthlyIncome,
      'avgDailySpending': avgDailySpending,
      'recurringExpenses': recurringExpenses,
      'daysLeftInMonth': daysLeftInMonth,
      'savingsGoal': savingsGoal,
      'last30DaySpend': last30DaySpend,
      'avgMonthlySpend': avgMonthlySpend,
      'categoryTotals': categoryTotals,
    };
  }
}

/// AI decision response
enum AiDecisionType { buy, wait, no }

class AiDecision {
  final AiDecisionType decision;
  final int confidence; // 0-100
  final List<String> reasoning; // max 3 bullets
  final String suggestion;

  AiDecision({
    required this.decision,
    required this.confidence,
    required this.reasoning,
    required this.suggestion,
  });

  factory AiDecision.fromJson(Map<String, dynamic> json) {
    // Parse decision string to enum
    AiDecisionType decisionType;
    final decisionStr = (json['decision'] as String? ?? '').toUpperCase();
    switch (decisionStr) {
      case 'BUY':
        decisionType = AiDecisionType.buy;
        break;
      case 'WAIT':
        decisionType = AiDecisionType.wait;
        break;
      case 'NO':
        decisionType = AiDecisionType.no;
        break;
      default:
        decisionType = AiDecisionType.wait;
    }

    // Validate and clamp confidence
    int confidence = (json['confidence'] as num? ?? 50).toInt();
    confidence = confidence.clamp(0, 100);

    // Ensure reasoning is a list of strings (max 3)
    List<String> reasoning = [];
    if (json['reasoning'] is List) {
      reasoning = (json['reasoning'] as List)
          .map((e) => e.toString())
          .take(3)
          .toList();
    }

    // Ensure suggestion is a string
    String suggestion = json['suggestion']?.toString() ?? 'Consider your financial situation carefully.';

    return AiDecision(
      decision: decisionType,
      confidence: confidence,
      reasoning: reasoning,
      suggestion: suggestion,
    );
  }
}

/// Service for AI-powered purchase decisions
class AiShouldIBuyService {
  final String workerBaseUrl;
  static const String _clientIdKey = 'pezo_ai_client_id';
  static const String _cachePrefix = 'pezo_ai_cache_';
  static const int _cacheTtlDays = 7;
  static const Duration _requestTimeout = Duration(seconds: 10);

  String? _clientId;

  AiShouldIBuyService({required this.workerBaseUrl});

  /// Get or generate client ID
  Future<String> _getClientId() async {
    if (_clientId != null) return _clientId!;

    final prefs = await SharedPreferences.getInstance();
    _clientId = prefs.getString(_clientIdKey);

    if (_clientId == null || _clientId!.isEmpty) {
      // Generate a UUID-like string
      _clientId = _generateClientId();
      await prefs.setString(_clientIdKey, _clientId!);
    }

    return _clientId!;
  }

  /// Generate a simple client ID (UUID-like)
  String _generateClientId() {
    // Generate a UUID-like string: 8-4-4-4-12 format
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final micros = now.microsecondsSinceEpoch;
    
    // Convert to hex and ensure proper length
    String toHex(int value, int length) {
      return value.toRadixString(16).padLeft(length, '0').substring(0, length);
    }
    
    final part1 = toHex(timestamp, 8);
    final part2 = toHex(micros % 0xFFFF, 4);
    final part3 = toHex((timestamp ~/ 1000) % 0xFFFF, 4);
    final part4 = toHex((micros ~/ 1000) % 0xFFFF, 4);
    final part5 = toHex((timestamp * micros) % 0xFFFFFFFFFFFF, 12);
    
    return '$part1-$part2-$part3-$part4-$part5';
  }

  /// Generate cache key from payload
  String _generateCacheKey(ShouldIBuyPayload payload) {
    // Create canonical JSON string for hashing
    final canonical = jsonEncode({
      'item': payload.item.toLowerCase().trim(),
      'price': payload.price.toStringAsFixed(2),
      'currency': payload.currency,
      'category': payload.category,
      'isRecurring': payload.isRecurring,
      'frequency': payload.frequency,
      'snapshot': {
        'balance': payload.snapshot.balance.toStringAsFixed(2),
        'monthlyIncome': payload.snapshot.monthlyIncome.toStringAsFixed(2),
        'avgDailySpending': payload.snapshot.avgDailySpending.toStringAsFixed(2),
        'recurringExpenses': payload.snapshot.recurringExpenses.toStringAsFixed(2),
        'daysLeftInMonth': payload.snapshot.daysLeftInMonth,
        'savingsGoal': payload.snapshot.savingsGoal?.toStringAsFixed(2),
        'last30DaySpend': payload.snapshot.last30DaySpend.toStringAsFixed(2),
        'avgMonthlySpend': payload.snapshot.avgMonthlySpend.toStringAsFixed(2),
        'categoryTotals': payload.snapshot.categoryTotals.map(
          (k, v) => MapEntry(k, v.toStringAsFixed(2)),
        ),
      },
    });

    // Hash using SHA-256
    final bytes = utf8.encode(canonical);
    final hash = sha256.convert(bytes);
    return '${_cachePrefix}${hash.toString()}';
  }

  /// Get cached decision if available and not expired
  Future<AiDecision?> _getCachedDecision(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);

      if (cachedData == null) return null;

      final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      final age = DateTime.now().difference(cachedAt);

      // Check if cache is expired (7 days)
      if (age.inDays >= _cacheTtlDays) {
        await prefs.remove(cacheKey);
        return null;
      }

      // Return cached decision
      return AiDecision.fromJson(decoded['decision'] as Map<String, dynamic>);
    } catch (e) {
      print('Error reading cache: $e');
      return null;
    }
  }

  /// Cache a decision
  Future<void> _cacheDecision(String cacheKey, AiDecision decision) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'cachedAt': DateTime.now().toIso8601String(),
        'decision': {
          'decision': decision.decision.name.toUpperCase(),
          'confidence': decision.confidence,
          'reasoning': decision.reasoning,
          'suggestion': decision.suggestion,
        },
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching decision: $e');
    }
  }

  /// Get AI decision for a purchase
  /// Returns null if service is unavailable or fails
  Future<AiDecision?> getAiDecision(ShouldIBuyPayload payload) async {
    try {
      print('AI Service: Getting decision for ${payload.item} (${payload.price} ${payload.currency})');
      // Check cache first
      final cacheKey = _generateCacheKey(payload);
      final cached = await _getCachedDecision(cacheKey);
      if (cached != null) {
        print('AI decision retrieved from cache');
        return cached;
      }
      
      print('AI Service: Cache miss, calling worker at $workerBaseUrl');

      // Get client ID
      final clientId = await _getClientId();

      // Build request
      final url = Uri.parse('$workerBaseUrl/should-i-buy');
      print('AI Service: POST to $url');
      print('AI Service: Headers - X-PEZO-APP: pezo_v1, X-CLIENT-ID: $clientId');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'X-PEZO-APP': 'pezo_v1',
              'X-CLIENT-ID': clientId,
            },
            body: jsonEncode(payload.toJson()),
          )
          .timeout(_requestTimeout);
      
      print('AI Service: Response status ${response.statusCode}');

      // Handle errors
      if (response.statusCode != 200) {
        print('AI service error: ${response.statusCode} - ${response.body}');
        return null;
      }

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      print('AI Service: Response data: $responseData');
      final decision = AiDecision.fromJson(responseData);
      print('AI Service: Parsed decision: ${decision.decision}, confidence: ${decision.confidence}');

      // Cache the decision
      await _cacheDecision(cacheKey, decision);

      return decision;
    } catch (e) {
      print('Error getting AI decision: $e');
      return null;
    }
  }
}

