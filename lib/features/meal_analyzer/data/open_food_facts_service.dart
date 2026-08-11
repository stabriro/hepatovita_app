import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app/config/api_constants.dart';

class MealNutrients {
  final String displayName;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? fatPer100g;
  final double? saturatedFatPer100g;
  final double? sugarPer100g;
  final double? sodiumMgPer100g;
  final int? additivesCount;

  const MealNutrients({
    required this.displayName,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.fatPer100g,
    this.saturatedFatPer100g,
    this.sugarPer100g,
    this.sodiumMgPer100g,
    this.additivesCount,
  });
}

class OpenFoodFactsService {
  static const _cacheTtl = Duration(minutes: 30);
  static const _maxCacheEntries = 40;

  final LinkedHashMap<String, _CachedMealSearch> _recentSearchCache =
      LinkedHashMap<String, _CachedMealSearch>();

  Future<MealNutrients?> searchMeal(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = _normalizeQuery(trimmed);
    final cached = _getFreshCache(normalized);
    if (cached != null) {
      return cached;
    }

    final mapped = await _searchMealRemote(trimmed);
    _saveCache(normalized, mapped);
    return mapped;
  }

  Future<MealNutrients?> searchByBarcode(String barcode) async {
    final normalizedBarcode = barcode.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalizedBarcode.length < 8) {
      return null;
    }

    final cacheKey = 'barcode:$normalizedBarcode';
    final cached = _getFreshCache(cacheKey);
    if (cached != null) {
      return cached;
    }

    final uri = Uri.parse(
      '${ApiConstants.openFoodFactsProductUrlPrefix}/$normalizedBarcode.json',
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': ApiConstants.openFoodFactsUserAgent,
      },
    );

    if (response.statusCode != 200) {
      _saveCache(cacheKey, null);
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      _saveCache(cacheKey, null);
      return null;
    }

    final status = decoded['status'];
    if (status is! num || status.toInt() != 1) {
      _saveCache(cacheKey, null);
      return null;
    }

    final product = decoded['product'];
    if (product is! Map<String, dynamic>) {
      _saveCache(cacheKey, null);
      return null;
    }

    final mapped = _mapProduct(product);
    _saveCache(cacheKey, mapped);
    return mapped;
  }

  Future<MealNutrients?> _searchMealRemote(String trimmed) async {
    final uri = Uri.parse(ApiConstants.openFoodFactsSearchUrl).replace(
      queryParameters: {
        'search_terms': trimmed,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '12',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': ApiConstants.openFoodFactsUserAgent,
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final products = decoded['products'];
    if (products is! List) {
      return null;
    }

    for (final item in products) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final mapped = _mapProduct(item);
      if (mapped != null) {
        return mapped;
      }
    }

    return null;
  }

  MealNutrients? _getFreshCache(String key) {
    final cached = _recentSearchCache[key];
    if (cached != null) {
      final isFresh = DateTime.now().difference(cached.cachedAt) <= _cacheTtl;
      if (isFresh) {
        _touchCacheEntry(key, cached);
        return cached.result;
      }
      _recentSearchCache.remove(key);
    }
    return null;
  }

  String _normalizeQuery(String query) {
    return query.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _touchCacheEntry(String key, _CachedMealSearch value) {
    _recentSearchCache.remove(key);
    _recentSearchCache[key] = value;
  }

  void _saveCache(String key, MealNutrients? value) {
    _recentSearchCache.remove(key);
    _recentSearchCache[key] = _CachedMealSearch(
      result: value,
      cachedAt: DateTime.now(),
    );

    while (_recentSearchCache.length > _maxCacheEntries) {
      _recentSearchCache.remove(_recentSearchCache.keys.first);
    }
  }

  MealNutrients? _mapProduct(Map<String, dynamic> product) {
    final nutrimentsRaw = product['nutriments'];
    if (nutrimentsRaw is! Map<String, dynamic>) {
      return null;
    }

    final calories = _toDouble(
      nutrimentsRaw['energy-kcal_100g'] ?? nutrimentsRaw['energy-kcal'],
    );
    final protein = _toDouble(nutrimentsRaw['proteins_100g']);
    final fat = _toDouble(nutrimentsRaw['fat_100g']);
    final saturatedFat = _toDouble(nutrimentsRaw['saturated-fat_100g']);
    final sugar = _toDouble(nutrimentsRaw['sugars_100g']);
    final additivesCount = _toInt(product['additives_n']);

    final sodiumFromSodium = _toDouble(nutrimentsRaw['sodium_100g']);
    final salt = _toDouble(nutrimentsRaw['salt_100g']);
    final sodiumFromSalt = salt == null ? null : salt * 1000 * 0.393;
    final sodiumMg =
        sodiumFromSodium != null ? sodiumFromSodium * 1000 : sodiumFromSalt;

    if (calories == null && protein == null && fat == null) {
      return null;
    }

    final name = (product['product_name'] as String?)?.trim();
    return MealNutrients(
      displayName:
          (name == null || name.isEmpty) ? 'Open Food Facts Result' : name,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      fatPer100g: fat,
      saturatedFatPer100g: saturatedFat,
      sugarPer100g: sugar,
      sodiumMgPer100g: sodiumMg,
      additivesCount: additivesCount,
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class _CachedMealSearch {
  final MealNutrients? result;
  final DateTime cachedAt;

  const _CachedMealSearch({
    required this.result,
    required this.cachedAt,
  });
}
