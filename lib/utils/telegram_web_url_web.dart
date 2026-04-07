import 'dart:html' as html;

void clearTelegramQueryFromCurrentUrl() {
  final href = html.window.location.href;
  final uri = Uri.parse(href);
  if (uri.queryParameters['tg'] != '1') return;
  final clean = Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: uri.path,
    fragment: uri.fragment,
  );
  html.window.history.replaceState(null, '', clean.toString());
}
