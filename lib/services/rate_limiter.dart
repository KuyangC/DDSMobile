import 'dart:collection';

/// Centralized rate limiting service for notifications and API calls
/// Prevents spam and resource exhaustion
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  // Track request history per key
  final Map<String, Queue<DateTime>> _requestHistory = {};

  // Default rate limits
  static const int _defaultMaxPerMinute = 30;
  static const int _defaultMaxPerSecond = 5;
  static const int _defaultMinIntervalMs = 2000;

  // Custom limits for different types
  static const Map<String, RateLimit> _customLimits = {
    'NOTIFICATION': RateLimit(maxPerMinute: 60, maxPerSecond: 10, minIntervalMs: 1000),
    'FCM_SEND': RateLimit(maxPerMinute: 30, maxPerSecond: 2, minIntervalMs: 5000),
    'AUDIO_PLAY': RateLimit(maxPerMinute: 20, maxPerSecond: 1, minIntervalMs: 3000),
    'API_CALL': RateLimit(maxPerMinute: 100, maxPerSecond: 10, minIntervalMs: 100),
  };

  /// Check if request should be allowed based on rate limiting
  bool shouldAllowRequest(String requestId, {RateLimit? customLimit}) {
    final now = DateTime.now();
    final limit = customLimit ?? _customLimits[requestId] ??
                  RateLimit(
                    maxPerMinute: _defaultMaxPerMinute,
                    maxPerSecond: _defaultMaxPerSecond,
                    minIntervalMs: _defaultMinIntervalMs
                  );

    // Initialize queue if it doesn't exist
    _requestHistory.putIfAbsent(requestId, () => Queue<DateTime>());

    final requests = _requestHistory[requestId]!;

    // Clean old requests (older than 1 minute)
    while (requests.isNotEmpty &&
           now.difference(requests.first).inMinutes > 0) {
      requests.removeFirst();
    }

    // Check per-minute limit
    if (requests.length >= limit.maxPerMinute) {
      return false;
    }

    // Check per-second limit
    final recentSecond = requests.where((time) =>
        now.difference(time).inSeconds == 0);
    if (recentSecond.length >= limit.maxPerSecond) {
      return false;
    }

    // Check minimum interval between requests
    if (requests.isNotEmpty) {
      final lastRequest = requests.last;
      if (now.difference(lastRequest).inMilliseconds < limit.minIntervalMs) {
        return false;
      }
    }

    // Allow request and record it
    requests.addLast(now);
    return true;
  }

  /// Check if request should be rate limited (opposite of shouldAllowRequest)
  bool shouldRateLimit(String requestId, {RateLimit? customLimit}) {
    return !shouldAllowRequest(requestId, customLimit: customLimit);
  }

  /// Get remaining requests for a given ID
  int getRemainingRequests(String requestId, {RateLimit? customLimit}) {
    final limit = customLimit ?? _customLimits[requestId] ??
                  RateLimit(
                    maxPerMinute: _defaultMaxPerMinute,
                    maxPerSecond: _defaultMaxPerSecond,
                    minIntervalMs: _defaultMinIntervalMs
                  );

    final requests = _requestHistory[requestId] ?? Queue<DateTime>();
    final now = DateTime.now();

    // Count requests in the last minute
    final recentMinute = requests.where((time) =>
        now.difference(time).inMinutes < 1).length;

    return (limit.maxPerMinute - recentMinute).clamp(0, limit.maxPerMinute);
  }

  /// Get time until next request is allowed
  Duration getTimeUntilNextAllowed(String requestId, {RateLimit? customLimit}) {
    final limit = customLimit ?? _customLimits[requestId] ??
                  RateLimit(
                    maxPerMinute: _defaultMaxPerMinute,
                    maxPerSecond: _defaultMaxPerSecond,
                    minIntervalMs: _defaultMinIntervalMs
                  );

    final requests = _requestHistory[requestId];
    if (requests == null || requests.isEmpty) {
      return Duration.zero;
    }

    final now = DateTime.now();
    final lastRequest = requests.last;
    final timeSinceLast = now.difference(lastRequest);
    final minInterval = Duration(milliseconds: limit.minIntervalMs);

    if (timeSinceLast >= minInterval) {
      return Duration.zero;
    }

    return minInterval - timeSinceLast;
  }

  /// Reset rate limiting for a specific ID
  void reset(String requestId) {
    _requestHistory.remove(requestId);
  }

  /// Reset all rate limiting
  void resetAll() {
    _requestHistory.clear();
  }

  /// Get statistics for debugging
  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};
    for (final entry in _requestHistory.entries) {
      stats[entry.key] = {
        'total_requests': entry.value.length,
        'last_request': entry.value.isNotEmpty ? entry.value.last.toIso8601String() : null,
      };
    }
    return stats;
  }
}

/// Rate limit configuration
class RateLimit {
  final int maxPerMinute;
  final int maxPerSecond;
  final int minIntervalMs;

  const RateLimit({
    required this.maxPerMinute,
    required this.maxPerSecond,
    required this.minIntervalMs,
  });
}