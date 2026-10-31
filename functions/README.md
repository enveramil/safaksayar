# Asker Forumu - Firebase Cloud Functions

Bu dizin, forumdaki yeni konular ve yanıtlar için otomatik push bildirimleri gönderen Cloud Functions kodlarını içerir.

## Özellikler

1. **`onNewForumTopic`**:
   - `forum_topics/{topicId}` koleksiyonunda yeni konu açıldığında tetiklenir.
   - Konuyu açan kullanıcı **hariç** diğer tüm kayıtlı kullanıcılara push bildirimi gönderir.
   - Bildirime basıldığında doğrudan o konu detay ekranı açılır (`topicId` verisi taşır).
   - Geçersiz/eski token'ları otomatik olarak veri tabanından temizler.

2. **`onNewForumReply`**:
   - `forum_topics/{topicId}/replies/{replyId}` koleksiyonuna yanıt eklendiğinde tetiklenir.
   - **Yalnızca ve sadece konunun sahibine** bildirim gönderir.
   - Konu sahibi kendi konusuna yanıt verdiğinde bildirim gönderilmez.
   - Bildirime basıldığında doğrudan ilgili konu açılır.

## Kurulum ve Dağıtım (Deploy)

1. `functions` dizininde bağımlılıkları yükleyin:
   ```bash
   cd functions
   npm install
   ```

2. Firebase CLI ile projeye giriş yapın (gerekliyse):
   ```bash
   firebase login
   ```

3. Fonksiyonları Firebase'e yükleyin:
   ```bash
   firebase deploy --only functions
   ```
