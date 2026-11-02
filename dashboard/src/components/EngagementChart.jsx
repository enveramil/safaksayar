import React, { useState } from 'react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { Zap } from 'lucide-react';

export default function EngagementChart({ data }) {
  const [chartType, setChartType] = useState('interactions'); // 'interactions' | 'activeUsers' | 'screenMinutes'

  // Calculate real peak and totals from actual data
  const peakSlot = data && data.length > 0
    ? [...data].sort((a, b) => b.interactions - a.interactions)[0]
    : null;
  const totalInteractions = data ? data.reduce((acc, d) => acc + d.interactions, 0) : 0;
  const totalScreenMinutes = data ? data.reduce((acc, d) => acc + d.screenMinutes, 0) : 0;

  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-[#141824] border border-[#2A3146] p-3 rounded-lg shadow-xl text-xs space-y-1">
          <p className="font-bold text-gray-200">Saat: {label}</p>
          <div className="flex items-center space-x-2 text-blue-400">
            <span className="w-2 h-2 rounded-full bg-blue-500"></span>
            <span>Etkileşim: <b>{payload[0].value.toLocaleString('tr-TR')}</b></span>
          </div>
          {payload[1] && (
            <div className="flex items-center space-x-2 text-emerald-400">
              <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
              <span>Aktif Kullanıcı: <b>{payload[1].value}</b></span>
            </div>
          )}
        </div>
      );
    }
    return null;
  };

  return (
    <div className="p-5 rounded-2xl bg-[#131620] border border-[#1F2433] space-y-4">
      {/* Top Header Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <div className="flex items-center space-x-2">
            <Zap className="w-5 h-5 text-blue-400" />
            <h2 className="text-base font-bold text-white">
              24 Saatlik Etkileşim & Yoğunluk Grafiği
            </h2>
          </div>
          <p className="text-xs text-gray-400 mt-0.5">
            Firestore'daki log kayıtlarından türetilen saatlik gerçek işlem ve oturum dağılımı.
          </p>
        </div>

        {/* View Toggle */}
        <div className="flex items-center bg-[#181C2A] p-1 rounded-lg border border-[#22283A] text-xs">
          <button
            onClick={() => setChartType('interactions')}
            className={`px-3 py-1 rounded-md font-medium transition-all ${
              chartType === 'interactions'
                ? 'bg-blue-600 text-white shadow-sm'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            Toplam Etkileşim
          </button>
          <button
            onClick={() => setChartType('activeUsers')}
            className={`px-3 py-1 rounded-md font-medium transition-all ${
              chartType === 'activeUsers'
                ? 'bg-emerald-600 text-white shadow-sm'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            Aktif Kullanıcı
          </button>
          <button
            onClick={() => setChartType('screenMinutes')}
            className={`px-3 py-1 rounded-md font-medium transition-all ${
              chartType === 'screenMinutes'
                ? 'bg-purple-600 text-white shadow-sm'
                : 'text-gray-400 hover:text-white'
            }`}
          >
            Harcanan Dakika
          </button>
        </div>
      </div>

      {/* Main Chart */}
      <div className="h-72 w-full pt-2">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
            <defs>
              <linearGradient id="blueGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#2563EB" stopOpacity={0.4} />
                <stop offset="95%" stopColor="#2563EB" stopOpacity={0.0} />
              </linearGradient>
              <linearGradient id="emeraldGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#10B981" stopOpacity={0.4} />
                <stop offset="95%" stopColor="#10B981" stopOpacity={0.0} />
              </linearGradient>
              <linearGradient id="purpleGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#8B5CF6" stopOpacity={0.4} />
                <stop offset="95%" stopColor="#8B5CF6" stopOpacity={0.0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#1F2537" vertical={false} />
            <XAxis dataKey="hour" stroke="#64748B" fontSize={11} tickLine={false} />
            <YAxis stroke="#64748B" fontSize={11} tickLine={false} />
            <Tooltip content={<CustomTooltip />} />
            
            {chartType === 'interactions' && (
              <Area
                type="monotone"
                dataKey="interactions"
                stroke="#3B82F6"
                strokeWidth={2.5}
                fillOpacity={1}
                fill="url(#blueGradient)"
              />
            )}
            {chartType === 'activeUsers' && (
              <Area
                type="monotone"
                dataKey="activeUsers"
                stroke="#10B981"
                strokeWidth={2.5}
                fillOpacity={1}
                fill="url(#emeraldGradient)"
              />
            )}
            {chartType === 'screenMinutes' && (
              <Area
                type="monotone"
                dataKey="screenMinutes"
                stroke="#8B5CF6"
                strokeWidth={2.5}
                fillOpacity={1}
                fill="url(#purpleGradient)"
              />
            )}
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Real Chart Footer Highlights */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2 border-t border-[#1F2433]">
        <div className="flex items-center space-x-3 p-2.5 rounded-xl bg-[#161A26]">
          <div className="w-8 h-8 rounded-lg bg-blue-500/10 flex items-center justify-center text-blue-400">
            🌙
          </div>
          <div>
            <div className="text-xs text-gray-400">En Yoğun Saat Dilimi</div>
            <div className="text-sm font-bold text-white">
              {peakSlot && peakSlot.interactions > 0 ? `${peakSlot.hour} (${peakSlot.interactions} İşlem)` : 'Veri toplanıyor'}
            </div>
          </div>
        </div>
        <div className="flex items-center space-x-3 p-2.5 rounded-xl bg-[#161A26]">
          <div className="w-8 h-8 rounded-lg bg-emerald-500/10 flex items-center justify-center text-emerald-400">
            ⚡
          </div>
          <div>
            <div className="text-xs text-gray-400">Toplam 24s İşlem</div>
            <div className="text-sm font-bold text-white">{totalInteractions.toLocaleString('tr-TR')} Etkileşim</div>
          </div>
        </div>
        <div className="flex items-center space-x-3 p-2.5 rounded-xl bg-[#161A26]">
          <div className="w-8 h-8 rounded-lg bg-purple-500/10 flex items-center justify-center text-purple-400">
            ⏱️
          </div>
          <div>
            <div className="text-xs text-gray-400">Toplam Ekran Süresi</div>
            <div className="text-sm font-bold text-white">{totalScreenMinutes.toLocaleString('tr-TR')} Dakika</div>
          </div>
        </div>
      </div>
    </div>
  );
}
