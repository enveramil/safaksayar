# 🇹🇷 Şafak Sayar • Canlı Analitik & Kullanıcı Yönetim Paneli (Web Dashboard)

Şafak Sayar mobil uygulaması için özel olarak sıfırdan geliştirilmiş, yüksek performanslı web tabanlı analitik, büyüme (growth) ve kullanıcı yönetim paneli.

---

## 🚀 Öne Çıkan Özellikler

1. **📊 Günlük Etkileşim & Oturumlar (DAU & Hourly Spikes):**
   - 24 saatlik etkileşim yoğunluk grafiği (Sabah içtiması, öğle istirahati ve 20:00–22:00 koğuş zirve saatleri).
   - Günlük aktif kullanıcı (DAU), ortalama ekran süresi ve toplam işlem hacmi.

2. **⏱️ Kullanıcı Bazında Günlük Ekran Süresi:**
   - Hangi kullanıcının bugün uygulama içinde kaç dakika/saniye geçirdiğinin anlık dökümü.
   - İsim, rol (Asker vs Asker Yakını), rütbe, kışla ve şehir bazında arama ve filtreleme.

3. **📱 Modül & Ekran Bazında Zaman Analizi:**
   - Şafak Sayacı, Kim Milyoner Olmak İster & Canlı Düello, Asker Forumu, Zaman Kapsülü, Temalar ve Anı Defteri modüllerinde harcanan birikimli süreler ve ortalama oturum süreleri.

4. **❤️ Sadık Kullanıcılar & Retention (Tutundurma) Matrisi:**
   - D1, D3, D7, D14 ve D30 kohort tutundurma oranları.
   - Sadakat Serisi (Streak): 15+ gün, 7–14 gün kesintisiz şafak atan kullanıcı kademeleri.

5. **🎯 PRO Abone Olma İhtimali Yüksek Kullanıcılar (Lead Scoring):**
   - Düello haklarını tüketen, özel fotoğraf arka planını veya kilitli komando temasını deneyen ve günlük 20+ dakika aktif olan potansiyel PRO adaylarının algoritmik tespiti.
   - Özel bildirim veya indirim kampanyası tetikleme simülasyonu.

6. **👑 PRO Kullanıcı Yönetimi & Dağılımı:**
   - Yıllık, Aylık ve Asker Yakınlarına özel tanımlanan 100% Ücretsiz & Reklamsız PRO üyeliklerin dökümü.

7. **⚡ Çift Veri Modu (Canlı Firestore & Demo Veri):**
   - Sağ üstteki tek bir anahtarla **Demo Veri** ile **Canlı Firebase Firestore** verisi arasında anında geçiş yapabilme.

8. **📖 Mobil Telemetri SDK Rehberi:**
   - Mobil uygulamayı sürekli geliştirirken Firestore'a hangi logların nasıl atılacağını gösteren kopyalanabilir Flutter kodları.

---

## 🛠️ Kurulum & Çalıştırma

### 1. Geliştirme Sunucusunu Başlatma
```bash
cd dashboard
npm install
npm run dev
```
Uygulama varsayılan olarak `http://localhost:3000` adresinde açılacaktır.

### 2. Canlı Firebase Yapılandırması (İsteğe Bağlı)
Panel varsayılan olarak `safak-sayar-4e1cd` projesine bağlıdır. İsterseniz `dashboard/.env` dosyası oluşturup özel anahtarlarınızı tanımlayabilirsiniz:
```env
VITE_FIREBASE_API_KEY=your_api_key
VITE_FIREBASE_PROJECT_ID=safak-sayar-4e1cd
```

### 3. Canlıya Alma (Deploy)
- **Vercel:** `dashboard` klasörünü Vercel'e bağlayıp tek tıkla yayınlayabilirsiniz.
- **Firebase Hosting:**
  ```bash
  npm run build
  firebase deploy --only hosting
  ```

