/// Режим запуска: полное приложение или отдельная CRM-сборка (`lib/main_crm_web.dart`).
abstract final class AppLaunchConfig {
  static bool _crmWebOnly = false;

  /// Включить из `main_crm_web.dart` перед [runApp].
  static void enableCrmWebOnly() {
    _crmWebOnly = true;
  }

  static bool get crmWebOnly => _crmWebOnly;
}
