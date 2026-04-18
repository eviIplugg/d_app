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
const String kPostsCollection = 'posts';
const String kStoriesCollection = 'stories';
const String kEventsCollection = 'events';
const String kVenuesCollection = 'venues';
const String kEventSubscriptionsCollection = 'eventSubscriptions';
const String kEventParticipantsCollection = 'eventParticipants';
const String kBlacklistCollection = 'blacklist';

// Субколлекции
const String kMessagesSubcollection = 'messages';
const String kVerificationSubcollection = 'verification'; // или отдельная коллекция

// ============== USERS (профиль) ==============
// Коллекция: users
// documentId = uid (Firebase Auth UID)

const String kUserName = 'name';
const String kUserSurname = 'surname'; // Фамилия
const String kUserBirthdate = 'birthdate'; // Timestamp
const String kUserGender = 'gender'; // 'male' | 'female' | 'other'
const String kUserPreference = 'preference'; // 'men' | 'women' | 'everyone'
const String kUserPhotos = 'photos'; // List<String> URLs
const String kUserBio = 'bio';
const String kUserCity = 'city'; // Название города (например из списка РФ)
/// Геопозиция пользователя (широта/долгота). Используется для «рядом с вами» и Places.
const String kUserGeoLat = 'geoLat';
const String kUserGeoLng = 'geoLng';
const String kUserGeoUpdatedAt = 'geoUpdatedAt'; // Timestamp
const String kUserJob = 'job';
const String kUserEducation = 'education'; // Уровень образования (ключ)
const String kUserEducationLevel = 'educationLevel'; // среднее неполное | среднее полное | ...
const String kUserUniversity = 'university'; // Название вуза
const String kUserVerificationStatus = 'verificationStatus'; // 'none' | 'pending' | 'verified'
const String kUserPhoneNumber = 'phoneNumber'; // E.164 для входа по телефону
const String kUserAuthProvider = 'authProvider'; // 'phone' | 'google' | 'vk' | 'yandex'
const String kUserTelegramUserId = 'telegramUserId'; // id из Telegram Login Widget
const String kUserCreatedAt = 'createdAt'; // Timestamp
const String kUserUpdatedAt = 'updatedAt'; // Timestamp
const String kUserLastActiveAt = 'lastActiveAt'; // Timestamp
const String kUserFcmToken = 'fcmToken'; // для push-уведомлений
const String kUserInterests = 'interests'; // List<String> — теги: Теннис, Вино и т.д.
const String kUserRelationshipGoal = 'relationshipGoal'; // 'friendship' | 'communication' | 'relationship'

/// Роль пользователя: 'user' | 'organizer' | 'admin'. Для CRM и доступа.
const String kUserRole = 'role';
/// Заблокирован ли пользователь (админ).
const String kUserIsBanned = 'isBanned';
const String kUserDeletedAt = 'deletedAt'; // Timestamp
const String kUserDeletedBy = 'deletedBy'; // uid
const String kUserIsDeleted = 'isDeleted'; // bool

// ============== BLACKLIST (запрет повторной регистрации) ==============
const String kBlacklistType = 'type'; // 'phone' | 'telegram'
const String kBlacklistValueHash = 'valueHash';
const String kBlacklistCreatedAt = 'createdAt';
const String kBlacklistCreatedBy = 'createdBy';
const String kBlacklistReason = 'reason';

/// Настройки (вложенный объект в документе users): приватность, уведомления и т.д.
const String kUserSettings = 'settings';

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
const String kMessageImageUrl = 'imageUrl'; // для type == 'image'

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

// ============== POSTS (посты в ленте) ==============
const String kPostAuthorId = 'authorId';
const String kPostPhotoUrls = 'photoUrls'; // List<String>
const String kPostPhotoDataUrls = 'photoDataUrls'; // List<String> data:image/jpeg;base64,... (без Storage)
const String kPostCaption = 'caption';
const String kPostCreatedAt = 'createdAt'; // Timestamp
const String kPostType = 'type'; // 'personal' | 'activity'
const String kPostLikeCount = 'likeCount'; // int
const String kPostLikedBy = 'likedBy'; // List<String>

const String kPostActivityTitle = 'activityTitle';
const String kPostActivityDate = 'activityDate';
const String kPostActivityVenue = 'activityVenue';
const String kPostActivityVenueVerified = 'activityVenueVerified';
const String kPostActivityPrice = 'activityPrice';
const String kPostActivityRating = 'activityRating';
const String kPostActivityTag = 'activityTag';

/// Модерация постов/фото: 'pending' | 'approved' | 'rejected'. В ленте показываем только approved.
const String kPostModerationStatus = 'moderationStatus';
const String kPostReviewedAt = 'reviewedAt'; // Timestamp
const String kPostReviewedBy = 'reviewedBy'; // uid модератора

/// Подколлекция: posts/{postId}/comments/{commentId}
const String kPostCommentsSubcollection = 'comments';
const String kCommentAuthorId = 'authorId';
const String kCommentText = 'text';
const String kCommentCreatedAt = 'createdAt'; // Timestamp

// ============== STORIES (истории 24ч) ==============
const String kStoryAuthorId = 'authorId';
const String kStoryImageUrl = 'imageUrl';
const String kStoryStoragePath = 'storagePath';
const String kStoryCaption = 'caption';
const String kStoryCreatedAt = 'createdAt'; // Timestamp
const String kStoryExpiresAt = 'expiresAt'; // Timestamp
const String kStoryVisibleTo = 'visibleTo'; // List<String> uid получателей (matched users + author)

// ============== EVENTS (мероприятия в ленте) ==============
const String kEventTitle = 'title';
const String kEventDescription = 'description';
const String kEventImageUrl = 'imageUrl';
const String kEventPhotoUrls = 'photoUrls'; // List<String> для галереи
const String kEventDateTime = 'dateTime'; // Timestamp
const String kEventVenueId = 'venueId';
const String kEventVenueName = 'venueName';
const String kEventVenueVerified = 'venueVerified';
const String kEventAddress = 'address';
const String kEventCity = 'city';
const String kEventPrice = 'price'; // "1500 ₽" или "от 1500 ₽"
const String kEventRating = 'rating'; // 5.0
const String kEventStatus = 'status'; // 'open' | 'full'
const String kEventCurrentParticipants = 'currentParticipants';
const String kEventMaxParticipants = 'maxParticipants';
const String kEventCreatedAt = 'createdAt';
const String kEventLikedBy = 'likedBy'; // List<String> userId
/// UID организатора (владельца venue), создавшего мероприятие.
const String kEventCreatedBy = 'createdBy';

// ============== VENUES (места проведения / организаторы) ==============
const String kVenueName = 'name';
const String kVenuePhotoUrl = 'photoUrl';
const String kVenueVerified = 'verified';
/// UID пользователя-организатора (владелец места).
const String kVenueOwnerId = 'ownerId';
const String kVenueEventsCount = 'eventsCount';
const String kVenueSubscribersCount = 'subscribersCount';
const String kVenueAddress = 'address';
const String kVenueCity = 'city';

// eventSubscriptions: userId (docId), venueIds in subcollection or document with array
const String kEventSubscriptionUserId = 'userId';
const String kEventSubscriptionVenueId = 'venueId';

// eventParticipants: eventId + userId (для "Ваше расписание")
const String kEventParticipantEventId = 'eventId';
const String kEventParticipantUserId = 'userId';
