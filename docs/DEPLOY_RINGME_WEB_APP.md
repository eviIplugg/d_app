# Веб-хостинг Firebase (проект `dating-app-34f38`)

Два сайта в одном проекте:

| URL | Содержимое | Hosting target |
|-----|------------|----------------|
| **https://auth-ringme.web.app** | Основное приложение для web (`lib/main.dart`) и страница виджета Telegram **`/telegram.html`** (копируется из `hosting/telegram.html` при деплое) | `consumer` |
| **https://dating-app-34f38.web.app** | CRM (`lib/main_crm_web.dart`) | `crm` |

В **Authentication → Settings → Authorized domains** добавьте: `auth-ringme.web.app`, `dating-app-34f38.web.app`.

Домен бота Telegram (`/setdomain` в BotFather): **auth-ringme.web.app** — см. `lib/config/telegram_config.dart`.

## Одна команда: всё веб + Hosting

Из корня репозитория (нужны [Flutter](https://flutter.dev) и [Firebase CLI](https://firebase.google.com/docs/cli#install_the_firebase_cli) или `npx firebase-tools`):

```bash
./scripts/deploy_web_all.sh
```

Скрипт выполняет `flutter pub get`, собирает CRM в `build/web_crm`, приложение в `build/web`, копирует `hosting/telegram.html` → `build/web/telegram.html`, затем `firebase deploy --only hosting` (оба сайта: `crm`, `consumer`).

Полный деплой проекта (правила Firestore, Storage, Functions, hosting):

```bash
FULL=1 ./scripts/deploy_web_all.sh
```

---

## Пошагово (вручную)

Проект CLI: `firebase use dating-app-34f38` (или `default`).

### 1. CRM

```bash
flutter build web -t lib/main_crm_web.dart --release --output=build/web_crm
firebase deploy --only hosting:crm
```

### 2. Основное приложение + Telegram (`/telegram.html`)

```bash
flutter build web --release
cp hosting/telegram.html build/web/telegram.html
firebase deploy --only hosting:consumer
```

Сборки **CRM** и **consumer** используют разные папки (`build/web_crm` и `build/web`), их можно деплоить в любом порядке без перезаписи друг друга.

## Редирект после Telegram

Файл `hosting/telegram.html` после авторизации перенаправляет на **https://auth-ringme.web.app/?tg=1&…** — там же лежит сборка **consumer** (`main.dart`).

---

Устаревший вариант с отдельным таргетом `landing` и третьим сайтом не используется: виджет и приложение на одном хосте **auth-ringme**.
