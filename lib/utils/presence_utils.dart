/// Подписи «в сети» по полю lastActiveAt в Firestore.
class PresenceUtils {
  PresenceUtils._();

  /// Считаем «в сети», если активность не старше этого порога.
  static const Duration onlineThreshold = Duration(minutes: 3);

  static bool isOnlineNow(DateTime? lastActive) {
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive) < onlineThreshold;
  }

  /// Короткая строка для списка чатов / подзаголовка.
  static String shortLabel(DateTime? lastActive) {
    if (lastActive == null) return '';
    final diff = DateTime.now().difference(lastActive);
    if (diff < onlineThreshold) return 'в сети';
    if (diff < const Duration(minutes: 60)) return 'был(а) ${diff.inMinutes} мин. назад';
    if (diff < const Duration(hours: 24)) {
      final h = diff.inHours;
      return 'был(а) ${h} ч. назад';
    }
    if (diff < const Duration(days: 7)) return 'был(а) ${diff.inDays} дн. назад';
    return 'давно не заходил(а)';
  }
}
