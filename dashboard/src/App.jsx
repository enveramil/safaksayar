import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import MetricCards from './components/MetricCards';
import EngagementChart from './components/EngagementChart';
import ModuleUsageBreakdown from './components/ModuleUsageBreakdown';
import UserScreenTimeTable from './components/UserScreenTimeTable';
import ProPropensityCard from './components/ProPropensityCard';
import ProSubscribersCard from './components/ProSubscribersCard';
import LoyaltyMatrix from './components/LoyaltyMatrix';
import MobileTelemetryGuide from './components/MobileTelemetryGuide';
import { dataService } from './services/dataService';
import { Loader2, AlertCircle, RefreshCw } from 'lucide-react';

export default function App() {
  const [activeTab, setActiveTab] = useState('overview');
  const [dateRange, setDateRange] = useState('today');
  const [data, setData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [errorMessage, setErrorMessage] = useState(null);

  const loadData = async () => {
    setIsRefreshing(true);
    setErrorMessage(null);
    try {
      const res = await dataService.getDashboardData(dateRange);
      setData(res);
    } catch (e) {
      console.error('Data load error:', e);
      setErrorMessage(e.message || 'Firestore verileri alınamadı.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [dateRange]);

  return (
    <div className="min-h-screen bg-[#0B0D13] text-gray-100 flex flex-col selection:bg-blue-600 selection:text-white">
      {/* Top Fixed Header */}
      <Header
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        onRefresh={loadData}
        isRefreshing={isRefreshing}
        dateRange={dateRange}
        setDateRange={setDateRange}
      />

      {/* Main Content Area */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">
        {isLoading ? (
          <div className="h-96 flex flex-col items-center justify-center space-y-3">
            <Loader2 className="w-8 h-8 text-blue-500 animate-spin" />
            <p className="text-sm text-gray-400">Canlı Firestore verileri yükleniyor...</p>
          </div>
        ) : errorMessage ? (
          <div className="p-8 rounded-2xl bg-red-950/20 border border-red-500/30 text-center space-y-3 max-w-md mx-auto">
            <AlertCircle className="w-10 h-10 text-red-400 mx-auto" />
            <h3 className="text-base font-bold text-white">Firestore Bağlantı Hatası</h3>
            <p className="text-xs text-gray-400 leading-relaxed">{errorMessage}</p>
            <button
              onClick={loadData}
              className="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-500 text-white font-semibold text-xs inline-flex items-center space-x-1.5"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Tekrar Dene</span>
            </button>
          </div>
        ) : (
          <>
            {/* Top KPI Cards (Always visible on overview) */}
            {activeTab === 'overview' && (
              <>
                <MetricCards overview={data.overview} onCardClick={setActiveTab} />
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                  <div className="lg:col-span-2">
                    <EngagementChart data={data.hourlyEngagement} />
                  </div>
                  <div>
                    <ModuleUsageBreakdown modules={data.moduleUsage.slice(0, 3)} />
                  </div>
                </div>
                <div className="pt-2">
                  <ProPropensityCard users={data.users} />
                </div>
                <div className="pt-2">
                  <LoyaltyMatrix cohorts={data.retentionCohorts} users={data.users} />
                </div>
                <div className="pt-2">
                  <UserScreenTimeTable users={data.users} />
                </div>
              </>
            )}

            {/* Modules Tab */}
            {activeTab === 'modules' && (
              <div className="space-y-6">
                <ModuleUsageBreakdown modules={data.moduleUsage} />
                <EngagementChart data={data.hourlyEngagement} />
              </div>
            )}

            {/* Users & Screen Time Tab */}
            {activeTab === 'users' && (
              <div className="space-y-6">
                <UserScreenTimeTable users={data.users} />
                <LoyaltyMatrix cohorts={data.retentionCohorts} users={data.users} />
              </div>
            )}

            {/* Leads & PRO Subscribers Tab */}
            {activeTab === 'leads' && (
              <div className="space-y-6">
                <ProPropensityCard users={data.users} />
                <ProSubscribersCard users={data.users} subscribersSummary={data.subscribersSummary} />
              </div>
            )}

            {/* Mobile SDK & Telemetry Guide Tab */}
            {activeTab === 'telemetry' && (
              <div className="space-y-6">
                <MobileTelemetryGuide />
              </div>
            )}
          </>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-[#1F2433] py-4 bg-[#0A0C11] text-center text-xs text-gray-500">
        <p>
          Şafak Sayar • Canlı Firestore Entegrasyonu • safak-sayar-4e1cd
        </p>
      </footer>
    </div>
  );
}
