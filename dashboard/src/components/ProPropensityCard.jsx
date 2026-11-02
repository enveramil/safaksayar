import React, { useState } from 'react';
import {
  Crown,
  Zap,
  Flame,
  Send,
  Sparkles,
  CheckCircle2,
  TrendingUp,
  Target,
  Search,
  SlidersHorizontal,
  Clock,
  Shield,
  Heart,
  ChevronRight,
  Check,
} from 'lucide-react';

export default function ProPropensityCard({ users, onSelectUser }) {
  const [minScore, setMinScore] = useState(50);
  const [search, setSearch] = useState('');
  const [notifiedUsers, setNotifiedUsers] = useState({});

  if (!users) return null;

  // Filter non-premium users with conversionScore >= minScore
  const allLeads = users
    .filter((u) => !u.isPremium && (u.conversionScore || 0) >= minScore)
    .sort((a, b) => (b.conversionScore || 0) - (a.conversionScore || 0));

  const filteredLeads = allLeads.filter((u) => {
    if (!search.trim()) return true;
    const q = search.toLocaleLowerCase('tr-TR');
    return (
      (u.name && u.name.toLocaleLowerCase('tr-TR').includes(q)) ||
      (u.trackingCode && u.trackingCode.toLocaleLowerCase('tr-TR').includes(q)) ||
      (u.location && u.location.toLocaleLowerCase('tr-TR').includes(q)) ||
      (u.rank && u.rank.toLocaleLowerCase('tr-TR').includes(q))
    );
  });

  const handleNotify = (userId, name) => {
    setNotifiedUsers((prev) => ({ ...prev, [userId]: true }));
    setTimeout(() => {
      alert(`[Özel Teklif İletildi]: "${name}" kullanıcısına %30 İndirimli Yıllık PRO ve Canlı Düello avantajı bildirimi başarıyla planlandı.`);
    }, 100);
  };

  return (
    <div className="space-y-4">
      {/* Header & Controls */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 p-5 rounded-2xl bg-[#131620] border border-amber-500/20 shadow-xl shadow-amber-500/5">
        <div>
          <h2 className="text-lg font-bold text-white flex items-center space-x-2">
            <Target className="w-5 h-5 text-amber-400" />
            <span>PRO Abone Olma İhtimali En Yüksek Kullanıcılar (Lead Scoring)</span>
          </h2>
          <p className="text-xs text-gray-400 mt-1">
            Paywall incelemesi, oyun düellosu, özel tema tıklamaları ve ekran süresine göre tespit edilen yüksek dönüşüm adayları.
          </p>
        </div>

        {/* Filters & Search */}
        <div className="flex flex-wrap items-center gap-2">
          {/* Search Box */}
          <div className="relative">
            <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="İsim veya kod ara..."
              className="bg-[#181C2A] border border-[#262D40] rounded-xl pl-8 pr-3 py-1.5 text-xs text-white placeholder-gray-500 focus:outline-none focus:border-amber-500/50 w-44"
            />
          </div>

          {/* Min Score Tabs */}
          <div className="flex items-center bg-[#181C2A] p-1 rounded-xl border border-[#262D40] text-xs">
            <button
              onClick={() => setMinScore(50)}
              className={`px-3 py-1 rounded-lg font-bold transition-all ${
                minScore === 50
                  ? 'bg-amber-500 text-black shadow-md shadow-amber-500/20'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Tümü (%50+)
            </button>
            <button
              onClick={() => setMinScore(65)}
              className={`px-3 py-1 rounded-lg font-bold transition-all ${
                minScore === 65
                  ? 'bg-amber-500 text-black shadow-md shadow-amber-500/20'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Yüksek (%65+)
            </button>
            <button
              onClick={() => setMinScore(80)}
              className={`px-3 py-1 rounded-lg font-bold transition-all ${
                minScore === 80
                  ? 'bg-amber-500 text-black shadow-md shadow-amber-500/20'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Kritik (%80+)
            </button>
          </div>

          <span className="px-3 py-1.5 rounded-xl text-xs font-black bg-amber-500/10 text-amber-300 border border-amber-500/30">
            {filteredLeads.length} Aday
          </span>
        </div>
      </div>

      {/* Grid of Leads */}
      {filteredLeads.length === 0 ? (
        <div className="p-8 rounded-2xl bg-[#131620] border border-[#1F2433] text-center text-xs text-gray-400 space-y-2">
          <Target className="w-8 h-8 text-gray-600 mx-auto" />
          <p className="font-bold text-gray-300">Bu filtreye uygun aday bulunamadı</p>
          <p className="text-[11px] text-gray-500">
            Arama metnini temizleyebilir veya eşik değerini "%50+" olarak seçebilirsiniz.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredLeads.map((lead) => {
            const isCritical = (lead.conversionScore || 0) >= 80;
            const isHigh = (lead.conversionScore || 0) >= 65;
            const hasNotified = Boolean(notifiedUsers[lead.userId]);

            return (
              <div
                key={lead.userId}
                className={`p-5 rounded-2xl bg-[#131620] border transition-all duration-300 shadow-lg flex flex-col justify-between ${
                  isCritical
                    ? 'border-amber-500/50 hover:border-amber-400 shadow-amber-500/10'
                    : isHigh
                    ? 'border-amber-500/30 hover:border-amber-400/60 shadow-amber-500/5'
                    : 'border-[#22283A] hover:border-amber-500/30'
                }`}
              >
                <div>
                  {/* User Header */}
                  <div className="flex items-start justify-between">
                    <div className="flex items-center space-x-3">
                      <div
                        className={`w-11 h-11 rounded-xl flex items-center justify-center font-black text-white text-sm shadow-md ${
                          isCritical
                            ? 'bg-gradient-to-br from-amber-500 to-amber-700'
                            : 'bg-gradient-to-br from-blue-600 to-indigo-700'
                        }`}
                      >
                        {lead.name.charAt(0)}
                      </div>
                      <div>
                        <div className="flex items-center space-x-1.5">
                          <h3 className="text-sm font-bold text-white hover:text-amber-400 transition-colors">
                            {lead.name}
                          </h3>
                        </div>
                        <div className="flex items-center space-x-1.5 mt-0.5 text-[11px] text-gray-400">
                          {lead.role === 'asker' ? (
                            <span className="text-blue-400 flex items-center font-medium">
                              <Shield className="w-3 h-3 mr-0.5" />
                              {lead.rank || 'Er'}
                            </span>
                          ) : (
                            <span className="text-pink-400 flex items-center font-medium">
                              <Heart className="w-3 h-3 mr-0.5" />
                              {lead.roleLabel}
                            </span>
                          )}
                          <span>•</span>
                          <span className="truncate max-w-[110px]">{lead.location}</span>
                        </div>
                      </div>
                    </div>

                    {/* Score Badge */}
                    <div className="text-right shrink-0">
                      <div
                        className={`inline-flex items-center space-x-1 px-2.5 py-1 rounded-lg font-black text-xs border ${
                          isCritical
                            ? 'bg-amber-500/20 text-amber-300 border-amber-500/40'
                            : isHigh
                            ? 'bg-purple-500/20 text-purple-300 border-purple-500/30'
                            : 'bg-blue-500/20 text-blue-300 border-blue-500/30'
                        }`}
                      >
                        <Sparkles className="w-3.5 h-3.5 fill-current" />
                        <span>%{lead.conversionScore}</span>
                      </div>
                      <span className="block text-[9px] text-gray-400 mt-0.5">Dönüşüm Skoru</span>
                    </div>
                  </div>

                  {/* Tracking Code & Module */}
                  <div className="mt-3 flex items-center justify-between text-[11px] px-2.5 py-1.5 rounded-lg bg-[#181C2A] border border-[#22283A]">
                    <div className="flex items-center space-x-1.5 text-gray-400">
                      <span className="text-gray-500">Takip Kodu:</span>
                      {lead.trackingCode ? (
                        <span className="font-mono text-amber-300 font-bold bg-amber-500/10 px-1.5 py-0.5 rounded border border-amber-500/20">
                          {lead.trackingCode}
                        </span>
                      ) : (
                        <span className="text-gray-600 font-mono text-[10px]">Doğrudan Cihaz</span>
                      )}
                    </div>
                    <div className="text-gray-400 truncate max-w-[130px]">
                      <span className="text-gray-500 mr-1">Favori:</span>
                      <span className="text-gray-300 font-medium">{lead.favoriteModule || 'Ana Sayfa'}</span>
                    </div>
                  </div>

                  {/* Behavioral Triggers */}
                  <div className="mt-3 p-3 rounded-xl bg-[#161A26] border border-[#202638] text-xs space-y-1.5">
                    <span className="text-[10px] font-black text-amber-400 uppercase tracking-wider block">
                      Tespit Edilen Davranışlar:
                    </span>
                    {lead.conversionReasons &&
                      lead.conversionReasons.map((reason, i) => (
                        <div key={i} className="flex items-start space-x-2 text-gray-300 text-[11px]">
                          <CheckCircle2 className="w-3.5 h-3.5 text-amber-400 shrink-0 mt-0.5" />
                          <span>{reason}</span>
                        </div>
                      ))}
                  </div>

                  {/* Metrics */}
                  <div className="mt-3 grid grid-cols-2 gap-2 text-xs">
                    <div className="p-2 rounded-lg bg-[#151926] text-center border border-[#1E2333]">
                      <span className="text-gray-400 text-[10px] block">Günlük Süre</span>
                      <p className="font-bold text-white mt-0.5">
                        {Math.floor(lead.dailyTimeSeconds / 60)} dk {lead.dailyTimeSeconds % 60} sn
                      </p>
                    </div>
                    <div className="p-2 rounded-lg bg-[#151926] text-center border border-[#1E2333]">
                      <span className="text-gray-400 text-[10px] block">Sadakat Serisi</span>
                      <p className="font-bold text-amber-400 mt-0.5">
                        {lead.weeklyStreak} Gün Kesintisiz
                      </p>
                    </div>
                  </div>
                </div>

                {/* Action Button */}
                <div className="mt-4 pt-3 border-t border-[#1F2433]">
                  <button
                    disabled={hasNotified}
                    onClick={() => handleNotify(lead.userId, lead.name)}
                    className={`w-full py-2 px-3 rounded-xl font-bold text-xs flex items-center justify-center space-x-2 transition-all ${
                      hasNotified
                        ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 cursor-default'
                        : 'bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-400 hover:to-amber-500 text-black font-extrabold shadow-lg shadow-amber-500/20'
                    }`}
                  >
                    {hasNotified ? (
                      <>
                        <Check className="w-3.5 h-3.5" />
                        <span>Dönüşüm Teklifi İletildi</span>
                      </>
                    ) : (
                      <>
                        <Send className="w-3.5 h-3.5" />
                        <span>Özel PRO İndirim Bildirimi Gönder</span>
                      </>
                    )}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
