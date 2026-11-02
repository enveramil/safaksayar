import React from 'react';
import {
  Clock,
  Swords,
  MessageSquare,
  Mail,
  Palette,
  BookOpen,
  PieChart as PieIcon,
  Flame,
  ArrowRight,
} from 'lucide-react';

const iconMap = {
  Clock: Clock,
  Swords: Swords,
  MessageSquare: MessageSquare,
  Mail: Mail,
  Palette: Palette,
  BookOpen: BookOpen,
};

export default function ModuleUsageBreakdown({ modules }) {
  if (!modules || modules.length === 0) return null;

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
        <div>
          <h2 className="text-lg font-bold text-white flex items-center space-x-2">
            <PieIcon className="w-5 h-5 text-purple-400" />
            <span>Modül & Ekran Bazında Zaman ve Frekans Analizi</span>
          </h2>
          <p className="text-xs text-gray-400">
            Kullanıcıların uygulama içinde en çok hangi modüllerde vakit geçirdiğini ve ortalama oturum sürelerini gösterir.
          </p>
        </div>
      </div>

      {/* Grid of Modules */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {modules.map((m) => {
          const Icon = iconMap[m.icon] || Clock;

          return (
            <div
              key={m.moduleId}
              className="p-5 rounded-2xl bg-[#131620] border border-[#1F2433] hover:border-gray-600 transition-all duration-300 flex flex-col justify-between"
            >
              <div>
                {/* Module Title & Category */}
                <div className="flex items-start justify-between">
                  <div className="flex items-center space-x-3">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center shadow-lg"
                      style={{ backgroundColor: `${m.color}20`, color: m.color }}
                    >
                      <Icon className="w-5 h-5" />
                    </div>
                    <div>
                      <h3 className="text-sm font-bold text-white tracking-tight">
                        {m.name}
                      </h3>
                      <span className="text-[10px] uppercase tracking-wider font-semibold px-2 py-0.5 rounded bg-[#1B202E] text-gray-400 border border-[#262D40]">
                        {m.category}
                      </span>
                    </div>
                  </div>
                  <span className="text-xs font-bold px-2 py-1 rounded-full bg-blue-500/10 text-blue-400">
                    %{m.interactionShare} Pay
                  </span>
                </div>

                {/* Progress Bar of Share */}
                <div className="mt-4">
                  <div className="w-full bg-[#181C28] h-2 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-500"
                      style={{
                        width: `${m.interactionShare}%`,
                        backgroundColor: m.color,
                      }}
                    />
                  </div>
                </div>

                {/* Metric Stats */}
                <div className="mt-4 grid grid-cols-2 gap-2 pt-3 border-t border-[#1F2433]/60 text-xs">
                  <div>
                    <span className="text-gray-400 text-[11px]">Toplam Harcanan Süre</span>
                    <p className="text-sm font-black text-white mt-0.5">
                      {m.formattedDuration}
                    </p>
                  </div>
                  <div>
                    <span className="text-gray-400 text-[11px]">Ort. Oturum Süresi</span>
                    <p className="text-sm font-black text-emerald-400 mt-0.5">
                      {m.avgDurationPerUser}
                    </p>
                  </div>
                </div>
              </div>

              {/* Bottom Footer Info */}
              <div className="mt-4 pt-3 border-t border-[#1F2433]/60 flex items-center justify-between text-xs text-gray-400">
                <span>Günlük Giriş Sayısı:</span>
                <span className="font-bold text-gray-200">
                  {m.dailySessions.toLocaleString('tr-TR')} oturum
                </span>
              </div>
            </div>
          );
        })}
      </div>

      {/* Strategic Insights Card */}
      <div className="p-5 rounded-2xl bg-gradient-to-r from-blue-950/40 via-purple-950/30 to-indigo-950/40 border border-blue-500/30">
        <div className="flex items-start space-x-3">
          <div className="p-2.5 rounded-xl bg-blue-500/20 text-blue-400 shrink-0">
            <Flame className="w-6 h-6" />
          </div>
          <div>
            <h4 className="text-sm font-bold text-white">
              Büyüme & Etkileşim Tavsiyeleri
            </h4>
            <p className="text-xs text-gray-300 mt-1 leading-relaxed">
              • <b>Kim Milyoner Olmak İster & Düello:</b> Oturum başına 14 dk ile en yüksek tutundurma sağlayan modüldür. Düello haklarının yenilenmesi için "Arkadaşını Davet Et" veya "PRO ile Sınırsız Oyna" kurgusu PRO satışlarını doğrudan artırır.
              <br />
              • <b>Zaman Kapsülü & Takvim:</b> Asker Yakını kullanıcıların %85'i haftada en az 3 kez bu modülü ziyaret ediyor. Sevgili/aile bildirimleri uygulamaya anlık dönüşleri tetikliyor.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

