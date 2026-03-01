/// Константы коллекций и полей Firestore для dating-приложения.
/// Используйте эти константы везде при работе с Firebase.
library;

// ============== КОЛЛЕКЦИИ ==============

const String kUsersCollection = 'users';
const String kSwipesCollection = 'swipes';
const String kMatchesCollection = 'matches';
const String kChatsCollection = 'chats';
const String kActivitiesCollection = 'activities';
const String kVerificationCollection = 'verification';
const String kFeedCollection = 'feed'; // опционально: кэш ленты по пользователю

// Субколлекции
const String kMessagesSubcollection = 'messages';
const String kVerificationSubcollection = 'verification'; // или отдельная коллекция

// ============== USERS (профиль) ==============
// Коллекция: users
// documentId = uid (Firebase Auth UID)

const String kUserName = 'name';
const String kUserBirthdate = 'birthdate'; // Timestamp
const String kUserGender = 'gender'; // 'male' | 'female' | 'other'
const String kUserPreference = 'preference'; // 'men' | 'women' | 'everyone'
const String kUserPhotos = 'photos'; // List<String> URLs
const String kUserBio = 'bio';
const String kUserCity = 'city';
const String kUserJob = 'job';
const String kUserEducation = 'education';
const String kUserVerificationStatus = 'verificationStatus'; // 'none' | 'pending' | 'verified'
const String kUserPhoneNumber = 'phoneNumber'; // E.164 для входа по телефону
const String kUserAuthProvider = 'authProvider'; // 'phone' | 'google' | 'vk' | 'yandex'
const String kUserCreatedAt = 'createdAt'; // Timestamp
const String kUserUpdatedAt = 'updatedAt'; // Timestamp
const String kUserLastActiveAt = 'lastActiveAt'; // Timestamp
const String kUserFcmToken = 'fcmToken'; // для push-уведомлений

// ============== SWIPES (свайпы) ==============
// Коллекция: swipes
// documentId = auto ID или составной: "${userId}_${targetUserId}"

const String kSwipeUserId = 'userId';
const String kSwipeTargetUserId = 'targetUserId';
const String kSwipeDirection = 'direction'; // 'like' | 'pass'
const String kSwipeCreatedAt = 'createdAt'; // Timestamp

// Составной индекс: userId + createdAt (для ленты и истории)

// ============== MATCHES (матчи) ==============
// Коллекция: matches
// documentId = auto ID или "${minUid}_${maxUid}" для уникальности пары

const String kMatchUserId1 = 'userId1';
const String kMatchUserId2 = 'userId2';
const String kMatchCreatedAt = 'createdAt'; // Timestamp
const String kMatchLastActivityAt = 'lastActivityAt'; // Timestamp
const String kMatchUnreadCount1 = 'unreadCount1'; // int, для userId1
const String kMatchUnreadCount2 = 'unreadCount2'; // int, для userId2

// ============== CHATS (чаты) ==============
// Коллекция: chats
// documentId = matchId (тот же ID, что и в matches)

const String kChatParticipantIds = 'participantIds'; // List<String>
const String kChatCreatedAt = 'createdAt'; // Timestamp
const String kChatLastMessageAt = 'lastMessageAt'; // Timestamp
const String kChatLastMessagePreview = 'lastMessagePreview'; // String
const String kChatLastMessageSenderId = 'lastMessageSenderId'; // String

// Субколлекция: chats/{chatId}/messages
const String kMessageSenderId = 'senderId';
const String kMessageText = 'text';
const String kMessageCreatedAt = 'createdAt'; // Timestamp
const String kMessageReadBy = 'readBy'; // List<String> — кто прочитал (userId)
const String kMessageType = 'type'; // 'text' | 'image' (опционально)

// ============== ACTIVITIES (активности) ==============
// Коллекция: activities
// Лента активности пользователя: лайки, матчи, просмотры профиля

const String kActivityUserId = 'userId'; // кому показываем активность
const String kActivityActorId = 'actorId'; // кто совершил действие
const String kActivityType = 'type'; // 'like' | 'match' | 'message' | 'profile_view'
const String kActivityTargetId = 'targetId'; // matchId, chatId, или userId
const String kActivityCreatedAt = 'createdAt'; // Timestamp
const String kActivityPayload = 'payload'; // Map — доп. данные (текст сообщения и т.д.)

// ============== VERIFICATION (верификация) ==============
// Коллекция: verification
// documentId = userId

const String kVerificationUserId = 'userId';
const String kVerificationStatus = 'status'; // 'pending' | 'approved' | 'rejected'
const String kVerificationDocumentUrls = 'documentUrls'; // List<String> — фото документов
const String kVerificationSubmittedAt = 'submittedAt'; // Timestamp
const String kVerificationReviewedAt = 'reviewedAt'; // Timestamp
const String kVerificationRejectReason = 'rejectReason'; // String, если rejected

// ============== FEED (лента) ==============
// Вариант 1: лента строится на лету — запрос к users с фильтрами по городу/возрасту/полу,
// исключая уже просмотренных (swipes где userId = currentUser).
// Вариант 2: коллекция feed — кэш карточек для пользователя (подколлекция users/{uid}/feed или отдельная коллекция).

// Пример подколлекции для кэша ленты: users/{uid}/feedCache
const String kFeedCacheSubcollection = 'feedCache';
// documentId = targetUserId
const String kFeedCachedAt = 'cachedAt'; // Timestamp
// остальные поля — копия нужных полей из users (name, photos[0], age, city...)
