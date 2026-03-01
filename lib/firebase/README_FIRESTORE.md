# Структура базы данных Firebase (Firestore)

Используется **Cloud Firestore**. Константы путей и полей — в `lib/firebase/firestore_schema.dart`.

---

## 1. **users** — профили

| Поле | Тип | Описание |
|------|-----|----------|
| (documentId) | — | `uid` из Firebase Auth |
| name | string | Имя |
| birthdate | Timestamp | Дата рождения |
| gender | string | `male` \| `female` \| `other` |
| preference | string | `men` \| `women` \| `everyone` |
| photos | array<string> | URL фотографий (до 6) |
| bio | string | О себе |
| city | string | Город |
| job | string | Работа |
| education | string | Образование |
| verificationStatus | string | `none` \| `pending` \| `verified` |
| phoneNumber | string | Номер телефона (E.164) для входа по телефону |
| authProvider | string | `phone` \| `google` \| `vk` \| `yandex` |
| createdAt | Timestamp | Регистрация |
| updatedAt | Timestamp | Обновление профиля |
| lastActiveAt | Timestamp | Последняя активность |
| fcmToken | string | Токен для push |

---

## 2. **swipes** — свайпы

| Поле | Тип | Описание |
|------|-----|----------|
| userId | string | Кто свайпнул |
| targetUserId | string | Кого свайпнули |
| direction | string | `like` \| `pass` |
| createdAt | Timestamp | Время свайпа |

**Индексы:** `userId` + `createdAt` (для истории и ленты).

---

## 3. **matches** — матчи

| Поле | Тип | Описание |
|------|-----|----------|
| userId1 | string | Первый пользователь (меньший uid) |
| userId2 | string | Второй пользователь |
| createdAt | Timestamp | Время матча |
| lastActivityAt | Timestamp | Последнее сообщение/действие |
| unreadCount1 | number | Непрочитанные для userId1 |
| unreadCount2 | number | Непрочитанные для userId2 |

**documentId:** можно `matchId` или составной `userId1_userId2` (сортировать uid для уникальности).

---

## 4. **chats** — чаты

| Поле | Тип | Описание |
|------|-----|----------|
| participantIds | array<string> | [userId1, userId2] |
| createdAt | Timestamp | Создание чата |
| lastMessageAt | Timestamp | Время последнего сообщения |
| lastMessagePreview | string | Превью текста |
| lastMessageSenderId | string | Кто написал последнее |

**documentId:** тот же `matchId`, что и в коллекции `matches`.

### Субколлекция **chats/{chatId}/messages**

| Поле | Тип | Описание |
|------|-----|----------|
| senderId | string | Кто отправил |
| text | string | Текст |
| createdAt | Timestamp | Время отправки |
| readBy | array<string> | Кто прочитал (userId) |
| type | string | `text` \| `image` (опционально) |

---

## 5. **activities** — активности

Лента событий: лайки, матчи, сообщения, просмотры профиля.

| Поле | Тип | Описание |
|------|-----|----------|
| userId | string | Кому показываем (владелец ленты) |
| actorId | string | Кто совершил действие |
| type | string | `like` \| `match` \| `message` \| `profile_view` |
| targetId | string | matchId, chatId или userId |
| createdAt | Timestamp | Время события |
| payload | map | Доп. данные (например, текст сообщения) |

**Индексы:** `userId` + `createdAt` (по убыванию).

---

## 6. **verification** — верификация

| Поле | Тип | Описание |
|------|-----|----------|
| (documentId) | — | `userId` |
| userId | string | Пользователь |
| status | string | `pending` \| `approved` \| `rejected` |
| documentUrls | array<string> | URL фото документов |
| submittedAt | Timestamp | Когда отправлено |
| reviewedAt | Timestamp | Когда проверено |
| rejectReason | string | Причина отказа (если rejected) |

В профиле (`users`) поле `verificationStatus` дублирует итог для быстрого отображения.

---

## 7. **Лента (feed)**

**Вариант A (рекомендуется):** лента без отдельной коллекции.

- Запрос к `users` с фильтрами: город, возраст (по birthdate), пол (preference), исключать себя.
- Исключать тех, кто уже есть в `swipes` для текущего пользователя (`userId == currentUserId`).
- Пагинация: `startAfterDocument` / `limit`.

**Вариант B:** кэш ленты в подколлекции `users/{uid}/feedCache`.

- documentId = `targetUserId`, поля — копия нужных данных из `users` (имя, фото, возраст, город).
- Обновлять при добавлении новых пользователей или по расписанию.

---

## Правила безопасности (Firestore Rules) — пример

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isOwner(uid) { return request.auth != null && request.auth.uid == uid; }
    function isParticipant(participantIds) { return request.auth.uid in participantIds; }

    match /users/{userId} {
      allow read: if request.auth != null;
      allow create: if isOwner(userId);
      allow update, delete: if isOwner(userId);
    }
    match /swipes/{swipeId} {
      allow read, write: if request.auth != null;
    }
    match /matches/{matchId} {
      allow read, write: if request.auth != null;
    }
    match /chats/{chatId} {
      allow read, write: if request.auth != null && isParticipant(resource.data.participantIds);
      allow create: if request.auth != null;
    }
    match /chats/{chatId}/messages/{msgId} {
      allow read, write: if request.auth != null;
    }
    match /activities/{activityId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    match /verification/{userId} {
      allow read: if isOwner(userId);
      allow write: if request.auth != null; // создание/обновление — только свой userId
    }
  }
}
```

---

## Подключение Firebase в проекте

В `pubspec.yaml` добавь:

```yaml
dependencies:
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
```

Инициализация в `main.dart`:

```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

Файл `google-services.json` (Android) и `GoogleService-Info.plist` (iOS) должны содержать пакет приложения. Сейчас в проекте используется **applicationId = com.ringme.app** (совпадает с google-services.json).
