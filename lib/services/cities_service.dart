import 'dart:convert';
import 'package:flutter/services.dart';

/// Сервис загрузки списка городов России из assets. Кеширует результат в памяти.
class CitiesService {
  CitiesService._();
  static final CitiesService _instance = CitiesService._();
  factory CitiesService() => _instance;

  List<String>? _cachedCityNames;

  /// Список названий городов на русском (city_ru). Загружается из assets один раз.
  Future<List<String>> getCityNames() async {
    if (_cachedCityNames != null) return _cachedCityNames!;
    try {
      final jsonStr = await rootBundle.loadString('assets/json/cities_ru.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final names = <String>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          final cityRu = e['city_ru']?.toString();
          if (cityRu != null && cityRu.trim().isNotEmpty) {
            names.add(cityRu.trim());
          }
        }
      }
      names.sort((a, b) => a.compareTo(b));
      _cachedCityNames = names;
      return names;
    } catch (_) {
      _cachedCityNames = [];
      return [];
    }
  }

  /// Сбросить кеш (например для тестов).
  void clearCache() {
    _cachedCityNames = null;
  }
}
