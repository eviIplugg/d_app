import 'dart:html' as html;

import '../config/web_hosts.dart';

/// На CRM (dating-app-34f38.web.app) коллбэк Telegram не обрабатываем — ведём на consumer-приложение.
void redirectCrmToConsumerIfTelegramCallback() {
  final search = html.window.location.search ?? '';
  if (search.isEmpty || !search.contains('tg=1')) return;
  final path = html.window.location.pathname ?? '';
  final newUrl = '$kConsumerWebAppOrigin$path$search${html.window.location.hash}';
  html.window.location.replace(newUrl);
}
