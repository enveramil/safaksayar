import React, { useState } from 'react';
import {
  Search,
  Filter,
  ArrowUpDown,
  Clock,
  Crown,
  Heart,
  Shield,
  MapPin,
  Flame,
  CheckCircle2,
  ChevronRight,
  X,
} from 'lucide-react';

export default function UserScreenTimeTable({ users }) {
  const [searchTerm, setSearchTerm] = useState('');
  const [roleFilter, setRoleFilter] = useState('all'); // 'all' | 'asker' | 'yakin' | 'pro'
  const [selectedUser, setSelectedUser] = useState(null);

  if (!users || users.length === 0) return null;

  // Filtering
  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      u.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.location.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.city.toLowerCase().includes(searchTerm.toLowerCase());

    if (!matchesSearch) return false;

    if (roleFilter === 'asker') return u.role === 'asker';
    if (roleFilter === 'yakin') return u.role === 'yakin';
    if (roleFilter === 'pro') return u.isPremium === true;
    return true;
  });

  const formatSeconds = (sec) => {
    if (!sec || sec <= 0) return '0 sn (Yeni Giriş)';
    const hours = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    if (hours > 0) return `${hours} sa ${m} dk`;
    if (m === 0) return `${s} sn`;
    return `${m} dk ${s} sn`;
  };

  return (
    <div className="space-y-4">
      {/* Table Header & Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold text-white flex items-center space-x-2">
            <Clock className="w-5 h-5 text-emerald-400" />
            <span>Kullanıcı Bazında Günlük Harcanan Süreler</span>
          </h2>
          <p className="text-xs text-gray-400">
            Hangi kullanıcının bugün uygulama içinde ne kadar aktif zaman geçirdiğini ve sadakat serisini gösterir.
          </p>
        </div>

        {/* Filter & Search Bar */}
        <div className="flex items-center space-x-2">
          {/* Search Input */}
          <div className="relative">
            <Search className="w-4 h-4 text-gray-400 absolute left-3 top-2.5" />
            <input
              type="text"
              placeholder="İsim, şehir, kışla ara..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="bg-[#141824] border border-[#1F2433] rounded-lg pl-9 pr-3 py-1.5 text-xs text-white placeholder-gray-500 focus:outline-none focus:border-blue-500 transition-all w-48 sm:w-60"
            />
          </div>

          {/* Role Filter */}
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="bg-[#141824] border border-[#1F2433] rounded-lg px-2.5 py-1.5 text-xs text-gray-200 outline-none cursor-pointer"
          >
            <option value="all">Tüm Roller</option>
            <option value="asker">Yalnızca Askerler</option>
            <option value="yakin">Yalnızca Yakınlar</option>
            <option value="pro">Yalnızca PRO Üyeler</option>
          </select>
        </div>
      </div>

      {/* Main Table */}
      <div className="bg-[#131620] border border-[#1F2433] rounded-2xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#1F2433] bg-[#0E1118]/70 text-[11px] uppercase tracking-wider text-gray-400">
                <th className="py-3 px-4">Kullanıcı & Rol</th>
                <th className="py-3 px-4">Birlik / Şehir</th>
                <th className="py-3 px-4">Günlük Süre</th>
                <th className="py-3 px-4">Sadakat Serisi</th>
                <th className="py-3 px-4">Favori Modül</th>
                <th className="py-3 px-4">PRO Durumu</th>
                <th className="py-3 px-4 text-right">İşlem</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#1F2433]/60 text-xs">
              {filteredUsers.map((user) => {
                const maxDaySec = 3600; // 1 saat referans
                const pct = Math.min(100, Math.round((user.dailyTimeSeconds / maxDaySec) * 100));

                return (
                  <tr
                    key={user.userId}
                    onClick={() => setSelectedUser(user)}
                    className="hover:bg-[#181D2C] transition-colors cursor-pointer group"
                  >
                    {/* User & Role */}
                    <td className="py-3.5 px-4">
                      <div className="flex items-center space-x-3">
                        <div
                          className={`w-9 h-9 rounded-xl ${
                            user.avatarColor || 'bg-blue-600'
                          } flex items-center justify-center font-bold text-white shadow-md text-xs shrink-0`}
                        >
                          {user.name.charAt(0)}
                        </div>
                        <div>
                          <div className="flex items-center space-x-1.5 font-bold text-white">
                            <span>{user.name}</span>
                            {user.isPremium && (
                              <Crown className="w-3.5 h-3.5 text-amber-400 fill-amber-400" />
                            )}
                          </div>
                          <div className="flex items-center space-x-1.5 mt-0.5 text-[11px]">
                            {user.role === 'asker' ? (
                              <span className="text-blue-400 flex items-center">
                                <Shield className="w-3 h-3 mr-0.5" />
                                {user.rank || 'Asker'}
                              </span>
                            ) : (
                              <span className="text-pink-400 flex items-center">
                                <Heart className="w-3 h-3 mr-0.5" />
                                {user.roleLabel}
                              </span>
                            )}
                            {user.trackingCode && (
                              <span className="text-gray-400 font-mono text-[10px] bg-white/5 px-1.5 py-0.5 rounded border border-white/10">
                                {user.trackingCode}
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* Location */}
                    <td className="py-3.5 px-4 text-gray-300">
                      <div className="flex items-center space-x-1">
                        <MapPin className="w-3.5 h-3.5 text-gray-500 shrink-0" />
                        <span className="truncate max-w-[180px]">{user.location}</span>
                      </div>
                      <span className="text-[10px] text-gray-500 block ml-4.5">{user.city}</span>
                    </td>

                    {/* Daily Screen Time */}
                    <td className="py-3.5 px-4">
                      <div className="font-bold text-white">
                        {formatSeconds(user.dailyTimeSeconds)}
                      </div>
                      <div className="w-28 bg-[#1F2433] h-1.5 rounded-full overflow-hidden mt-1.5">
                        <div
                          className="h-full bg-gradient-to-r from-blue-500 to-emerald-400 rounded-full"
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                    </td>

                    {/* Loyalty Streak */}
                    <td className="py-3.5 px-4">
                      <div className="flex items-center space-x-1 text-amber-400 font-bold">
                        <Flame className="w-4 h-4 fill-amber-400" />
                        <span>{user.weeklyStreak} Gün</span>
                      </div>
                      <span className="text-[10px] text-gray-400">{user.loyaltyTier}</span>
                    </td>

                    {/* Favorite Module */}
                    <td className="py-3.5 px-4">
                      <span className="px-2.5 py-1 rounded-md bg-[#1B202E] text-gray-300 font-medium border border-[#272E42]">
                        {user.favoriteModule}
                      </span>
                    </td>

                    {/* PRO Status */}
                    <td className="py-3.5 px-4">
                      {user.isPremium ? (
                        <span
                          className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-bold ${
                            user.subscriptionCategory === 'annual'
                              ? 'bg-purple-500/10 text-purple-300 border border-purple-500/30'
                              : user.subscriptionCategory === 'monthly'
                              ? 'bg-blue-500/10 text-blue-300 border border-blue-500/30'
                              : user.subscriptionCategory === 'relative_free'
                              ? 'bg-emerald-500/10 text-emerald-300 border border-emerald-500/30'
                              : 'bg-amber-500/10 text-amber-300 border border-amber-500/30'
                          }`}
                        >
                          <Crown className="w-3 h-3 mr-1" />
                          {user.subscriptionLabel || 'PRO Üye'}
                        </span>
                      ) : (
                        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium bg-gray-800 text-gray-400">
                          Ücretsiz Hesap
                        </span>
                      )}
                    </td>

                    {/* Action */}
                    <td className="py-3.5 px-4 text-right">
                      <button className="p-1.5 rounded-lg hover:bg-[#252B3C] text-gray-400 hover:text-white transition-all">
                        <ChevronRight className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* User Drilldown Modal */}
      {selectedUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-[#131620] border border-[#2A3146] rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-4">
            <div className="flex items-start justify-between">
              <div className="flex items-center space-x-3">
                <div
                  className={`w-12 h-12 rounded-xl ${
                    selectedUser.avatarColor || 'bg-blue-600'
                  } flex items-center justify-center font-bold text-white text-lg shadow-lg`}
                >
                  {selectedUser.name.charAt(0)}
                </div>
                <div>
                  <h3 className="text-base font-bold text-white flex items-center space-x-1.5">
                    <span>{selectedUser.name}</span>
                    {selectedUser.isPremium && (
                      <Crown className="w-4 h-4 text-amber-400 fill-amber-400" />
                    )}
                  </h3>
                  <p className="text-xs text-gray-400">
                    {selectedUser.roleLabel} • {selectedUser.rank} • {selectedUser.location}
                    {selectedUser.trackingCode && ` • Kod: ${selectedUser.trackingCode}`}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setSelectedUser(null)}
                className="p-1.5 rounded-lg bg-[#181D2C] hover:bg-[#252C40] text-gray-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* User Statistics Grid */}
            <div className="grid grid-cols-2 gap-3 pt-2 text-xs">
              <div className="p-3 rounded-xl bg-[#181C2A] border border-[#22283A]">
                <span className="text-gray-400">Bugünkü Ekran Süresi</span>
                <p className="text-base font-black text-white mt-0.5">
                  {formatSeconds(selectedUser.dailyTimeSeconds)}
                </p>
              </div>
              <div className="p-3 rounded-xl bg-[#181C2A] border border-[#22283A]">
                <span className="text-gray-400">Kesintisiz Seri (Streak)</span>
                <p className="text-base font-black text-amber-400 mt-0.5">
                  {selectedUser.weeklyStreak} Gün Boyunca
                </p>
              </div>
              <div className="p-3 rounded-xl bg-[#181C2A] border border-[#22283A]">
                <span className="text-gray-400">Toplam Günlük Tıklama</span>
                <p className="text-base font-black text-emerald-400 mt-0.5">
                  {selectedUser.interactionCount} Etkileşim
                </p>
              </div>
              <div className="p-3 rounded-xl bg-[#181C2A] border border-[#22283A]">
                <span className="text-gray-400">PRO Dönüşüm Skoru</span>
                <p className="text-base font-black text-purple-400 mt-0.5">
                  %{selectedUser.conversionScore}
                </p>
              </div>
            </div>

            {/* Conversion Indicators */}
            {selectedUser.conversionReasons && (
              <div className="p-3 rounded-xl bg-purple-950/20 border border-purple-500/20 text-xs">
                <span className="font-bold text-purple-300 block mb-1">
                  💡 Neden PRO Olma İhtimali Yüksek?
                </span>
                <ul className="space-y-1 text-gray-300">
                  {selectedUser.conversionReasons.map((r, i) => (
                    <li key={i} className="flex items-center space-x-1.5">
                      <CheckCircle2 className="w-3.5 h-3.5 text-purple-400 shrink-0" />
                      <span>{r}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <div className="pt-2 flex justify-end">
              <button
                onClick={() => setSelectedUser(null)}
                className="px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-500 text-white text-xs font-semibold"
              >
                Kapat
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

