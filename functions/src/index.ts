import * as crypto from 'crypto';
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

admin.initializeApp();

const db = admin.firestore();

const telegramBotToken = defineSecret('TELEGRAM_BOT_TOKEN');

function sha256Hex(input: string): string {
  return crypto.createHash('sha256').update(input.trim(), 'utf8').digest('hex');
}

/** Проверка подписи Telegram Login Widget (https://core.telegram.org/widgets/login#checking-authorization) */
function verifyTelegramLoginPayload(raw: Record<string, unknown>, botToken: string): boolean {
  const hash = raw['hash'];
  if (typeof hash !== 'string' || hash.length === 0) return false;

  const pairs: [string, string][] = [];
  for (const [k, v] of Object.entries(raw)) {
    if (k === 'hash' || k === 'tg') continue;
    if (v === undefined || v === null) continue;
    const s = String(v);
    // Как у Telegram: пустые поля не участвуют в data-check-string (иначе deep link с last_name= ломает HMAC).
    if (s.trim() === '') continue;
    pairs.push([k, s]);
  }
  pairs.sort((a, b) => a[0].localeCompare(b[0]));
  const checkString = pairs.map(([k, v]) => `${k}=${v}`).join('\n');

  const secretKey = crypto.createHash('sha256').update(botToken, 'utf8').digest();
  const hmac = crypto.createHmac('sha256', secretKey).update(checkString, 'utf8').digest('hex');
  return hmac === hash;
}

function assertFreshAuthDate(raw: Record<string, unknown>, maxAgeSec: number): void {
  const authDateRaw = raw['auth_date'];
  const authDate = parseInt(String(authDateRaw ?? ''), 10);
  if (Number.isNaN(authDate)) {
    throw new HttpsError('invalid-argument', 'auth_date required');
  }
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - authDate) > maxAgeSec) {
    throw new HttpsError('invalid-argument', 'Telegram auth expired, try again');
  }
}

async function assertAdmin(callerUid: string): Promise<void> {
  const snap = await db.collection('users').doc(callerUid).get();
  const role = snap.data()?.role;
  if (role !== 'admin') {
    throw new HttpsError('permission-denied', 'Admin only');
  }
}

async function addBlacklist(type: 'phone' | 'telegram', value: string, createdBy: string, reason?: string) {
  const hash = sha256Hex(value);
  const docId = `${type}_${hash}`;
  await db.collection('blacklist').doc(docId).set(
    {
      type,
      valueHash: hash,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy,
      reason: reason ?? null,
    },
    { merge: true }
  );
}

async function deleteCollectionByQuery(q: FirebaseFirestore.Query<FirebaseFirestore.DocumentData>, hardLimit: number = 5000) {
  let deleted = 0;
  while (true) {
    const snap = await q.limit(400).get();
    if (snap.empty) break;
    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
      deleted++;
      if (deleted >= hardLimit) break;
    }
    await batch.commit();
    if (deleted >= hardLimit) break;
  }
  return deleted;
}

type DeleteOptions = {
  deletePosts?: boolean;
  deleteEvents?: boolean;
  deleteVenues?: boolean;
  reason?: string;
};

