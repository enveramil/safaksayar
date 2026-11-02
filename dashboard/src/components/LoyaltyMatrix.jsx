import React from 'react';
import {
  Heart,
  Flame,
  CalendarCheck,
} from 'lucide-react';

export default function LoyaltyMatrix({ cohorts, users }) {
  if (!cohorts) return null;

  const totalUsers = users ? users.length : 0;
  const tier1Count = users ? users.filter((u) => u.weeklyStreak >= 15).length : 0;
  const tier2Count = users ? users.filter((u) => u.weeklyStreak >= 7 && u.weeklyStreak < 15).length : 0;
  const tier3Count = users ? users.filter((u) => u.weeklyStreak >= 3 && u.weeklyStreak < 7).length : 0;
  const tier4Count = users ? users.filter((u) => u.weeklyStreak < 3).length : 0;

  const tiers = [
    { name: 'Efsanevi (Tier 1)', streak: '15+ Gün Kesintisiz', count: `${tier1Count} Kullanıcı`, color: 'text-amber-400', bg: 'bg-amber-500/10' },
    { name: 'Çok Sadık (Tier 2)', streak: '7 - 14 Gün', count: `${tier2Count} Kullanıcı`, color: 'text-purple-400', bg: 'bg-purple-500/10' },
    { name: 'Sadık (Tier 3)', streak: '3 - 6 Gün', count: `${tier3Count} Kullanıcı`, color: 'text-blue-400', bg: 'bg-blue-500/10' },
    { name: 'Yeni / Ara Sıra (Tier 4)', streak: '1 - 2 Gün', count: `${tier4Count} Kullanıcı`, color: 'text-gray-400', bg: 'bg-gray-500/10' },
  ];

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div>
        <h2 className="text-lg font-bold text-white flex items-center space-x-2">
          <Heart className="w-5 h-5 text-pink-400" />
          <span>Sadık Kullanıcılar & Tutundurma (Retention) Matrisi</span>
        </h2>
        <p className="text-xs text-gray-400">
          Gerçek Firestore kullanıcılarının şafak atma serileri ve kohort bazlı uygulamaya dönme oranları.
        </p>
      </div>

      {/* 4 Real Tier Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {tiers.map((t, idx) => (
          <div
            key={idx}
            className="p-4 rounded-xl bg-[#131620] border border-[#1F2433] flex items-center space-x-3"
          >
            <div className={`p-3 rounded-xl ${t.bg} ${t.color}`}>
              <Flame className="w-6 h-6 fill-current" />
            </div>
            <div>
              <span className="text-[11px] text-gray-400 block font-medium">
                {t.name}
              </span>
              <div className="text-base font-black text-white mt-0.5">
                {t.count}
              </div>
              <span className="text-[10px] text-gray-500">{t.streak}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Retention Cohort Table */}
      <div className="bg-[#131620] border border-[#1F2433] rounded-2xl overflow-hidden shadow-xl">
        <div className="p-4 border-b border-[#1F2433] bg-[#0E1118]/70 flex items-center justify-between">
          <span className="text-xs font-bold text-gray-300 uppercase tracking-wider flex items-center space-x-2">
            <CalendarCheck className="w-4 h-4 text-emerald-400" />
            <span>Kayıt Tarihine Göre Kohort Tutundurma (Gerçek Veri)</span>
          </span>
          <span className="text-[11px] text-emerald-400 font-bold bg-emerald-500/10 px-2.5 py-1 rounded-full border border-emerald-500/20">
            Toplam {totalUsers} Kullanıcı İncelendi
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#1F2433] text-[11px] text-gray-400 uppercase">
                <th className="py-3 px-4">Kohort Grubu</th>
                <th className="py-3 px-4">Kullanıcı Sayısı</th>
                <th className="py-3 px-4 text-center">1. Gün (D1)</th>
                <th className="py-3 px-4 text-center">3. Gün (D3)</th>
                <th className="py-3 px-4 text-center">7. Gün (D7)</th>
                <th className="py-3 px-4 text-center">14. Gün (D14)</th>
                <th className="py-3 px-4 text-center">30. Gün (D30)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1F2433]/60 text-xs">
              {cohorts.map((c, i) => (
                <tr key={i} className="hover:bg-[#181D2C] transition-colors">
                  <td className="py-3 px-4 font-bold text-white">{c.cohort}</td>
                  <td className="py-3 px-4 text-gray-300">{c.newUsers} Kullanıcı</td>
                  <td className="py-3 px-4 text-center">
                    <span className="px-2.5 py-1 rounded-md bg-blue-500/20 text-blue-300 font-bold">
                      {c.d1}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-center">
                    <span className="px-2.5 py-1 rounded-md bg-blue-500/15 text-blue-300 font-bold">
                      {c.d3}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-center">
                    <span className="px-2.5 py-1 rounded-md bg-emerald-500/15 text-emerald-300 font-bold">
                      {c.d7}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-center">
                    <span className="px-2.5 py-1 rounded-md bg-emerald-500/10 text-emerald-400 font-bold">
                      {c.d14}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-center">
                    <span className="px-2.5 py-1 rounded-md bg-purple-500/10 text-purple-300 font-bold">
                      {c.d30}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
