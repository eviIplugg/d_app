"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.telegramSignIn = exports.adminDeleteUsers = void 0;
const crypto = __importStar(require("crypto"));
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
admin.initializeApp();
const db = admin.firestore();
const telegramBotToken = (0, params_1.defineSecret)('TELEGRAM_BOT_TOKEN');
function sha256Hex(input) {
    return crypto.createHash('sha256').update(input.trim(), 'utf8').digest('hex');
}
/** Проверка подписи Telegram Login Widget (https://core.telegram.org/widgets/login#checking-authorization) */
function verifyTelegramLoginPayload(raw, botToken) {
    const hash = raw['hash'];
    if (typeof hash !== 'string' || hash.length === 0)
        return false;
    const pairs = [];
    for (const [k, v] of Object.entries(raw)) {
        if (k === 'hash' || k === 'tg')
            continue;
        if (v === undefined || v === null)
            continue;
        pairs.push([k, String(v)]);
    }
    pairs.sort((a, b) => a[0].localeCompare(b[0]));
    const checkString = pairs.map(([k, v]) => `${k}=${v}`).join('\n');
    const secretKey = crypto.createHash('sha256').update(botToken, 'utf8').digest();
    const hmac = crypto.createHmac('sha256', secretKey).update(checkString, 'utf8').digest('hex');
    return hmac === hash;
}
function assertFreshAuthDate(raw, maxAgeSec) {
    const authDateRaw = raw['auth_date'];
    const authDate = parseInt(String(authDateRaw ?? ''), 10);
    if (Number.isNaN(authDate)) {
        throw new https_1.HttpsError('invalid-argument', 'auth_date required');
    }
    const now = Math.floor(Date.now() / 1000);
    if (Math.abs(now - authDate) > maxAgeSec) {
        throw new https_1.HttpsError('invalid-argument', 'Telegram auth expired, try again');
    }
}
async function assertAdmin(callerUid) {
    const snap = await db.collection('users').doc(callerUid).get();
    const role = snap.data()?.role;
    if (role !== 'admin') {
        throw new https_1.HttpsError('permission-denied', 'Admin only');
    }
}
async function addBlacklist(type, value, createdBy, reason) {
    const hash = sha256Hex(value);
    const docId = `${type}_${hash}`;
    await db.collection('blacklist').doc(docId).set({
        type,
        valueHash: hash,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy,
        reason: reason ?? null,
    }, { merge: true });
}
async function deleteCollectionByQuery(q, hardLimit = 5000) {
    let deleted = 0;
    while (true) {
        const snap = await q.limit(400).get();
        if (snap.empty)
            break;
        const batch = db.batch();
        for (const doc of snap.docs) {
            batch.delete(doc.ref);
            deleted++;
            if (deleted >= hardLimit)
                break;
        }
        await batch.commit();
        if (deleted >= hardLimit)
            break;
    }
    return deleted;
}
exports.adminDeleteUsers = (0, https_1.onCall)(async (req) => {
    const callerUid = req.auth?.uid;
    if (!callerUid)
        throw new https_1.HttpsError('unauthenticated', 'Auth required');
    await assertAdmin(callerUid);
    const uids = (req.data?.uids ?? []);
    const options = (req.data?.options ?? {});
    if (!Array.isArray(uids) || uids.length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'uids[] required');
    }
    if (uids.length > 200) {
        throw new https_1.HttpsError('invalid-argument', 'Too many uids (max 200 per call)');
    }
    const result = { ok: [], failed: [] };
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
            if (phone)
                await addBlacklist('phone', phone, callerUid, options.reason);
            if (tg)
                await addBlacklist('telegram', tg, callerUid, options.reason);
            // Удаляем пользователя из Firebase Auth (жёстко)
            try {
                await admin.auth().deleteUser(uid);
            }
            catch (e) {
                // Если пользователя уже нет в Auth — продолжаем
                const msg = String(e?.message ?? e);
                if (!msg.toLowerCase().includes('user-not-found'))
                    throw e;
            }
            // Tombstone в Firestore (PII убираем, чаты не трогаем)
            await userRef.set({
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
            }, { merge: true });
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
        }
        catch (e) {
            result.failed.push({ uid, error: String(e?.message ?? e) });
        }
    }
    return result;
});
/**
 * Вход через Telegram: проверка подписи виджета, при существующем пользователе — custom token для Firebase Auth.
 * Новый пользователь: { register: true } — клиент создаёт anonymous и saveTelegramUser.
 */
exports.telegramSignIn = (0, https_1.onCall)({
    region: 'us-central1',
    secrets: [telegramBotToken],
    maxInstances: 20,
}, async (request) => {
    const botToken = telegramBotToken.value().trim();
    if (!botToken) {
        throw new https_1.HttpsError('failed-precondition', 'TELEGRAM_BOT_TOKEN secret is not set');
    }
    const raw = (request.data ?? {});
    if (!verifyTelegramLoginPayload(raw, botToken)) {
        throw new https_1.HttpsError('permission-denied', 'Invalid Telegram auth signature');
    }
    assertFreshAuthDate(raw, 86400);
    const idRaw = raw['id'];
    const tgId = idRaw !== undefined && idRaw !== null ? String(idRaw).trim() : '';
    if (!tgId) {
        throw new https_1.HttpsError('invalid-argument', 'id required');
    }
    const blDocId = `telegram_${sha256Hex(tgId)}`;
    const blSnap = await db.collection('blacklist').doc(blDocId).get();
    if (blSnap.exists) {
        throw new https_1.HttpsError('permission-denied', 'This Telegram account is blocked');
    }
    const userSnap = await db.collection('users').where('telegramUserId', '==', tgId).limit(1).get();
    if (userSnap.empty) {
        return { register: true };
    }
    const userDoc = userSnap.docs[0];
    const uid = userDoc.id;
    const userData = userDoc.data() || {};
    if (userData.isDeleted === true) {
        throw new https_1.HttpsError('failed-precondition', 'This account was removed');
    }
    const customToken = await admin.auth().createCustomToken(uid);
    return { customToken };
});
