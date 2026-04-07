# Деплой Flutter Web на REG.RU

## 1. Две сборки

### Полное приложение (лента, чаты, поиск — как на телефоне)

```bash
cd путь/к/d_app
flutter build web --release
```

Готовые файлы: **`build/web/`** — загрузите **содержимое** папки на хостинг.

### Только CRM (админка: модерация, пользователи, мероприятия)

Отдельная точка входа: `lib/main_crm_web.dart` (доступ только для пользователей с ролью `admin` в Firestore).

```bash
flutter build web -t lib/main_crm_web.dart --release
```

Результат тоже в **`build/web/`** (перезапишет предыдущую сборку). Для двух сайтов собирайте по очереди и **копируйте** `build/web` в разные папки, например:
- `dist_app/` — после `flutter build web`
- `dist_crm/` — после `flutter build web -t lib/main_crm_web.dart`

---

## 2. REG.RU: куда заливать

1. Панель REG.RU → **Хостинг** → ваш тариф → **Файловый менеджер** или **FTP**.
2. Для основного сайта обычно каталог **`public_html`** (или `www`).
3. Для поддомена, например `crm.ваш-домен.ru` — отдельная папка (указана в настройках поддомена).
4. Залейте **внутрь** целевой папки файлы из `build/web`:  
   `index.html`, `main.dart.js`, `flutter.js`, `assets/`, `canvaskit/` и остальное — **структура как после сборки**.

---

## 3. SPA: все пути на `index.html`

Flutter Web — одностраничное приложение. При обновлении страницы по прямому URL сервер должен отдавать `index.html`.

### Apache (.htaccess в той же папке, куда залили сайт)

Создайте файл **`.htaccess`** (с точкой в начале имени):

```apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>
```

Пример копируется из репозитория: **`hosting/apache_flutter_web.htaccess`**.

### Nginx (если REG даёт конфиг)

Нужен `try_files $uri $uri/ /index.html;` для `location /`.

---

## 4. Firebase (обязательно для входа)

1. [Firebase Console](https://console.firebase.google.com) → проект → **Authentication** → **Settings** → **Authorized domains**.
2. Добавьте домены: **`ваш-домен.ru`**, **`www.ваш-домен.ru`**, **`crm.ваш-домен.ru`** (если CRM на поддомене).

Без этого вход по телефону / VK / Telegram на вашем домене не заработает.

---

## 5. HTTPS

В панели REG.RU включите **бесплатный SSL (Let's Encrypt)** для домена/поддомена — нужно для Telegram Login и нормальной работы PWA.

---

## 6. Альтернатива: Firebase Hosting

В проекте уже есть `firebase.json` с таргетом **`crm`** (`public: build/web`). После `flutter build web` / CRM-сборки:

```bash
firebase deploy --only hosting:crm
```

На REG.RU вы получаете полный контроль и один биллинг; Firebase Hosting удобен, если домен привязан к Google.

---

## 7. Проверка локально

```bash
flutter build web --release
cd build/web
python -m http.server 8080
```

Откройте `http://localhost:8080` (для корректных путей к `main.dart.js` лучше не открывать `index.html` как `file://`).
