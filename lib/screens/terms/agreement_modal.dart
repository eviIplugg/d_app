import 'package:flutter/material.dart';

/// Текст пользовательского соглашения и политики конфиденциальности для показа в модальном окне.
class AgreementModal extends StatelessWidget {
  const AgreementModal({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  /// Показать модальное окно с пользовательским соглашением.
  static void showUserAgreement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgreementModal(
        title: 'Пользовательское соглашение',
        body: _userAgreementText,
      ),
    );
  }

  /// Показать модальное окно с политикой конфиденциальности.
  static void showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgreementModal(
        title: 'Политика конфиденциальности',
        body: _privacyPolicyText,
      ),
    );
  }

  static const String _userAgreementText = '''
Пользовательское соглашение

Настоящее Пользовательское соглашение (далее — Соглашение) регулирует отношения между пользователем (далее — Пользователь) и сервисом знакомств (далее — Сервис).

1. Общие положения
1.1. Использование Сервиса означает безоговорочное принятие Пользователем всех условий настоящего Соглашения.
1.2. Регистрируясь в Сервисе, Пользователь подтверждает, что достиг возраста 18 лет и имеет полное право заключать настоящее Соглашение.

2. Регистрация и аккаунт
2.1. Пользователь обязан предоставлять достоверную информацию при регистрации.
2.2. Пользователь несёт ответственность за сохранность данных для входа в аккаунт.
2.3. Запрещается передача аккаунта третьим лицам.

3. Правила поведения
3.1. Запрещается размещение информации, нарушающей законодательство РФ или права третьих лиц.
3.2. Запрещается оскорбления, угрозы, домогательства и иные действия, ущемляющие права других пользователей.
3.3. Сервис оставляет за собой право удалять контент и блокировать аккаунты при нарушении правил.

4. Конфиденциальность
4.1. Обработка персональных данных осуществляется в соответствии с Политикой конфиденциальности Сервиса.

5. Изменения
5.1. Сервис вправе изменять условия Соглашения. Актуальная версия размещена в приложении. Продолжение использования Сервиса после изменений означает согласие с новой редакцией.

Дата последнего обновления: 2025 год.
''';

  static const String _privacyPolicyText = '''
Политика конфиденциальности

Настоящая Политика конфиденциальности определяет порядок обработки и защиты персональных данных пользователей сервиса знакомств (далее — Сервис).

1. Какие данные мы собираем
1.1. Данные, предоставляемые при регистрации: имя, дата рождения, пол, город, фотографии, информация о себе, предпочтения и цели знакомства.
1.2. Технические данные: идентификатор устройства, IP-адрес, данные о действиях в приложении для обеспечения работы и безопасности Сервиса.

2. Цели обработки
2.1. Предоставление функционала Сервиса (подбор анкет, чаты, уведомления).
2.2. Улучшение работы приложения и качества сервиса.
2.3. Соблюдение требований законодательства.

3. Передача данных
3.1. Мы не передаём персональные данные третьим лицам в маркетинговых целях без согласия пользователя.
3.2. Данные могут передаваться партнёрам, обеспечивающим работу Сервиса (хостинг, аналитика), в объёме, необходимом для оказания услуг.
3.3. Передача данных возможна по требованию уполномоченных государственных органов в случаях, предусмотренных законом.

4. Хранение и защита
4.1. Данные хранятся на защищённых серверах. Применяются организационные и технические меры для предотвращения несанкционированного доступа.
4.2. Пользователь может запросить удаление аккаунта и персональных данных через настройки приложения или обратившись в поддержку.

5. Ваши права
5.1. Вы имеете право на доступ к своим данным, их исправление и удаление в соответствии с применимым законодательством.
5.2. Обращения по вопросам персональных данных направляются через раздел помощи в приложении.

Дата последнего обновления: 2025 год.
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF333333);
    final textColor = isDark ? Colors.white70 : Colors.grey.shade800;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: titleColor),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white12 : null),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                body,
                style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