export const adminDeleteUsers = onCall(async (req) => {
  const callerUid = req.auth?.uid;
  if (!callerUid) throw new HttpsError('unauthenticated', 'Auth required');
  await assertAdmin(callerUid);

  const uids = (req.data?.uids ?? []) as unknown;
  const options = (req.data?.options ?? {}) as DeleteOptions;
  if (!Array.isArray(uids) || uids.length === 0) {
    throw new HttpsError('invalid-argument', 'uids[] required');
  }
  if (uids.length > 200) {
    throw new HttpsError('invalid-argument', 'Too many uids (max 200 per call)');
  }

  const result: Record<string, any> = { ok: [], failed: [] };

  for (const uid of uids) {
    try {
      if (typeof uid !== 'string' || uid.trim().length < 6) {
        throw new Error('bad uid');
      }
      const userRef = db.collection('users').doc(uid);
      const userSnap = await userRef.get();
      const userData = userSnap.data() || {};

      const phone = typeof userData.phoneNumber === 'string' ? userData.phoneNumber : undefined;
      const tg = typeof userData.telegramUserId === 'string' ? userData.telegramUserId : undefined;

      if (phone) await addBlacklist('phone', phone, callerUid, options.reason);
      if (tg) await addBlacklist('telegram', tg, callerUid, options.reason);

      // Удаляем пользователя из Firebase Auth (жёстко)
      try {
        await admin.auth().deleteUser(uid);
      } catch (e: any) {
        // Если пользователя уже нет в Auth — продолжаем
        const msg = String(e?.message ?? e);
        if (!msg.toLowerCase().includes('user-not-found')) throw e;
      }

      // Tombstone в Firestore (PII убираем, чаты не трогаем)
      await userRef.set(
        {
          isDeleted: true,
          deletedAt: admin.firestore.FieldValue.serverTimestamp(),
          deletedBy: callerUid,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          name: 'Удалённый пользователь',
          surname: null,
          birthdate: null,
          gender: null,
          preference: null,
          bio: null,
          city: null,
          job: null,
          educationLevel: null,
          university: null,
          photos: [],
          phoneNumber: null,
          telegramUserId: null,
        },
        { merge: true }
      );

      if (options.deletePosts) {
        await deleteCollectionByQuery(db.collection('posts').where('authorId', '==', uid), 20000);
      }
      if (options.deleteEvents) {
        await deleteCollectionByQuery(db.collection('events').where('createdBy', '==', uid), 20000);
      }
      if (options.deleteVenues) {
        await deleteCollectionByQuery(db.collection('venues').where('ownerId', '==', uid), 20000);
      }

      result.ok.push(uid);
    } catch (e: any) {
      result.failed.push({ uid, error: String(e?.message ?? e) });
    }
  }

  return result;
});

/**
 * Вход через Telegram: проверка подписи виджета, при существующем пользователе — custom token для Firebase Auth.
 * Новый пользователь: { register: true } — клиент создаёт anonymous и saveTelegramUser.
 */
export const telegramSignIn = onCall(
  {
    region: 'us-central1',
    secrets: [telegramBotToken],
    maxInstances: 20,
  },
  async (request) => {
    const botToken = telegramBotToken.value().trim();
    if (!botToken) {
      throw new HttpsError('failed-precondition', 'TELEGRAM_BOT_TOKEN secret is not set');
    }

    const raw = (request.data ?? {}) as Record<string, unknown>;
    if (!verifyTelegramLoginPayload(raw, botToken)) {
      throw new HttpsError('permission-denied', 'Invalid Telegram auth signature');
    }
    assertFreshAuthDate(raw, 86400);

    const idRaw = raw['id'];
    const tgId = idRaw !== undefined && idRaw !== null ? String(idRaw).trim() : '';
    if (!tgId) {
      throw new HttpsError('invalid-argument', 'id required');
    }

    const blDocId = `telegram_${sha256Hex(tgId)}`;
    const blSnap = await db.collection('blacklist').doc(blDocId).get();
    if (blSnap.exists) {
      throw new HttpsError('permission-denied', 'This Telegram account is blocked');
    }

    const userSnap = await db.collection('users').where('telegramUserId', '==', tgId).limit(1).get();

    if (userSnap.empty) {
      return { register: true as const };
    }

    const userDoc = userSnap.docs[0];
    const uid = userDoc.id;
    const userData = userDoc.data() || {};

    if (userData.isDeleted === true) {
      throw new HttpsError('failed-precondition', 'This account was removed');
    }

    const customToken = await admin.auth().createCustomToken(uid);
    return { customToken };
  }
);

/**
 * Выдаёт custom token для входа в CRM на другом origin (dating-app-34f38.web.app).
 * Использование: авторизованный админ в основном приложении запрашивает ссылку и открывает CRM.
 */
export const issueCrmLoginToken = onCall(
  {
    region: 'us-central1',
    maxInstances: 20,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Auth required');
    }

    const userSnap = await db.collection('users').doc(uid).get();
    const role = userSnap.data()?.role;
    if (role !== 'admin') {
      throw new HttpsError('permission-denied', 'Admin only');
    }

    const customToken = await admin.auth().createCustomToken(uid, { crm: true });
    const crmUrl = `https://dating-app-34f38.web.app/?crm_token=${encodeURIComponent(customToken)}`;
    return { customToken, crmUrl };
  }
);

