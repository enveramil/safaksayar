import React, { useState } from 'react';
import {
  Code2,
  Copy,
  Check,
  Smartphone,
  Database,
  Layers,
  ArrowRight,
} from 'lucide-react';

export default function MobileTelemetryGuide() {
  const [copiedIndex, setCopiedIndex] = useState(null);

  const handleCopy = (code, index) => {
    navigator.clipboard.writeText(code);
    setCopiedIndex(index);
    setTimeout(() => setCopiedIndex(null), 2000);
  };

  const flutterSnippet1 = `// 1. Ekran Süresi Telemetrisi (Flutter - LogService)
void onPageExit(String pageName, int durationSeconds) async {
  final userId = prefs.getString('userId');
  
  // A. logs koleksiyonuna anlık log atar
  await FirebaseFirestore.instance.collection('logs').add({
    'userId': userId,
    'pageName': pageName,          // Örn: 'Kim Milyoner', 'Asker Forumu'
    'duration': durationSeconds,    // Harcanan saniye
    'eventType': 'süre_harcandı',
    'timestamp': FieldValue.serverTimestamp(),
  });

  // B. users tablosunda kullanıcının günlük toplam süresini artırır
  await FirebaseFirestore.instance.collection('users').doc(userId).set({
    'todayScreenTimeSeconds': FieldValue.increment(durationSeconds),
    'lastActiveAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}`;

  const flutterSnippet2 = `// 2. Modül Bazında Oturum Kaydı
void logModuleEngagement({
  required String moduleId,       // Örn: 'millionaire_quiz', 'calendar_capsule'
  required String moduleName,     // 'Kim Milyoner & Canlı Düello'
  required int durationSeconds,
}) async {
  final pageRef = FirebaseFirestore.instance.collection('page_stats').doc(moduleName);
  await FirebaseFirestore.instance.runTransaction((tx) async {
    final doc = await tx.get(pageRef);
    final current = (doc.data()?['totalSeconds'] as int?) ?? 0;
    tx.set(pageRef, {
      'pageName': moduleName,
      'totalSeconds': current + durationSeconds,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });
}`;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-lg font-bold text-white flex items-center space-x-2">
          <Smartphone className="w-5 h-5 text-blue-400" />
          <span>Mobil Uygulama Telemetri Sözleşmesi & Rehberi</span>
        </h2>
        <p className="text-xs text-gray-400">
          Bu dashboard panelini canlı verilerle beslemek için mobil uygulamada uygulanacak Firestore telemetri şeması ve kod örnekleri.
        </p>
      </div>

      {/* Schema Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="p-4 rounded-xl bg-[#131620] border border-[#1F2433] space-y-2">
          <div className="flex items-center space-x-2 text-blue-400 font-bold text-xs">
            <Database className="w-4 h-4" />
            <span>Koleksiyon: users</span>
          </div>
          <p className="text-[11px] text-gray-400 leading-relaxed">
            Kullanıcının profil bilgileri, rolü (<code className="text-blue-300">asker</code> / <code className="text-pink-300">yakin</code>), <code className="text-amber-300">isPremium</code> durumu, günlük toplam ekran süresi ve sadakat serisi (<code className="text-emerald-300">streakDays</code>).
          </p>
        </div>

        <div className="p-4 rounded-xl bg-[#131620] border border-[#1F2433] space-y-2">
          <div className="flex items-center space-x-2 text-purple-400 font-bold text-xs">
            <Layers className="w-4 h-4" />
            <span>Koleksiyon: logs</span>
          </div>
          <p className="text-[11px] text-gray-400 leading-relaxed">
            Kullanıcının her ekran/modülden çıkışında harcadığı saniyeyi (<code className="text-purple-300">duration</code>) ve dokunma etkileşimlerini saklayan zaman serisi logları.
          </p>
        </div>

        <div className="p-4 rounded-xl bg-[#131620] border border-[#1F2433] space-y-2">
          <div className="flex items-center space-x-2 text-emerald-400 font-bold text-xs">
            <Code2 className="w-4 h-4" />
            <span>Koleksiyon: page_stats</span>
          </div>
          <p className="text-[11px] text-gray-400 leading-relaxed">
            Modül bazında (Şafak Sayacı, Düello, Forum vb.) tüm kullanıcıların birikimli olarak harcadığı toplam süreyi (<code className="text-emerald-300">totalSeconds</code>) tutan optimize edilmiş özet tablosu.
          </p>
        </div>
      </div>

      {/* Code Snippets */}
      <div className="space-y-4">
        {/* Snippet 1 */}
        <div className="bg-[#131620] border border-[#1F2433] rounded-2xl overflow-hidden">
          <div className="px-4 py-3 bg-[#0E1118]/80 border-b border-[#1F2433] flex items-center justify-between">
            <span className="text-xs font-mono font-bold text-gray-300">
              1. Kullanıcı Bazlı Ekran Süresi Loglama (Flutter)
            </span>
            <button
              onClick={() => handleCopy(flutterSnippet1, 1)}
              className="flex items-center space-x-1 px-2.5 py-1 rounded bg-[#1A1F2E] hover:bg-[#252C40] text-gray-300 text-xs transition-all"
            >
              {copiedIndex === 1 ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-400" />
                  <span className="text-emerald-400">Kopyalandı</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" />
                  <span>Kodu Kopyala</span>
                </>
              )}
            </button>
          </div>
          <pre className="p-4 text-xs font-mono text-gray-200 overflow-x-auto bg-[#0A0C11] leading-relaxed">
            <code>{flutterSnippet1}</code>
          </pre>
        </div>

        {/* Snippet 2 */}
        <div className="bg-[#131620] border border-[#1F2433] rounded-2xl overflow-hidden">
          <div className="px-4 py-3 bg-[#0E1118]/80 border-b border-[#1F2433] flex items-center justify-between">
            <span className="text-xs font-mono font-bold text-gray-300">
              2. Modül & Ekran Bazında Birikimli Süre Güncelleme (Transaction)
            </span>
            <button
              onClick={() => handleCopy(flutterSnippet2, 2)}
              className="flex items-center space-x-1 px-2.5 py-1 rounded bg-[#1A1F2E] hover:bg-[#252C40] text-gray-300 text-xs transition-all"
            >
              {copiedIndex === 2 ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-400" />
                  <span className="text-emerald-400">Kopyalandı</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" />
                  <span>Kodu Kopyala</span>
                </>
              )}
            </button>
          </div>
          <pre className="p-4 text-xs font-mono text-gray-200 overflow-x-auto bg-[#0A0C11] leading-relaxed">
            <code>{flutterSnippet2}</code>
          </pre>
        </div>
      </div>
    </div>
  );
}

