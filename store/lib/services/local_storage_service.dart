import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/constants/app_constants.dart';

class LocalStorageService {
  static SharedPreferences? _preferences;
  static const String _recentSearchesKey = 'recent_searches';
  static const String _inventoryTrendKeyPrefix = 'inventory_trend_snapshots';
  static const String _inventoryAuditLogKey = 'inventory_audit_logs';
  
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }
  
  static Future<void> saveToken(String token) async {
    if (_preferences == null) {
      await init();
    }
    await _preferences!.setString(AppConstants.tokenKey, token);
  }
  
  static String? getToken() {
    return _preferences?.getString(AppConstants.tokenKey);
  }
  
  static Future<void> saveUser(Map<String, dynamic> user) async {
    if (_preferences == null) {
      await init();
    }
    await _preferences!.setString(AppConstants.userKey, json.encode(user));
  }
  
  static Map<String, dynamic>? getUser() {
    final userString = _preferences?.getString(AppConstants.userKey);
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }
  
  static Future<void> setOnboardingCompleted() async {
    if (_preferences == null) {
      await init();
    }
    await _preferences!.setBool(AppConstants.onboardingKey, true);
  }
  
  static bool isOnboardingCompleted() {
    return _preferences?.getBool(AppConstants.onboardingKey) ?? false;
  }
  
  static Future<void> saveThemeMode(String themeMode) async {
    if (_preferences == null) {
      await init();
    }
    await _preferences!.setString(AppConstants.themeKey, themeMode);
  }
  
  static String? getThemeMode() {
    return _preferences?.getString(AppConstants.themeKey);
  }
  
  static Future<void> clearAll() async {
    if (_preferences == null) {
      await init();
    }
    await _preferences!.clear();
  }

  static List<String> getRecentSearches() {
    return _preferences?.getStringList(_recentSearchesKey) ?? [];
  }

  static Future<void> saveRecentSearch(String query) async {
    if (_preferences == null) {
      await init();
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final existing = getRecentSearches();
    existing.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    existing.insert(0, trimmed);

    final limited = existing.take(8).toList();
    await _preferences!.setStringList(_recentSearchesKey, limited);
  }

  static Future<void> clearRecentSearches() async {
    if (_preferences == null) {
      await init();
    }
    await _preferences!.remove(_recentSearchesKey);
  }

  static String _inventoryTrendKeyForThreshold(int threshold) {
    return '$_inventoryTrendKeyPrefix-$threshold';
  }

  static List<Map<String, dynamic>> getInventoryTrendSnapshots({int threshold = 5}) {
    final raw = _preferences?.getString(_inventoryTrendKeyForThreshold(threshold));
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final parsed = json.decode(raw);
      if (parsed is! List) {
        return [];
      }

      return parsed
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addInventoryTrendSnapshot({
    required int lowStockCount,
    required int outOfStockCount,
    required int inventoryUnits,
    int threshold = 5,
  }) async {
    if (_preferences == null) {
      await init();
    }

    final existing = getInventoryTrendSnapshots(threshold: threshold);
    final now = DateTime.now();

    final next = {
      't': now.toIso8601String(),
      'low': lowStockCount,
      'out': outOfStockCount,
      'units': inventoryUnits,
    };

    if (existing.isNotEmpty) {
      final last = existing.last;
      final samePoint =
          (last['low'] ?? -1) == lowStockCount &&
          (last['out'] ?? -1) == outOfStockCount &&
          (last['units'] ?? -1) == inventoryUnits;

      if (samePoint) {
        return;
      }
    }

    existing.add(next);
    final limited = existing.length > 14
        ? existing.sublist(existing.length - 14)
        : existing;

    await _preferences!.setString(
      _inventoryTrendKeyForThreshold(threshold),
      json.encode(limited),
    );
  }

  static List<Map<String, dynamic>> getInventoryAuditLogs() {
    final raw = _preferences?.getString(_inventoryAuditLogKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final parsed = json.decode(raw);
      if (parsed is! List) {
        return [];
      }

      return parsed
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addInventoryAuditLog({
    required String action,
    String? category,
    String? productName,
    required int successCount,
    required int failedCount,
    int? affectedProducts,
  }) async {
    if (_preferences == null) {
      await init();
    }

    final existing = getInventoryAuditLogs();
    existing.add({
      't': DateTime.now().toIso8601String(),
      'action': action,
      'category': category,
      'productName': productName,
      'successCount': successCount,
      'failedCount': failedCount,
      'affectedProducts': affectedProducts ?? successCount + failedCount,
    });

    final limited = existing.length > 30
        ? existing.sublist(existing.length - 30)
        : existing;

    await _preferences!.setString(_inventoryAuditLogKey, json.encode(limited));
  }

  static Future<void> clearInventoryAuditLogs() async {
    if (_preferences == null) {
      await init();
    }

    await _preferences!.remove(_inventoryAuditLogKey);
  }
}