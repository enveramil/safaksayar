import React from 'react';
import {
  Users,
  Clock,
  MousePointerClick,
  Heart,
  Crown,
  TrendingUp,
  ArrowUpRight,
} from 'lucide-react';

export default function MetricCards({ overview, onCardClick }) {
  if (!overview) return null;

  const cards = [
    {
      title: 'Günlük Aktif Kullanıcı (DAU)',
      value: overview.dau.toLocaleString('tr-TR'),
      change: `+${overview.dauChange}%`,
      subtitle: 'Son 24 saat içinde giriş yapan tekil asker & yakın',
      icon: Users,
      color: 'text-blue-400',
      bgColor: 'bg-blue-500/10',
      borderColor: 'border-blue-500/20',
      glow: 'glow-border',
      tab: 'users',
    },
    {
      title: 'Ort. Günlük Ekran Süresi',
      value: `${Math.floor(overview.avgScreenTimeSeconds / 60)} dk ${overview.avgScreenTimeSeconds % 60} sn`,
      change: `+${overview.avgScreenTimeChange}%`,
      subtitle: 'Kullanıcı başına uygulama içi harcanan aktif süre',
      icon: Clock,
      color: 'text-emerald-400',
      bgColor: 'bg-emerald-500/10',
      borderColor: 'border-emerald-500/20',
      glow: 'glow-emerald',
      tab: 'users',
    },
    {
      title: 'Günlük Etkileşim & Oturum',
      value: overview.totalInteractions.toLocaleString('tr-TR'),
      change: `+${overview.interactionsChange}%`,
      subtitle: 'Toplam sayfa geçişi, tıklama, düello ve işlem',
      icon: MousePointerClick,
      color: 'text-purple-400',
      bgColor: 'bg-purple-500/10',
      borderColor: 'border-purple-500/20',
      glow: 'glow-purple',
      tab: 'modules',
    },
    {
      title: 'Sadık Kullanıcı Sayısı',
      value: overview.loyalUsersCount.toLocaleString('tr-TR'),
      change: `%${overview.loyaltyRate}`,
      subtitle: 'Haftada 5+ gün kesintisiz şafak atan kullanıcılar',
      icon: Heart,
      color: 'text-pink-400',
      bgColor: 'bg-pink-500/10',
      borderColor: 'border-pink-500/20',
      glow: '',
      tab: 'users',
    },
    {
      title: 'Yüksek PRO Potansiyeli',
      value: `${overview.highPropensityLeads} Aday`,
      change: 'Öncelikli',
      subtitle: 'Abonelik alma ihtimali >%80 olan aktif kullanıcılar',
      icon: Crown,
      color: 'text-amber-400',
      bgColor: 'bg-amber-500/10',
      borderColor: 'border-amber-500/20',
      glow: '',
      tab: 'leads',
    },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
      {cards.map((card, idx) => {
        const Icon = card.icon;
        return (
          <div
            key={idx}
            onClick={() => onCardClick && card.tab && onCardClick(card.tab)}
            className={`p-4 rounded-xl bg-[#131620] border ${card.borderColor} ${card.glow} transition-all duration-300 hover:scale-[1.02] flex flex-col justify-between ${
              onCardClick && card.tab ? 'cursor-pointer hover:border-amber-500/40' : ''
            }`}
          >
            <div>
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-gray-400">
                  {card.title}
                </span>
                <div className={`p-2 rounded-lg ${card.bgColor}`}>
                  <Icon className={`w-4 h-4 ${card.color}`} />
                </div>
              </div>
              <div className="mt-3 flex items-baseline space-x-2">
                <span className="text-2xl font-black text-white tracking-tight">
                  {card.value}
                </span>
                <span className="inline-flex items-center text-xs font-semibold text-emerald-400">
                  <ArrowUpRight className="w-3 h-3 mr-0.5" />
                  {card.change}
                </span>
              </div>
            </div>
            <p className="mt-2 text-[11px] text-gray-400 leading-tight">
              {card.subtitle}
            </p>
          </div>
        );
      })}
    </div>
  );
}

