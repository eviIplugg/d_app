/// Уровни образования: ключ для БД и подпись для UI.
const List<MapEntry<String, String>> kEducationLevels = [
  MapEntry('secondary_incomplete', 'Среднее неполное'),
  MapEntry('secondary_full', 'Среднее полное'),
  MapEntry('secondary_vocational', 'Среднее специальное'),
  MapEntry('incomplete_higher', 'Незаконченное высшее'),
  MapEntry('bachelor', 'Бакалавр'),
  MapEntry('specialist', 'Специалист'),
  MapEntry('master', 'Магистр'),
  MapEntry('higher', 'Высшее'),
  MapEntry('postgraduate', 'Аспирантура / PhD'),
];

String? educationLevelLabel(String? key) {
  if (key == null || key.isEmpty) return null;
  for (final e in kEducationLevels) {
    if (e.key == key) return e.value;
  }
  return key;
}
