import React, { useState, useEffect } from 'react';
import {
  Activity,
  Calendar,
  RefreshCw,
  Database,
  Radio,
  Sliders,
  Users,
  LayoutGrid,
  Zap,
  BookOpen,
  Lock,
  Unlock,
  ShieldAlert,
} from 'lucide-react';
import { db } from '../firebase/config';
import { doc, onSnapshot, setDoc } from 'firebase/firestore';

export default function Header({
  activeTab,
  setActiveTab,
  onRefresh,
  isRefreshing,
  dateRange,
  setDateRange,
}) {
  const [isNecessaryPro, setIsNecessaryPro] = useState(false);
  const [isUpdatingConfig, setIsUpdatingConfig] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(doc(db, 'parameter', 'config'), (snap) => {
      if (snap.exists()) {
        const val = snap.data()?.isNecessaryProScreen ?? false;
        setIsNecessaryPro(val);
      }
    });
    return () => unsub();
  }, []);

  const handleToggleProScreen = async () => {
    setIsUpdatingConfig(true);
    try {
      await setDoc(
        doc(db, 'parameter', 'config'),
        { isNecessaryProScreen: !isNecessaryPro },
        { merge: true }
      );
    } catch (e) {
      console.error('Config update error:', e);
      alert('Firestore güncelleme hatası: ' + e.message);
    } finally {
      setIsUpdatingConfig(false);
    }
  };
  const tabs = [
    { id: 'overview', label: 'Genel Bakış', icon: LayoutGrid },
    { id: 'modules', label: 'Modül & Süre Dağılımı', icon: Activity },
    { id: 'users', label: 'Kullanıcı Ekran Süreleri', icon: Users },
    { id: 'leads', label: 'PRO Adayları & Aboneler', icon: Zap },
    { id: 'telemetry', label: 'Mobil SDK Telemetri', icon: BookOpen },
  ];

  return (
    <header className="border-b border-[#1F2433] bg-[#0E1118]/90 backdrop-blur-md sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Top Bar */}
        <div className="flex items-center justify-between h-16">
          {/* Logo & Title */}
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-blue-600 via-indigo-600 to-purple-600 flex items-center justify-center shadow-lg shadow-blue-500/20">
              <span className="text-xl">🇹🇷</span>
            </div>
            <div>
              <div className="flex items-center space-x-2">
                <h1 className="text-lg font-bold text-white tracking-tight">
                  Şafak Sayar
                </h1>
                <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 flex items-center space-x-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                  <span>Canlı Firestore</span>
                </span>
              </div>
              <p className="text-xs text-gray-400">
                Gerçek Zamanlı Kullanıcı & Etkileşim Kontrol Merkezi
              </p>
            </div>
          </div>

          {/* Right Action Controls */}
          <div className="flex items-center space-x-3">
            {/* Real-time isNecessaryProScreen Switch */}
            <button
              onClick={handleToggleProScreen}
              disabled={isUpdatingConfig}
              className={`flex items-center space-x-2 px-3 py-1.5 rounded-lg text-xs font-semibold border transition-all ${
                isNecessaryPro
                  ? 'bg-amber-500/15 text-amber-300 border-amber-500/40 hover:bg-amber-500/25 shadow-sm shadow-amber-500/10'
                  : 'bg-emerald-500/10 text-emerald-300 border-emerald-500/30 hover:bg-emerald-500/20'
              }`}
              title="Tıkla: Mobil Uygulamada Zorunlu PRO Ekranını Aç / Kapat"
            >
              {isNecessaryPro ? (
                <Lock className="w-3.5 h-3.5 text-amber-400" />
              ) : (
                <Unlock className="w-3.5 h-3.5 text-emerald-400" />
              )}
              <span className="hidden md:inline">Zorunlu PRO:</span>
              <span className="font-mono">
                {isNecessaryPro ? 'AÇIK (Ücret Zorunlu)' : 'KAPALI (Çarpı İle Serbest)'}
              </span>
            </button>

            {/* Live Database Status Indicator */}
            <div className="hidden lg:flex items-center space-x-2 bg-[#141824] border border-emerald-500/30 px-3 py-1.5 rounded-lg text-xs font-mono text-emerald-300">
              <Database className="w-3.5 h-3.5 text-emerald-400" />
              <span>safak-sayar-4e1cd</span>
            </div>

            {/* Date Range Selector */}
            <div className="flex items-center bg-[#141824] border border-[#1F2433] rounded-lg px-2.5 py-1.5 text-xs text-gray-300">
              <Calendar className="w-3.5 h-3.5 mr-2 text-gray-400" />
              <select
                value={dateRange}
                onChange={(e) => setDateRange(e.target.value)}
                className="bg-transparent text-gray-200 outline-none cursor-pointer"
              >
                <option value="today" className="bg-[#141824]">Bugün (Canlı)</option>
                <option value="7d" className="bg-[#141824]">Son 7 Gün</option>
                <option value="30d" className="bg-[#141824]">Son 30 Gün</option>
              </select>
            </div>

            {/* Refresh Button */}
            <button
              onClick={onRefresh}
              disabled={isRefreshing}
              className="p-2 rounded-lg bg-[#141824] hover:bg-[#1A2030] text-gray-300 hover:text-white border border-[#1F2433] transition-all"
              title="Gerçek Verileri Yenile"
            >
              <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin text-blue-400' : ''}`} />
            </button>
          </div>
        </div>

        {/* Tab Navigation */}
        <nav className="flex space-x-1 border-t border-[#1F2433]/60 overflow-x-auto scrollbar-none py-2">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center space-x-2 px-3.5 py-2 rounded-lg text-xs sm:text-sm font-medium whitespace-nowrap transition-all ${
                  isActive
                    ? 'bg-[#1E2333] text-white border border-blue-500/40 shadow-sm shadow-blue-500/10'
                    : 'text-gray-400 hover:text-gray-200 hover:bg-[#151926]'
                }`}
              >
                <Icon className={`w-4 h-4 ${isActive ? 'text-blue-400' : 'text-gray-400'}`} />
                <span>{tab.label}</span>
              </button>
            );
          })}
        </nav>
      </div>
    </header>
  );
}
