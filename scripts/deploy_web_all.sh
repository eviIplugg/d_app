#!/usr/bin/env bash
# Сборка и деплой всех веб-сайтов Firebase Hosting в проекте dating-app-34f38:
#   landing  → auth-ringme.web.app (только Telegram-авторизация, static hosting/telegram_auth.html)
#   consumer → ringme.web.app (Flutter web-приложение)
#   crm      → dating-app-34f38.web.app (CRM)
#
# Использование (из корня репозитория):
#   ./scripts/deploy_web_all.sh
#
# Полный деплой (правила Firestore, Storage, Functions, hosting):
#   FULL=1 ./scripts/deploy_web_all.sh

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> flutter pub get"
flutter pub get

echo "==> CRM → build/web_crm"
flutter build web -t lib/main_crm_admin_web.dart --release --output=build/web_crm

echo "==> Приложение → build/web"
flutter build web --release

firebase_cmd() {
  if command -v firebase >/dev/null 2>&1; then
    firebase "$@"
  elif command -v npx >/dev/null 2>&1; then
    npx --yes firebase-tools "$@"
  else
    echo "Установите Firebase CLI: npm install -g firebase-tools" >&2
    exit 127
  fi
}

if [[ "${FULL:-0}" == "1" ]]; then
  echo "==> firebase deploy (hosting + firestore + storage + functions)"
  firebase_cmd deploy
else
  echo "==> firebase deploy --only hosting"
  firebase_cmd deploy --only hosting
fi

echo "==> Готово."
