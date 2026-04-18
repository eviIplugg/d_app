class PlaceItem {
  final String id;
  final String name;
  final String? address;
  final double? rating;
  final String? url;
  final String? phones;
  final String? hours;
  final List<String> categories;
  final double lat;
  final double lng;
  final double? distanceMeters;
  /// URL фото из каталога 2GIS (`external_content`, `ads` и т.п.) при наличии в ответе API.
  final List<String> photoUrls;
  final String? description;

  PlaceItem({
    required this.id,
    required this.name,
    this.address,
    this.rating,
    this.url,
    this.phones,
    this.hours,
    List<String>? categories,
    required this.lat,
    required this.lng,
    this.distanceMeters,
    List<String>? photoUrls,
    this.description,
  })  : categories = _nonEmptyStrings(categories),
        photoUrls = _nonEmptyStrings(photoUrls);

  static List<String> _nonEmptyStrings(List<String>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return List<String>.from(raw.map((e) => e.trim()).where((s) => s.isNotEmpty));
  }

  /// Превью карты (Яндекс Static API 1.x) — только для блока «Как добраться», не как фото заведения.
  ///
  /// Важно: параметр `size` — это **`ширина,высота` через запятую**, не `640x360`.
  /// Иначе API отвечает 400 и [Image.network] не рисует ничего. Лимит сервиса: до 650×450.
  String mapPreviewUrl({int width = 640, int height = 360}) {
    final w = width.clamp(1, 650);
    final h = height.clamp(1, 450);
    final ll = '${lng.toStringAsFixed(6)},${lat.toStringAsFixed(6)}';
    return 'https://static-maps.yandex.ru/1.x/?ll=$ll&z=16&l=map&size=$w,$h&pt=$ll,pm2rdm';
  }

  /// Первая ссылка на фото заведения из каталога 2GIS, если API её вернул.
  String? get displayCoverImageUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  /// Только фото заведения из каталога (без подстановки карты).
  List<String> get displayGalleryUrls => List<String>.from(photoUrls);

  String get firmProfileUrl => 'https://2gis.ru/firm/$id';

  String get distanceLabel {
    final d = distanceMeters;
    if (d == null) return '';
    if (d < 950) return '${d.round()} м';
    return '${(d / 1000).toStringAsFixed(1)} км';
  }

  PlaceItem copyWith({
    String? id,
    String? name,
    String? address,
    double? rating,
    String? url,
    String? phones,
    String? hours,
    List<String>? categories,
    double? lat,
    double? lng,
    double? distanceMeters,
    List<String>? photoUrls,
    String? description,
  }) {
    return PlaceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      rating: rating ?? this.rating,
      url: url ?? this.url,
      phones: phones ?? this.phones,
      hours: hours ?? this.hours,
      categories: categories ?? this.categories,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      photoUrls: photoUrls ?? this.photoUrls,
      description: description ?? this.description,
    );
  }
}
