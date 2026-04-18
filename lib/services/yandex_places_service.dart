import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../config/yandex_places_config.dart';
import '../models/place_item.dart';

class YandexPlacesService {
  YandexPlacesService._();
  static final YandexPlacesService _instance = YandexPlacesService._();
  factory YandexPlacesService() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://catalog.api.2gis.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Лимит 2GIS Catalog для параметра `page_size` в `/3.0/items`.
  static const int _catalogMaxPageSize = 10;

  /// Поля каталога: адрес, отзывы, фото (`external_content`, `ads`) — при отсутствии прав на часть полей 2GIS просто не вернёт блок.
  static const String _itemFields =
      'items.point,items.address,items.rubrics,items.reviews,items.contact_groups,items.schedule,'
      'items.external_content,items.ads,items.flags,items.description,items.full_name,items.address_name';

  static const Set<String> _directPhotoKeys = {
    'main_photo_url',
    'preview_url',
    'thumbnail_url',
    'photo_url',
    'image_url',
    'photo',
  };

  /// Ищет ближайшие заведения (кафе/рестораны) вокруг координат.
  ///
  /// Сейчас используется 2GIS Catalog API:
  /// https://catalog.api.2gis.com/3.0/items?q=...&type=branch&point=lon,lat&radius=...
  /// Параметр [results] ограничен сверху [_catalogMaxPageSize] (требование API).
  Future<List<PlaceItem>> searchNearby({
    required double lat,
    required double lng,
    String query = '',
    int results = _catalogMaxPageSize,
    int radiusMeters = 3000,
  }) async {
    if (!isYandexPlacesConfigured) {
      throw Exception('Не задан API key в lib/config/yandex_places_config.dart');
    }

    final q = query.trim().isEmpty ? 'кафе ресторан' : query.trim();
    _ensureValidGeo(lat, lng);

    final resp = await _dio.get<Map<String, dynamic>>(
      '/3.0/items',
      queryParameters: {
        'key': yandexPlacesApiKey.trim(),
        'q': q,
        'locale': 'ru_RU',
        'type': 'branch',
        'point': '$lng,$lat',
        'location': '$lng,$lat',
        'radius': radiusMeters.clamp(100, 40000),
        'sort': 'distance',
        'page_size': results.clamp(1, _catalogMaxPageSize),
        'fields': _itemFields,
      },
    );

    final data = resp.data ?? const <String, dynamic>{};
    _throwIfCatalogMetaError(data);
    final result = data['result'];
    final items = (result is Map) ? result['items'] : null;
    if (items is! List) return const [];

    final out = <PlaceItem>[];
    for (final raw in items) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final place = _placeFromItemMap(map, userLat: lat, userLng: lng);
      if (place != null) out.add(place);
    }

