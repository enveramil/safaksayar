const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 1. YENİ FORUM KONUSU BİLDİRİMİ
 * Forumda yeni bir konu açıldığında tetiklenir.
 * Konuyu AÇAN KULLANICI HARİÇ diğer tüm kayıtlı kullanıcılara push bildirimi gönderir.
 * Bildirime tıklandığında doğrudan ilgili forum konusu açılır.
 */
exports.onNewForumTopic = functions.firestore
  .document("forum_topics/{topicId}")
  .onCreate(async (snap, context) => {
    const topicId = context.params.topicId;
    const topic = snap.data();
    if (!topic) {
      console.log("Konu verisi boş, bildirim gönderilmedi.");
      return null;
    }

    const creatorId = topic.senderId;
    const title = topic.title || "Yeni Konu";
    const authorName = topic.senderName || "Bir Silah Arkadaşın";
    const category = topic.category || "Genel";
    const isGeneral = topic.isGeneral !== false;
    const location = topic.location || "";

    // Bildirim içeriği özeti
    let contentSnippet = "";
    if (topic.content) {
      const clean = topic.content.replace(/\n+/g, " ").trim();
      contentSnippet = clean.length > 90 ? clean.substring(0, 87) + "..." : clean;
    }

    console.log(`[Yeni Konu] Topic ID: ${topicId}, Yazar: ${authorName} (${creatorId}), Başlık: ${title}`);

    try {
      // user_fcm_tokens koleksiyonundaki tüm cihaz token'larını çek
      const tokensSnap = await admin.firestore().collection("user_fcm_tokens").get();
      if (tokensSnap.empty) {
        console.log("Kayıtlı FCM token bulunamadı.");
        return null;
      }

      const eligibleTokens = [];
      const staleDocIds = [];

      tokensSnap.forEach((doc) => {
        const data = doc.data();
        const docUserId = data.userId || doc.id;
        const token = data.token;

        // Kural: Konuyu AÇANA bildirim GİTMEYECEK, diğer kullanıcılara gidecek!
        if (docUserId !== creatorId && token && typeof token === "string") {
          // Bölgesel bir konuysa ve kullanıcının yeri eşleşmiyorsa filtrele (Genel ise herkese gider)
          if (!isGeneral && location && data.askerlikYeri) {
            if (data.askerlikYeri.trim().toLowerCase() !== location.trim().toLowerCase()) {
              return;
            }
          }
          eligibleTokens.push({ docId: doc.id, token: token.trim() });
        }
      });

      // Tekilleştirme (aynı token birden fazla cihaz kaydında varsa tek gönderim yap)
      const uniqueTokensMap = new Map();
      eligibleTokens.forEach((item) => {
        if (!uniqueTokensMap.has(item.token)) {
          uniqueTokensMap.set(item.token, item.docId);
        }
      });

      const tokensToSend = Array.from(uniqueTokensMap.keys());
      if (tokensToSend.length === 0) {
        console.log("Bildirim gönderilecek uygun başka kullanıcı token'ı bulunamadı.");
        return null;
      }

      console.log(`Toplam ${tokensToSend.length} kullanıcıya yeni konu bildirimi gönderiliyor.`);

      // FCM sendEachForMulticast maksimum 500 token alır, 500'lük partilerle gönderiyoruz
      for (let i = 0; i < tokensToSend.length; i += 500) {
        const batchTokens = tokensToSend.slice(i, i + 500);

        const message = {
          tokens: batchTokens,
          notification: {
            title: `📌 [${category}] ${title}`,
            body: `${authorName}: ${contentSnippet}`,
          },
          data: {
            type: "forum_topic",
            topicId: topicId,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "forum_notifications_channel",
              sound: "default",
              color: "#2563EB",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(`Parti gönderildi. Başarılı: ${response.successCount}, Hatalı: ${response.failureCount}`);

        // Geçersiz veya süresi dolmuş token'ları temizlik listesine ekle
        response.responses.forEach((resp, idx) => {
          if (!resp.success && resp.error) {
            const code = resp.error.code;
            if (
              code === "messaging/invalid-registration-token" ||
              code === "messaging/registration-token-not-registered"
            ) {
              const badToken = batchTokens[idx];
              const docId = uniqueTokensMap.get(badToken);
              if (docId) staleDocIds.push(docId);
            }
          }
        });
      }

      // Geçersiz token'ları Firestore'dan silerek sistemi optimize tut
      if (staleDocIds.length > 0) {
        const batch = admin.firestore().batch();
        staleDocIds.slice(0, 450).forEach((id) => {
          batch.delete(admin.firestore().collection("user_fcm_tokens").doc(id));
        });
        await batch.commit();
        console.log(`${staleDocIds.length} adet geçersiz token veri tabanından temizlendi.`);
      }

      return null;
    } catch (error) {
      console.error("onNewForumTopic hatası:", error);
      return null;
    }
  });

/**
 * 2. KONU SAHİBİNE YANIT BİLDİRİMİ
 * Bir forum konusuna yanıt yazıldığında tetiklenir.
 * Yalnızca ve sadece KONU SAHİBİNE bildirim gönderir.
 * (Yanıtı yazan bizzat konu sahibiyse bildirim gitmez).
 * Bildirime tıklandığında doğrudan o konu açılır.
 */
exports.onNewForumReply = functions.firestore
  .document("forum_topics/{topicId}/replies/{replyId}")
  .onCreate(async (snap, context) => {
    const { topicId, replyId } = context.params;
    const reply = snap.data();
    if (!reply) {
      console.log("Yanıt verisi boş, bildirim gönderilmedi.");
      return null;
    }

    const replierId = reply.senderId;
    const replierName = reply.senderName || "Bir Silah Arkadaşın";
    const replyContent = (reply.content || "").replace(/\n+/g, " ").trim();
    const snippet = replyContent.length > 90 ? replyContent.substring(0, 87) + "..." : replyContent;

    console.log(`[Yeni Yanıt] Topic: ${topicId}, Yanıtlayan: ${replierName} (${replierId})`);

    try {
      // Üst konuyu (parent topic) çek ve konu sahibini tespit et
      const topicDoc = await admin.firestore().collection("forum_topics").doc(topicId).get();
      if (!topicDoc.exists) {
        console.log(`Konu (${topicId}) bulunamadı.`);
        return null;
      }

      const topicData = topicDoc.data();
      const topicOwnerId = topicData.senderId;
      const topicTitle = topicData.title || "Konun";

      // Kural: Konu sahibi kendi konusuna yanıt yazdıysa bildirim gönderme!
      if (!topicOwnerId || topicOwnerId === replierId) {
        console.log("Yanıtı bizzat konu sahibi yazdı, bildirim atlanıyor.");
        return null;
      }

      // Konu sahibinin FCM token'ını bul (önce user_fcm_tokens, yoksa users tablosundan)
      let ownerToken = null;
      const tokenDoc = await admin.firestore().collection("user_fcm_tokens").doc(topicOwnerId).get();
      if (tokenDoc.exists && tokenDoc.data()?.token) {
        ownerToken = tokenDoc.data().token;
      } else {
        const userDoc = await admin.firestore().collection("users").doc(topicOwnerId).get();
        if (userDoc.exists && userDoc.data()?.fcmToken) {
          ownerToken = userDoc.data().fcmToken;
        }
      }

      if (!ownerToken) {
        console.log(`Konu sahibinin (${topicOwnerId}) kayıtlı FCM token'ı bulunamadı.`);
        return null;
      }

      const message = {
        token: ownerToken,
        notification: {
          title: `💬 ${replierName} konuna yanıt verdi`,
          body: `"${topicTitle}": ${snippet}`,
        },
        data: {
          type: "forum_topic_reply",
          topicId: topicId,
          replyId: replyId,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "forum_notifications_channel",
            sound: "default",
            color: "#2563EB",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`Konu sahibine (${topicOwnerId}) bildirim başarıyla iletildi: ${response}`);
      return null;
    } catch (error) {
      console.error("onNewForumReply hatası:", error);
      return null;
    }
  });

/**
 * 3. CANLI 1v1 DÜELLO MEYDAN OKUMA BİLDİRİMİ
 * quiz_duels koleksiyonunda yeni bir 'waiting' düello odası açıldığında tetiklenir.
 * Odayı açan kullanıcı haricindeki aktif kullanıcılara push bildirimi gönderir.
 * Bildirime tıklandığında kullanıcı doğrudan odaya katılır ve düello başlar.
 */
exports.onDuelChallengeCreated = functions.firestore
  .document("quiz_duels/{duelId}")
  .onCreate(async (snap, context) => {
    const duelId = context.params.duelId;
    const duel = snap.data();
    if (!duel || duel.status !== "waiting") {
      return null;
    }

    const host = duel.player1;
    if (!host) return null;

    const hostId = host.userId;
    const hostName = host.name || "Bir Yarışmacı";
    const hostRank = host.rank || "Asker";

    console.log(`[Canlı Düello] Yeni meydan okuma: ${duelId}, Kurucu: ${hostName} (${hostId})`);

    try {
      // 1. user_fcm_tokens koleksiyonundaki aktif kullanıcıları çek
      const tokensSnap = await admin.firestore().collection("user_fcm_tokens").get();
      if (tokensSnap.empty) {
        console.log("Kayıtlı FCM token bulunamadı.");
        return null;
      }

      const candidateTokens = [];
      tokensSnap.forEach((doc) => {
        const data = doc.data();
        const docUserId = data.userId || doc.id;
        const token = data.token;

        // Odayı açan kullanıcı hariç
        if (docUserId !== hostId && token && typeof token === "string") {
          candidateTokens.push({
            docId: doc.id,
            token: token.trim(),
            updatedAt: data.updatedAt ? data.updatedAt.toDate() : new Date(0),
          });
        }
      });

      if (candidateTokens.length === 0) {
        console.log("Bildirim gönderilecek uygun başka aktif kullanıcı bulunamadı.");
        return null;
      }

      // En son aktif olan kullanıcılara öncelik ver (sırala)
      candidateTokens.sort((a, b) => b.updatedAt - a.updatedAt);

      // Tekil token listesi oluştur (en aktif ilk 25 kullanıcıya gönder)
      const uniqueTokens = Array.from(new Set(candidateTokens.map((c) => c.token))).slice(0, 25);

      const message = {
        tokens: uniqueTokens,
        notification: {
          title: "⚔️ Canlı 1v1 Düello Meydan Okuması!",
          body: `${hostName} (${hostRank}) seninle Kim Milyoner Olmak İster düellosuna girmek istiyor! Katılmak için dokun.`,
        },
        data: {
          type: "quiz_duel_invite",
          duelId: duelId,
          hostName: hostName,
          hostRank: hostRank,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "forum_notifications_channel",
            sound: "default",
            color: "#F59E0B",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`Düello bildirimi gönderildi. Başarılı: ${response.successCount}, Hatalı: ${response.failureCount}`);
      return null;
    } catch (error) {
      console.error("onDuelChallengeCreated hatası:", error);
      return null;
    }
  });

/**
 * Türkçe akraba/yakın unvanını doğal iyelik ekiyle döndürür.
 * Örn: "es" -> "Eşin", "sevgili" -> "Sevgilin", "anne" -> "Annen"
 */
function getTurkishRelationshipTitle(rel) {
  if (!rel) return "Yakının";
  const lower = rel.toLowerCase().trim();
  if (lower.includes("eş") || lower === "es") return "Eşin";
  if (lower.includes("sevgil")) return "Sevgilin";
  if (lower.includes("anne")) return "Annen";
  if (lower.includes("baba")) return "Baban";
  if (lower.includes("kardeş") || lower === "kardes") return "Kardeşin";
  if (lower.includes("arkadaş") || lower === "arkadas") return "Arkadaşın";
  if (lower.includes("nişanl") || lower === "nisanli") return "Nişanlın";
  if (lower.includes("aile")) return "Ailen";
  return rel.charAt(0).toUpperCase() + rel.slice(1);
}

/**
 * 4. ZAMAN KAPSÜLÜ VE TAKVİM SÜRPRİZİ BİLDİRİMİ
 * tracking_codes/{trackingCode}/calendar_capsules/{capsuleId} dokümanı oluşturulduğunda veya güncellendiğinde tetiklenir.
 * - SADECE HEDEF ALICIYA bildirim gönderir (Gönderen asla kendi bildirimini almaz).
 * - Asker Yakını gönderdiyse: Derecesi ve ismiyle askere bildirim gider (Örn: "Eşin Ayşe Takvime Zaman Kapsülü Bıraktı!").
 * - Asker gönderdiyse: Takipçi yakınlara bildirim gider.
 */
exports.onCalendarCapsuleCreated = functions.firestore
  .document("tracking_codes/{trackingCode}/calendar_capsules/{capsuleId}")
  .onWrite(async (change, context) => {
    // 1. Doküman silindiyse bildirim gönderme
    if (!change.after.exists) {
      return null;
    }

    const { trackingCode, capsuleId } = context.params;
    const afterData = change.after.data();
    if (!afterData) return null;

    // 2. Eğer sadece kapsül açıldıysa veya içerik değişmediyse bildirim gönderme (Çift bildirim engeli)
    if (change.before.exists) {
      const beforeData = change.before.data() || {};
      const contentUnchanged =
        beforeData.note === afterData.note &&
        beforeData.audioBase64 === afterData.audioBase64 &&
        beforeData.imageBase64 === afterData.imageBase64 &&
        beforeData.dateKey === afterData.dateKey;

      if (contentUnchanged) {
        console.log(`[Zaman Kapsülü] İçerik değişmedi, bildirim atlandı. Capsule: ${capsuleId}`);
        return null;
      }
    }

    const senderRole = afterData.senderRole || "yakin";
    const senderUserId = afterData.senderUserId || "";
    const rawSenderName = (afterData.senderName || "").trim();
    const senderRelationship = (afterData.senderRelationship || "").trim();
    const dateKey = afterData.dateKey || "";
    const note = (afterData.note || "").trim();
    const hasAudio = !!afterData.audioBase64;
    const hasImage = !!afterData.imageBase64;
    const hasNote = note.length > 0;

    const trMonths = [
      "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
      "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ];
    let formattedDate = dateKey;
    try {
      const parts = dateKey.split("-");
      if (parts.length === 3) {
        const day = parseInt(parts[2], 10);
        const monthIdx = parseInt(parts[1], 10) - 1;
        const year = parts[0];
        formattedDate = `${day} ${trMonths[monthIdx] || parts[1]} ${year}`;
      }
    } catch (_) {}

    // Gönderen unvanını ve ismini Türkçe olarak doğal oluştur
    let displaySender;
    if (senderRole === "yakin") {
      const relTitle = getTurkishRelationshipTitle(senderRelationship || rawSenderName);
      if (rawSenderName && rawSenderName !== "Yakını" && rawSenderName !== "Asker Yakını" && !rawSenderName.toLowerCase().includes(relTitle.toLowerCase())) {
        displaySender = `${relTitle} ${rawSenderName}`;
      } else {
        displaySender = relTitle;
      }
    } else {
      displaySender = rawSenderName || "Askerin";
    }

    // Bildirim başlığı ve gövdesi
    let notifTitle = "";
    let notifBody = "";

    if (senderRole === "yakin") {
      notifTitle = `💌 ${displaySender} Takvime Zaman Kapsülü Bıraktı!`;
      if (hasAudio && hasImage) {
        notifBody = `🎙️📸 Sana özel sesli mesaj ve fotoğraf bıraktı! (${formattedDate}) 🔒`;
      } else if (hasAudio) {
        notifBody = `🎙️ Sana özel sesli bir mesaj kaydetti! (${formattedDate}) 🔒`;
      } else if (hasImage) {
        notifBody = `📸 Sana özel bir fotoğraf ve anı bıraktı! (${formattedDate}) 🔒`;
      } else if (hasNote) {
        const snippet = note.length > 70 ? note.substring(0, 67) + "..." : note;
        notifBody = `📝 "${snippet}" (${formattedDate}) 🔒`;
      } else {
        notifBody = `Takviminde sana özel yeni bir zaman kapsülü kilitledi! (${formattedDate}) 🔒`;
      }
    } else {
      notifTitle = `🎖️ Askerin ${displaySender} Takvime Anı Bıraktı!`;
      if (hasAudio && hasImage) {
        notifBody = `🎙️📸 Sana özel sesli mesaj ve fotoğraf ekledi! (${formattedDate}) 🔒`;
      } else if (hasAudio) {
        notifBody = `🎙️ Sana özel sesli mesaj kaydetti! (${formattedDate}) 🔒`;
      } else if (hasImage) {
        notifBody = `📸 Sana özel bir fotoğraf paylaştı! (${formattedDate}) 🔒`;
      } else if (hasNote) {
        const snippet = note.length > 70 ? note.substring(0, 67) + "..." : note;
        notifBody = `📝 "${snippet}" (${formattedDate}) 🔒`;
      } else {
        notifBody = `Askerlik takvimine senin için özel bir anı bıraktı! (${formattedDate}) 🔒`;
      }
    }

    console.log(`[Zaman Kapsülü] Gönderen: ${displaySender} (${senderRole}), Takip Kodu: ${trackingCode}, Tarih: ${dateKey}`);

    try {
      // 1. GÖNDERENİN KENDİ TOKEN'INI BUL (Gönderene asla bildirim gitmesin!)
      let senderToken = null;
      if (senderUserId) {
        try {
          const sDoc = await admin.firestore().collection("user_fcm_tokens").doc(senderUserId).get();
          if (sDoc.exists && sDoc.data()?.token) {
            senderToken = sDoc.data().token.trim();
          }
        } catch (_) {}
      }

      const recipientTokens = [];

      if (senderRole === "yakin") {
        // HEDEF: SADECE ASKER
        const trackingDoc = await admin.firestore().collection("tracking_codes").doc(trackingCode).get();
        if (trackingDoc.exists) {
          const trackingData = trackingDoc.data() || {};
          const soldierUserId = trackingData.userId;

          // 1. tracking_codes dokümanındaki direct fcmToken
          if (trackingData.fcmToken && typeof trackingData.fcmToken === "string") {
            recipientTokens.push(trackingData.fcmToken.trim());
          }

          // 2. user_fcm_tokens/{soldierUserId}
          if (soldierUserId && soldierUserId !== senderUserId) {
            try {
              const fcmDoc = await admin.firestore().collection("user_fcm_tokens").doc(soldierUserId).get();
              if (fcmDoc.exists && fcmDoc.data()?.token) {
                recipientTokens.push(fcmDoc.data().token.trim());
              }
            } catch (_) {}
          }

          // 3. user_fcm_tokens koleksiyonunda SADECE 'asker' rolünde olanlar
          try {
            const byCodeSnap = await admin
              .firestore()
              .collection("user_fcm_tokens")
              .where("trackingCode", "==", trackingCode)
              .where("role", "==", "asker")
              .get();
            byCodeSnap.forEach((doc) => {
              if (doc.id !== senderUserId && doc.data()?.token) {
                recipientTokens.push(doc.data().token.trim());
              }
            });
          } catch (_) {}
        }
      } else {
        // HEDEF: SADECE YAKINLAR (TAKİPÇİLER)
        const followersSnap = await admin
          .firestore()
          .collection("tracking_codes")
          .doc(trackingCode)
          .collection("followers")
          .get();

        for (const doc of followersSnap.docs) {
          const follower = doc.data();
          const followerId = follower.followerId || doc.id;
          if (followerId === senderUserId) continue; // Kendisine gönderme

          if (follower.fcmToken && typeof follower.fcmToken === "string") {
            recipientTokens.push(follower.fcmToken.trim());
          }

          const fcmDoc = await admin.firestore().collection("user_fcm_tokens").doc(followerId).get();
          if (fcmDoc.exists && fcmDoc.data()?.token) {
            recipientTokens.push(fcmDoc.data().token.trim());
          }
        }

        // trackingCode ile kayıtlı yakınları da ara
        try {
          const byRoleSnap = await admin
            .firestore()
            .collection("user_fcm_tokens")
            .where("trackingCode", "==", trackingCode)
            .where("role", "==", "yakin")
            .get();
          byRoleSnap.forEach((doc) => {
            if (doc.id !== senderUserId && doc.data()?.token) {
              recipientTokens.push(doc.data().token.trim());
            }
          });
        } catch (_) {}
      }

      // Tekil token listesi oluştur (Gönderenin kendi token'ını kesinlikle filtrele)
      const uniqueTokens = Array.from(new Set(recipientTokens.filter((t) => !!t && t.length > 10 && t !== senderToken)));
      if (uniqueTokens.length === 0) {
        console.log(`[Zaman Kapsülü] Hedef kullanıcı (${senderRole === "yakin" ? "Asker" : "Yakın"}) için kayıtlı token bulunamadı.`);
        return null;
      }

      console.log(`[Zaman Kapsülü] ${uniqueTokens.length} hedef cihaza anlık bildirim gönderiliyor.`);

      const message = {
        tokens: uniqueTokens,
        notification: {
          title: notifTitle,
          body: notifBody,
        },
        data: {
          type: "calendar_capsule",
          trackingCode: trackingCode,
          dateKey: dateKey,
          capsuleId: capsuleId,
          senderRole: senderRole,
          senderName: displaySender,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "forum_notifications_channel",
            sound: "default",
            color: "#F59E0B",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(`[Zaman Kapsülü] Bildirim sonucu: Başarılı: ${response.successCount}, Hatalı: ${response.failureCount}`);
      return null;
    } catch (error) {
      console.error("[Zaman Kapsülü] onCalendarCapsuleCreated hatası:", error);
      return null;
    }
  });

/**
 * 6. ASKER YAKINI EŞLEŞME BİLDİRİMİ
 * tracking_codes/{trackingCode}/followers/{followerId} dokümanı oluşturulduğunda tetiklenir.
 * SADECE ASKERE bildirim gönderir.
 * Bildirimde: Asker yakınının derecesi ve ismi yer alır.
 * Örn: "Eşin Ayşe şafağını takip etmeye başladı! 🪖💕"
 */
exports.onFollowerPaired = functions.firestore
  .document("tracking_codes/{trackingCode}/followers/{followerId}")
  .onWrite(async (change, context) => {
    // Sadece yeni takipçi eklendiğinde çalış
    if (!change.after.exists || change.before.exists) {
      return null;
    }

    const { trackingCode, followerId } = context.params;
    const data = change.after.data();
    if (!data) return null;

    const followerName = (data.name || "").trim();
    const relationship = (data.relationship || "").trim();
    const followerFcmToken = (data.fcmToken || "").trim();

    // Yakının Türkçe hitap unvanı
    const relTitle = getTurkishRelationshipTitle(relationship);
    let displayName = relTitle;
    if (followerName && followerName !== "Yakını" && !followerName.toLowerCase().includes(relTitle.toLowerCase())) {
      displayName = `${relTitle} ${followerName}`;
    }

    const title = "💕 Yeni Bir Yakının Şafağına Katıldı!";
    const body = `${displayName} şafağını takip etmeye başladı! Her an yanında! 🪖✨`;

    console.log(`[Eşleşme Bildirimi] Kod: ${trackingCode}, Takipçi: ${displayName} (${followerId})`);

    try {
      // SADECE ASKERİN TOKEN'INI BUL
      const trackingDoc = await admin.firestore().collection("tracking_codes").doc(trackingCode).get();
      if (!trackingDoc.exists) {
        console.log(`[Eşleşme Bildirimi] Takip kodu bulunamadı: ${trackingCode}`);
        return null;
      }

      const trackingData = trackingDoc.data() || {};
      const soldierUserId = trackingData.userId;
      const soldierTokens = [];

      // 1. tracking_codes dokümanındaki direkt fcmToken
      if (trackingData.fcmToken && typeof trackingData.fcmToken === "string") {
        soldierTokens.push(trackingData.fcmToken.trim());
      }

      // 2. user_fcm_tokens/{soldierUserId}
      if (soldierUserId && soldierUserId !== followerId) {
        try {
          const userFcmDoc = await admin.firestore().collection("user_fcm_tokens").doc(soldierUserId).get();
          if (userFcmDoc.exists && userFcmDoc.data()?.token) {
            soldierTokens.push(userFcmDoc.data().token.trim());
          }
        } catch (_) {}
      }

      // 3. user_fcm_tokens içinde trackingCode ve role === 'asker' olanlar
      try {
        const askerTokensSnap = await admin.firestore()
          .collection("user_fcm_tokens")
          .where("trackingCode", "==", trackingCode)
          .where("role", "==", "asker")
          .get();
        askerTokensSnap.forEach((doc) => {
          if (doc.id !== followerId && doc.data()?.token) {
            soldierTokens.push(doc.data().token.trim());
          }
        });
      } catch (_) {}

      // Takipçinin kendi token'ını kesinlikle filtrele
      const uniqueSoldierTokens = Array.from(new Set(soldierTokens.filter((t) => !!t && t.length > 10 && t !== followerFcmToken)));

      if (uniqueSoldierTokens.length === 0) {
        console.log(`[Eşleşme Bildirimi] Asker (${trackingCode}) için kayıtlı token bulunamadı.`);
        return null;
      }

      console.log(`[Eşleşme Bildirimi] Askere (${uniqueSoldierTokens.length} cihaz) bildirim gönderiliyor: ${body}`);

      const message = {
        tokens: uniqueSoldierTokens,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "follower_paired",
          trackingCode: trackingCode,
          followerId: followerId,
          followerName: displayName,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "forum_notifications_channel",
            sound: "default",
            color: "#EC4899",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      const resp = await admin.messaging().sendEachForMulticast(message);
      console.log(`[Eşleşme Bildirimi] Sonuç: Başarılı: ${resp.successCount}, Hatalı: ${resp.failureCount}`);
      return null;
    } catch (e) {
      console.error("[Eşleşme Bildirimi] Hata:", e);
      return null;
    }
  });

/**
 * 5. GÜNÜ GELEN ZAMAN KAPSÜLLERİNİ KONTROL ET VE BİLDİRİM GÖNDER
 * Ortak mantık: Bugün (veya verilen tarih) kilidi açılan, henüz açılmamış zaman kapsüllerini tarar
 * ve hedefe "Zaman kapsülünde bekleyen bir mesajın var!" bildirimi atar.
 */
async function processUnlockedCapsules(targetDateKey) {
  let todayKey = targetDateKey;
  if (!todayKey) {
    const now = new Date();
    // Türkiye saatine göre ayarla (UTC+3)
    const trDate = new Date(now.getTime() + 3 * 60 * 60 * 1000);
    const y = trDate.getUTCFullYear();
    const m = String(trDate.getUTCMonth() + 1).padStart(2, "0");
    const d = String(trDate.getUTCDate()).padStart(2, "0");
    todayKey = `${y}-${m}-${d}`;
  }

  console.log(`[Zaman Kapsülü Günlük Kontrol] Tarih: ${todayKey} için açılacak kapsüller taranıyor...`);

  try {
    const trackingCodesSnap = await admin.firestore().collection("tracking_codes").get();
    let sentCount = 0;
    let foundCount = 0;

    for (const tDoc of trackingCodesSnap.docs) {
      const trackingCode = tDoc.id;
      const tData = tDoc.data() || {};

      const capsulesSnap = await admin
        .firestore()
        .collection("tracking_codes")
        .doc(trackingCode)
        .collection("calendar_capsules")
        .where("dateKey", "==", todayKey)
        .get();

      for (const capDoc of capsulesSnap.docs) {
        const capsule = capDoc.data();
        if (capsule.isOpened) continue; // Açılmış olanları atla
        foundCount++;

        const senderName = capsule.senderName || (capsule.senderRole === "yakin" ? "Asker Yakını" : "Askerin");
        const senderRole = capsule.senderRole || "yakin";
        const capsuleId = capDoc.id;

        // Alıcının token'larını topla
        const recipientTokens = [];

        if (senderRole === "yakin") {
          // Askerin token'ını bul
          if (tData.fcmToken) recipientTokens.push(tData.fcmToken.trim());
          if (tData.userId) {
            try {
              const fDoc = await admin.firestore().collection("user_fcm_tokens").doc(tData.userId).get();
              if (fDoc.exists && fDoc.data()?.token) recipientTokens.push(fDoc.data().token.trim());
            } catch (_) {}
          }
          try {
            const byCode = await admin.firestore().collection("user_fcm_tokens").where("trackingCode", "==", trackingCode).get();
            byCode.forEach((d) => {
              if (d.data()?.token) recipientTokens.push(d.data().token.trim());
            });
          } catch (_) {}
        } else {
          // Takipçi yakınların token'larını bul
          try {
            const followersSnap = await admin.firestore().collection("tracking_codes").doc(trackingCode).collection("followers").get();
            followersSnap.forEach((fDoc) => {
              if (fDoc.data()?.fcmToken) recipientTokens.push(fDoc.data().fcmToken.trim());
            });
          } catch (_) {}
        }

        const uniqueTokens = Array.from(new Set(recipientTokens.filter((t) => !!t && t.length > 10)));
        if (uniqueTokens.length > 0) {
          const title = "🎉 Zaman Kapsülünün Kilidi Açıldı!";
          const body = `💌 ${senderName} tarafından zaman kapsülünde senin için bekleyen bir mesaj var! Görmek için dokun.`;

          const message = {
            tokens: uniqueTokens,
            notification: { title, body },
            data: {
              type: "calendar_capsule_unlocked",
              trackingCode: trackingCode,
              dateKey: todayKey,
              capsuleId: capsuleId,
              senderName: senderName,
              click_action: "FLUTTER_NOTIFICATION_CLICK",
            },
            android: {
              priority: "high",
              notification: {
                channelId: "forum_notifications_channel",
                sound: "default",
                color: "#F59E0B",
              },
            },
            apns: {
              payload: { aps: { sound: "default", badge: 1 } },
            },
          };

          await admin.messaging().sendEachForMulticast(message);
          sentCount += uniqueTokens.length;
          console.log(`[Zaman Kapsülü Günlük Kontrol] ${uniqueTokens.length} cihaza açılma bildirimi iletildi.`);
        }
      }
    }

    console.log(`[Zaman Kapsülü Günlük Kontrol] Toplam ${foundCount} kapsül bulundu, ${sentCount} cihaza bildirim atıldı.`);
    return { count: foundCount, sent: sentCount };
  } catch (error) {
    console.error("[Zaman Kapsülü Günlük Kontrol] Hata:", error);
    return { error: error.message };
  }
}

/**
 * 6. HER GÜN SABAH 09:00'DA ÇALIŞAN OTOMATİK ZAMAN KAPSÜLÜ BİLDİRİMİ
 */
exports.checkUnlockedCapsulesDaily = functions.pubsub
  .schedule("0 9 * * *")
  .timeZone("Europe/Istanbul")
  .onRun(async (context) => {
    await processUnlockedCapsules();
    return null;
  });

/**
 * 7. TEST VEYA MANUEL ÇAĞRI İÇİN HTTPS ENDPOINT
 * Kullanım: https://us-central1-safak-sayar-4e1cd.cloudfunctions.net/checkCapsulesNow
 */
exports.checkCapsulesNow = functions.https.onRequest(async (req, res) => {
  const dateKey = req.query.date || null;
  const result = await processUnlockedCapsules(dateKey);
  res.json({ success: true, date: dateKey || "today", result });
});

/**
 * 8. REVENUECAT SUNUCU WEBHOOK ENTEGRASYONU (ABONELİK YENİLENME & BİTİŞ SENKRONİZASYONU)
 * RevenueCat Dashboard -> Project Settings -> Integrations -> Webhooks kısmına
 * bu Cloud Function URL'si eklendiğinde uygulama kapalı olsa bile:
 * - Aylık / yıllık yeni abonelik ve yenilenmelerde (`INITIAL_PURCHASE`, `RENEWAL`, `UNCANCELLATION`):
 *   `users/{userId}.isPremium = true` ve yeni bitiş tarihi (`premiumExpiresAt`) güncellenir.
 * - Otomatik yenileme kapatıldığında (`CANCELLATION`):
 *   Ödenmiş dönem bitene kadar `isPremium = true` korunur, sadece `premiumWillRenew = false` yapılır.
 * - Abonelik süresi dolup yenilenmediğinde (`EXPIRATION`):
 *   `users/{userId}.isPremium = false` olarak durdurulur (manuel/süresiz tanımlı kullanıcılar korunur).
 */
exports.revenueCatWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method Not Allowed" });
  }

  // İsteğe bağlı güvenlik anahtarı kontrolü (REVENUECAT_WEBHOOK_SECRET tanımlıysa doğrular)
  const expectedSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
  if (expectedSecret) {
    const authHeader = req.headers.authorization || "";
    if (authHeader !== expectedSecret && authHeader !== `Bearer ${expectedSecret}`) {
      console.warn("[RevenueCat Webhook] Yetkisiz erişim denemesi engellendi.");
      return res.status(401).json({ error: "Unauthorized" });
    }
  }

  try {
    const event = req.body && req.body.event ? req.body.event : req.body;
    if (!event || !event.type) {
      return res.status(400).json({ error: "Invalid webhook payload" });
    }

    const eventType = event.type;
    if (eventType === "TEST") {
      console.log("[RevenueCat Webhook] Test bildirimi başarıyla alındı.");
      return res.status(200).json({ success: true, event: "TEST" });
    }

    const rawCandidates = [
      event.app_user_id,
      event.original_app_user_id,
      ...(Array.isArray(event.aliases) ? event.aliases : []),
    ].filter((id) => typeof id === "string" && id.trim().length > 0);

    // Anonim olmayan gerçek Firestore userId kimliklerine öncelik ver
    const candidateIds = Array.from(
      new Set(rawCandidates.filter((id) => !id.startsWith("$RCAnonymousID:")))
    );

    if (candidateIds.length === 0) {
      console.log(`[RevenueCat Webhook] Eşleşen uygulama userId bulunamadı (${eventType}).`);
      return res.status(200).json({ success: true, skipped: "anonymous_user" });
    }

    const nowMs = Date.now();
    const expirationMs =
      typeof event.expiration_at_ms === "number" ? event.expiration_at_ms : null;
    const graceExpirationMs =
      typeof event.grace_period_expiration_at_ms === "number"
        ? event.grace_period_expiration_at_ms
        : null;
    const productId = event.product_id || null;
    const periodType = event.period_type || null;

    const activeEventTypes = new Set([
      "INITIAL_PURCHASE",
      "RENEWAL",
      "UNCANCELLATION",
      "NON_RENEWING_PURCHASE",
      "PRODUCT_CHANGE",
      "SUBSCRIPTION_EXTENDED",
    ]);

    for (const userId of candidateIds) {
      const userRef = admin.firestore().collection("users").doc(userId);
      const userSnap = await userRef.get();
      const existingData = userSnap.exists ? userSnap.data() || {} : {};

      // Manuel / süresiz veya asker yakını olarak korunmuş kullanıcıların isPremium: true hakkını asla düşürme
      const isProtectedManual =
        existingData.isPremium === true &&
        (existingData.premiumSource === "manual" ||
          existingData.premiumSource === "lifetime" ||
          existingData.premiumSource === "relative_free_pro" ||
          existingData.user_role === "yakin");

      // Koruma altındaki (örneğin Asker Yakını) kullanıcı için iptal/süre dolumu gelirse dokunma
      if (isProtectedManual && !activeEventTypes.has(eventType)) {
        console.log(`[RevenueCat Webhook] Kullanıcı (${userId}) koruma altında (${existingData.user_role || existingData.premiumSource}). PRO durumu korunarak etkinlik atlandı.`);
        continue;
      }

      let nextIsPremium = null;
      let nextStatus = null;
      let nextWillRenew = null;

      if (activeEventTypes.has(eventType)) {
        const stillValid = expirationMs === null || expirationMs > nowMs;
        nextIsPremium = stillValid;
        nextStatus = stillValid ? "active" : "expired";
        nextWillRenew = eventType !== "NON_RENEWING_PURCHASE";
      } else if (eventType === "CANCELLATION") {
        // Mağaza iadesi (CUSTOMER_SUPPORT) ise anında düşür;
        // normal iptalde ödenmiş dönem (aylık/yıllık) bitene kadar koru, bittiğinde EXPIRATION düşürür.
        const isImmediateRefund = event.cancel_reason === "CUSTOMER_SUPPORT";
        if (!isImmediateRefund && expirationMs !== null && expirationMs > nowMs) {
          nextIsPremium = true;
          nextStatus = "cancelled_active_until_expiry";
          nextWillRenew = false;
        } else if (!isProtectedManual) {
          nextIsPremium = false;
          nextStatus = isImmediateRefund ? "refunded_or_revoked" : "cancelled_expired";
          nextWillRenew = false;
        }
      } else if (eventType === "BILLING_ISSUE") {
        // Ödeme alınamadı: Mağaza ek tahsilat süresi (grace period) devam ediyorsa koru,
        // süre bittiyse / tahsilat tamamen başarısızsa isPremium = false yap!
        const inGrace =
          (graceExpirationMs !== null && graceExpirationMs > nowMs) ||
          (expirationMs !== null && expirationMs > nowMs);
        if (inGrace) {
          nextIsPremium = true;
          nextStatus = "billing_retry";
          nextWillRenew = true;
        } else if (!isProtectedManual) {
          nextIsPremium = false;
          nextStatus = "payment_failed";
          nextWillRenew = false;
        }
      } else if (eventType === "SUBSCRIPTION_PAUSED") {
        if (!isProtectedManual && (expirationMs === null || expirationMs <= nowMs)) {
          nextIsPremium = false;
          nextStatus = "paused";
          nextWillRenew = false;
        }
      } else if (eventType === "EXPIRATION") {
        if (!isProtectedManual) {
          nextIsPremium = false;
          nextStatus =
            event.expiration_reason === "BILLING_ERROR" ||
            event.cancel_reason === "BILLING_ERROR"
              ? "payment_failed"
              : event.expiration_reason === "UNSUBSCRIBE" ||
                event.cancel_reason === "UNSUBSCRIBE"
              ? "cancelled_expired"
              : "expired";
          nextWillRenew = false;
        }
      }

      if (nextIsPremium === null) {
        continue;
      }

      const expiresTimestamp =
        expirationMs !== null
          ? admin.firestore.Timestamp.fromMillis(expirationMs)
          : null;
      const expiresIso =
        expirationMs !== null ? new Date(expirationMs).toISOString() : null;

      const updatePayload = {
        isPremium: nextIsPremium,
        premiumSource: "revenuecat",
        premiumStatus: nextStatus,
        premiumWillRenew: nextWillRenew,
        premiumExpiresAt: expiresTimestamp,
        premiumExpiresAtIso: expiresIso,
        ...(nextIsPremium === false && expiresIso
          ? { premiumExpiredAtIso: expiresIso }
          : {}),
        ...(productId ? { premiumProductId: productId } : {}),
        ...(periodType ? { premiumPeriodType: periodType } : {}),
        premiumLastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        quiz_stats: {
          ...(existingData.quiz_stats || {}),
          isPremium: nextIsPremium,
        },
      };

      await userRef.set(updatePayload, { merge: true });

      // Lider tablosundaki VIP rozetini de eşzamanlı güncelle
      const leaderRef = admin.firestore().collection("quiz_leaderboard").doc(userId);
      const leaderSnap = await leaderRef.get();
      if (leaderSnap.exists) {
        await leaderRef.set({ isPremium: nextIsPremium }, { merge: true });
      }

      console.log(
        `[RevenueCat Webhook] User: ${userId}, Event: ${eventType} -> isPremium: ${nextIsPremium} (${nextStatus})`
      );
    }

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error("[RevenueCat Webhook] Hata:", error);
    return res.status(500).json({ error: error.message });
  }
});




