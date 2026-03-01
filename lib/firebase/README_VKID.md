# VK ID — настройка авторизации

В проекте подключён официальный **VK ID SDK для Flutter** ([документация](https://id.vk.com/about/business/go/docs/ru/vkid/latest/vk-id/connection/start-integration/flutter/install)).

## 1. Создать приложение в VK ID

1. Зайдите в [кабинет VK ID](https://id.vk.com/).
2. Создайте приложение (если ещё не создано).
3. Скопируйте:
   - **ID приложения (client_id)**
   - **Защищённый ключ (client_secret)**

## 2. Android

В файле **`android/gradle.properties`** задайте (или замените значения по умолчанию):

```properties
VKID_CLIENT_ID=ваш_client_id
VKID_CLIENT_SECRET=ваш_client_secret
```

Не коммитьте реальные значения в публичный репозиторий — добавьте `gradle.properties` в `.gitignore` или используйте переменные окружения.

Репозиторий VK ID SDK и плагин `vkid.manifest.placeholders` уже подключены в:
- `android/settings.gradle.kts`
- `android/build.gradle.kts`
- `android/app/build.gradle.kts`

## 3. iOS

В **`ios/Runner/Info.plist`** подставьте свои данные:

- **VK_APP_CLIENT_ID** — ваш `client_id`.
- **VK_APP_CLIENT_SECRET** — ваш `client_secret`.
- В **CFBundleURLSchemes** массив должен содержать схему вида **`vk{client_id}`** (например, `vk123456` для client_id = 123456).

Сейчас в примере указаны `vk0` и пустой secret — замените на значения из кабинета VK ID.

## 4. Firebase

Для входа через VK и последующего использования Firebase Auth в [Firebase Console](https://console.firebase.google.com) в разделе Authentication → Sign-in method провайдер **VK** отдельно не настраивается: используется кастомный вход через `OAuthProvider('vk.com').credential(accessToken, idToken)` с токенами, которые возвращает VK ID SDK.

После подстановки **client_id** и **client_secret** выполните `flutter pub get` и пересоберите приложение.