    out.sort((a, b) => (a.distanceMeters ?? 1e18).compareTo(b.distanceMeters ?? 1e18));
    return out;
  }

  /// Подгружает карточку по id (для экрана деталей: фото, описание, если поиск их не вернул).
  Future<PlaceItem?> fetchPlaceById(String branchId) async {
    final id = branchId.trim();
    if (id.isEmpty) return null;
    if (!isYandexPlacesConfigured) {
      throw Exception('Не задан API key в lib/config/yandex_places_config.dart');
    }

    final resp = await _dio.get<Map<String, dynamic>>(
      '/3.0/items/byid',
      queryParameters: {
        'key': yandexPlacesApiKey.trim(),
        'id': id,
        'locale': 'ru_RU',
        'fields': _itemFields,
      },
    );

    final data = resp.data ?? const <String, dynamic>{};
    _throwIfCatalogMetaError(data);
    final result = data['result'];
    final items = (result is Map) ? result['items'] : null;
    if (items is! List || items.isEmpty) return null;
    final raw = items.first;
    if (raw is! Map) return null;
    return _placeFromItemMap(Map<String, dynamic>.from(raw), userLat: null, userLng: null);
  }

  static PlaceItem? _placeFromItemMap(
    Map<String, dynamic> raw, {
    required double? userLat,
    required double? userLng,
  }) {
    final id = raw['id']?.toString() ?? '';
    final name = raw['name']?.toString() ?? '';
    if (name.trim().isEmpty) return null;

    final point = raw['point'];
    final plng = (point is Map) ? _toDouble(point['lon']) : null;
    final plat = (point is Map) ? _toDouble(point['lat']) : null;
    if (plng == null || plat == null) return null;

    String? address = raw['address_name']?.toString();
    if (address == null || address.isEmpty) {
      final addressObj = raw['address'];
      if (addressObj is Map) {
        final am = Map<String, dynamic>.from(addressObj);
        address = am['name']?.toString() ?? am['address_name']?.toString() ?? am['building_name']?.toString();
      }
    }
    address ??= raw['full_name']?.toString();

    final categories = <String>[];
    final rubrics = raw['rubrics'];
    if (rubrics is List) {
      for (final r in rubrics) {
        final n = (r is Map ? r['name'] : null)?.toString();
        if (n != null && n.isNotEmpty) categories.add(n);
      }
    }

    double? rating;
    final reviews = raw['reviews'];
    if (reviews is Map) {
      rating = _toDouble(reviews['general_rating'] ?? reviews['rating']);
    }

    String? phones;
    final groups = raw['contact_groups'];
    if (groups is List) {
      final values = <String>[];
      for (final g in groups) {
        final contacts = (g is Map) ? g['contacts'] : null;
        if (contacts is! List) continue;
        for (final c in contacts) {
          if (c is! Map) continue;
          final v = c['value']?.toString();
          if (v != null && v.isNotEmpty) values.add(v);
        }
      }
      if (values.isNotEmpty) phones = values.join(', ');
    }

    String? hours;
    final schedule = raw['schedule'];
    if (schedule is Map) {
      final sm = Map<String, dynamic>.from(schedule);
      hours = sm['text']?.toString();
      hours ??= _scheduleMapToBriefText(sm);
    }

    double? dist;
    if (userLat != null && userLng != null) {
      dist = _toDouble(raw['distance']) ?? Geolocator.distanceBetween(userLat, userLng, plat, plng);
    }

    final photoUrls = _extractPhotoUrls(raw);
    final description = _parseDescription(raw);

    return PlaceItem(
      id: id.isEmpty ? '$plat,$plng' : id,
      name: name,
      address: address,
      rating: rating,
      url: null,
      phones: phones,
      hours: hours,
      categories: categories,
      lat: plat,
      lng: plng,
      distanceMeters: dist,
      photoUrls: photoUrls,
      description: description,
    );
  }

  static String? _parseDescription(Map<String, dynamic> raw) {
    final d = raw['description'];
    if (d is String) {
      final t = d.trim();
      return t.isEmpty ? null : t;
    }
    if (d is Map) {
      final m = Map<String, dynamic>.from(d);
      final text = m['text']?.toString() ?? m['body']?.toString();
      if (text != null && text.trim().isNotEmpty) return text.trim();
    }
    return null;
  }

  static List<String> _extractPhotoUrls(Map<String, dynamic> raw) {
    final seen = <String>{};
    final out = <String>[];

    void add(String? u) {
      if (u == null) return;
      final t = u.trim();
      if (t.isEmpty || !t.startsWith('http')) return;
      if (seen.add(t)) out.add(t);
    }

    void walkMap(Map<dynamic, dynamic> map) {
      for (final e in map.entries) {
        final k = e.key.toString().toLowerCase();
        final v = e.value;
        if (v is String) {
          if (_directPhotoKeys.contains(k)) {
            add(v);
          } else if (k == 'url' && _looksLikeImageUrl(v)) {
            add(v);
          } else if (k == 'src' && _looksLikeImageUrl(v)) {
            add(v);
          }
        } else if (v is Map) {
          walkMap(v);
        } else if (v is List) {
          for (final x in v) {
            if (x is Map) walkMap(x);
          }
        }
      }
    }

    void walkTop(dynamic node) {
      if (node is Map) {
        walkMap(node);
      } else if (node is List) {
        for (final x in node) {
          if (x is Map) walkMap(x);
        }
      }
    }

    walkTop(raw['external_content']);
    walkTop(raw['ads']);
    walkTop(raw['photos']);
    walkTop(raw['images']);
    walkTop(raw['media']);
    return out;
  }

  static bool _looksLikeImageUrl(String v) {
    final lower = v.toLowerCase();
    if (lower.contains('photo.2gis')) return true;
    if (lower.contains('flamp.ru') && (lower.contains('.jpg') || lower.contains('.jpeg') || lower.contains('.png'))) {
      return true;
    }
    if (RegExp(r'\.(jpe?g|png|webp)(\?|$)', caseSensitive: false).hasMatch(lower)) return true;
    return false;
  }

  static double? _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  /// 2GIS часто отвечает HTTP 200 с `meta.code` 404/403 — Dio не считает это ошибкой.
  static void _throwIfCatalogMetaError(Map<String, dynamic> data) {
    final meta = data['meta'];
    if (meta is! Map) return;
    final codeRaw = meta['code'];
    final code = codeRaw is int ? codeRaw : (codeRaw is num ? codeRaw.toInt() : null);
    if (code == null || code == 200) return;

    final err = meta['error'];
    final apiMsg = (err is Map) ? err['message']?.toString().trim() : null;
    if (code == 404) {
      throw Exception(
        'По текущим координатам или запросу ничего не найдено в каталоге 2GIS. '
        'Проверьте геолокацию и поиск.${apiMsg != null && apiMsg.isNotEmpty ? ' ($apiMsg)' : ''}',
      );
    }
    if (code == 403) {
      throw Exception(
        'Доступ к каталогу 2GIS запрещён (403). Проверьте ключ PLACES_API_KEY и тариф.'
        '${apiMsg != null && apiMsg.isNotEmpty ? ' $apiMsg' : ''}',
      );
    }
    throw Exception(apiMsg != null && apiMsg.isNotEmpty ? apiMsg : 'Ошибка каталога 2GIS (код $code)');
  }

  static void _ensureValidGeo(double lat, double lng) {
    if (lat.abs() < 1e-7 && lng.abs() < 1e-7) {
      throw Exception(
        'Координаты не заданы (0,0). Включите геолокацию или задайте город в профиле, чтобы искать места рядом.',
      );
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw Exception('Некорректные координаты в профиле. Обновите геолокацию.');
    }
  }

  /// Расписание 2GIS: дни недели → `working_hours`.
  static String? _scheduleMapToBriefText(Map<String, dynamic> schedule) {
    const order = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const ru = {'Mon': 'Пн', 'Tue': 'Вт', 'Wed': 'Ср', 'Thu': 'Чт', 'Fri': 'Пт', 'Sat': 'Сб', 'Sun': 'Вс'};
    final parts = <String>[];
    for (final day in order) {
      final dayMap = schedule[day];
      if (dayMap is! Map) continue;
      final wh = dayMap['working_hours'];
      if (wh is! List || wh.isEmpty) continue;
      final first = wh.first;
      if (first is! Map) continue;
      final from = first['from']?.toString();
      final to = first['to']?.toString();
      if (from == null || to == null) continue;
      parts.add('${ru[day] ?? day} $from–$to');
      if (parts.length >= 3) break;
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }
}
