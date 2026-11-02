import React from 'react';
import {
  Crown,
  Heart,
  Calendar,
  CreditCard,
  CheckCircle,
  AlertCircle,
  ShieldAlert,
} from 'lucide-react';

export default function ProSubscribersCard({ users, subscribersSummary }) {
  if (!users) return null;

  // Filter accurately by verified subscriptionCategory
  const proUsers = users.filter((u) => u.isPremium);
  const annualUsers = users.filter((u) => u.isPremium && u.subscriptionCategory === 'annual');
  const monthlyUsers = users.filter((u) => u.isPremium && u.subscriptionCategory === 'monthly');
  const relativeFreeUsers = users.filter((u) => u.isPremium && u.subscriptionCategory === 'relative_free');
  const manualTestUsers = users.filter(
    (u) => u.isPremium && (u.subscriptionCategory === 'manual_test' || u.subscriptionCategory === 'store_other')
  );

  const annualRevenue = annualUsers.length * 499;
  const monthlyRevenue = Math.round(monthlyUsers.length * 69.99);

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
        <div>
          <h2 className="text-lg font-bold text-white flex items-center space-x-2">
            <Crown className="w-5 h-5 text-purple-400" />
            <span>Gerçek PRO Aboneler & Ayrıcalık Dağılımı</span>
          </h2>
          <p className="text-xs text-gray-400">
            Firestore'daki doğrulanmış App Store abonelikleri ve asker yakını ücretsiz üyeliklerinin dökümü.
          </p>
        </div>
        <span className="px-3 py-1 rounded-full text-xs font-bold bg-purple-500/10 text-purple-300 border border-purple-500/30">
          Toplam {proUsers.length} Doğrulanmış PRO
        </span>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Yıllık */}
        <div className="p-4 rounded-xl bg-[#131620] border border-purple-500/30 flex items-center justify-between">
          <div>
            <span className="text-xs text-gray-400 font-medium">Yıllık PRO (Store)</span>
            <div className="text-2xl font-black text-white mt-1">
              {annualUsers.length} Üye
            </div>
            <span className="text-[11px] text-purple-400 font-semibold block mt-0.5">
              {annualUsers.length > 0 ? `Tahmini Gelir: ₺${annualRevenue} / Yıl` : 'Henüz Yıllık Satış Yok (₺0)'}
            </span>
          </div>
          <div className="p-3 rounded-xl bg-purple-500/10 text-purple-400">
            <CreditCard className="w-5 h-5" />
          </div>
        </div>

        {/* Aylık */}
        <div className="p-4 rounded-xl bg-[#131620] border border-blue-500/30 flex items-center justify-between">
          <div>
            <span className="text-xs text-gray-400 font-medium">Aylık PRO (Store)</span>
            <div className="text-2xl font-black text-white mt-1">
              {monthlyUsers.length} Üye
            </div>
            <span className="text-[11px] text-blue-400 font-semibold block mt-0.5">
              {monthlyUsers.length > 0 ? `Tahmini Gelir: ₺${monthlyRevenue} / Ay` : 'Henüz Aylık Satış Yok (₺0)'}
            </span>
          </div>
          <div className="p-3 rounded-xl bg-blue-500/10 text-blue-400">
            <Calendar className="w-5 h-5" />
          </div>
        </div>

        {/* Asker Yakını Ücretsiz PRO */}
        <div className="p-4 rounded-xl bg-[#131620] border border-emerald-500/30 flex items-center justify-between">
          <div>
            <span className="text-xs text-gray-400 font-medium">Asker Yakını Ayrıcalığı</span>
            <div className="text-2xl font-black text-emerald-400 mt-1">
              {relativeFreeUsers.length} Ücretsiz PRO
            </div>
            <span className="text-[11px] text-emerald-300 font-semibold block mt-0.5">
              100% Ücretsiz & Reklamsız
            </span>
          </div>
          <div className="p-3 rounded-xl bg-emerald-500/10 text-emerald-400">
            <Heart className="w-5 h-5" />
          </div>
        </div>

        {/* Test / Manuel Tanımlı */}
        <div className="p-4 rounded-xl bg-[#131620] border border-amber-500/30 flex items-center justify-between">
          <div>
            <span className="text-xs text-gray-400 font-medium">Manuel / Test PRO</span>
            <div className="text-2xl font-black text-amber-300 mt-1">
              {manualTestUsers.length} Üye
            </div>
            <span className="text-[11px] text-amber-400 font-semibold block mt-0.5">
              Geliştirici / Test Kayıtları
            </span>
          </div>
          <div className="p-3 rounded-xl bg-amber-500/10 text-amber-400">
            <ShieldAlert className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Subscriber List Table */}
      <div className="bg-[#131620] border border-[#1F2433] rounded-2xl overflow-hidden shadow-xl">
        {proUsers.length === 0 ? (
          <div className="p-8 text-center text-xs text-gray-400 space-y-2">
            <AlertCircle className="w-8 h-8 text-gray-500 mx-auto" />
            <p className="font-bold text-gray-300">Firestore veritabanında henüz PRO üye bulunamadı.</p>
            <p className="text-[11px]">Gerçek kullanıcılar App Store üzerinden satın alma yaptığında veya Asker Yakını olarak eşleştiğinde burada görüntülenecektir.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-[#1F2433] bg-[#0E1118]/70 text-[11px] uppercase tracking-wider text-gray-400">
                  <th className="py-3 px-4">Kullanıcı</th>
                  <th className="py-3 px-4">Doğrulanmış Üyelik Türü</th>
                  <th className="py-3 px-4">Kaynak (Source)</th>
                  <th className="py-3 px-4">Durum (Status)</th>
                  <th className="py-3 px-4 text-right">Bitiş Tarihi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1F2433]/60 text-xs">
                {proUsers.map((user) => (
                  <tr key={user.userId} className="hover:bg-[#181D2C] transition-colors">
                    <td className="py-3 px-4">
                      <div className="flex items-center space-x-2.5">
                        <div className="w-8 h-8 rounded-lg bg-purple-600/20 text-purple-400 flex items-center justify-center font-bold">
                          {user.name.charAt(0)}
                        </div>
                        <div>
                          <div className="font-bold text-white flex items-center space-x-1">
                            <span>{user.name}</span>
                            <Crown className="w-3 h-3 text-amber-400 fill-amber-400" />
                          </div>
                          <span className="text-[10px] text-gray-400">{user.roleLabel} • {user.city}</span>
                        </div>
                      </div>
                    </td>
                    <td className="py-3 px-4 font-semibold text-gray-200">
                      <span
                        className={`inline-flex items-center px-2 py-0.5 rounded text-[11px] font-bold ${
                          user.subscriptionCategory === 'annual'
                            ? 'bg-purple-500/20 text-purple-300 border border-purple-500/30'
                            : user.subscriptionCategory === 'monthly'
                            ? 'bg-blue-500/20 text-blue-300 border border-blue-500/30'
                            : user.subscriptionCategory === 'relative_free'
                            ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                            : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                        }`}
                      >
                        {user.subscriptionLabel}
                      </span>
                    </td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded bg-[#1B202E] text-gray-300 font-mono text-[11px] border border-[#272E42]">
                        {user.premiumSource || 'yok'}
                      </span>
                    </td>
                    <td className="py-3 px-4">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                        <CheckCircle className="w-3 h-3 mr-1" />
                        {user.premiumStatus || 'Aktif'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right font-mono text-[11px] text-gray-300">
                      {user.subscriptionCategory === 'relative_free'
                        ? 'Süresiz (Asker Yakını)'
                        : user.premiumExpiresAt
                        ? user.premiumExpiresAt.toLocaleDateString('tr-TR')
                        : 'Belirtilmedi'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
