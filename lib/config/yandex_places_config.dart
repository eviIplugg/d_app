/// API ключ для поиска мест.
///
/// Сейчас используется 2GIS Catalog API (https://catalog.api.2gis.com/3.0/items).
/// Демо-ключ имеет лимиты и может перестать работать.
///
/// Важно: не коммитьте реальный ключ в публичный репозиторий.
/// Для локального запуска можно передать:
/// flutter run --dart-define=PLACES_API_KEY=your_key
const String yandexPlacesApiKey = String.fromEnvironment(
  'PLACES_API_KEY',
  // Временный демо-ключ для дев-сборок. Перед публикацией заменить на секрет/define без defaultValue.
  defaultValue: '48d1d001-9049-4520-9a8e-447a720a35bb',
);

bool get isYandexPlacesConfigured => yandexPlacesApiKey.trim().isNotEmpty;

