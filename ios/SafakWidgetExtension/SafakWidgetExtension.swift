import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), remainingDays: 100, name: "Asker", sulusTarihi: Date().addingTimeInterval(-86400 * 30), terhisTarihi: Date().addingTimeInterval(86400 * 150))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.bayesa.ios.safaksayar2026")
        let name = userDefaults?.string(forKey: "name") ?? "Asker"
        let endStr = userDefaults?.string(forKey: "end_date") ?? ""
        let sulusStr = userDefaults?.string(forKey: "sulus_tarihi") ?? ""
        
        var remainingDays = userDefaults?.integer(forKey: "remainingDays") ?? 0
        
        var sulusDate = Date().addingTimeInterval(-86400 * 30) // fallback 30 days ago
        if let parsedSulus = parseISO8601Date(sulusStr) {
            sulusDate = parsedSulus
        }
        
        var terhisDate = Date().addingTimeInterval(86400 * 150) // fallback 150 days later
        if let parsedEnd = parseISO8601Date(endStr) {
            terhisDate = parsedEnd
            
            let diffs = Calendar.current.dateComponents([.day], from: Date(), to: terhisDate)
            remainingDays = max(0, diffs.day ?? 0)
        }
        
        return SimpleEntry(date: Date(), remainingDays: remainingDays, name: name, sulusTarihi: sulusDate, terhisTarihi: terhisDate)
    }

    private func parseISO8601Date(_ str: String) -> Date? {
        if str.isEmpty { return nil }
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        
        for format in formats {
            df.dateFormat = format
            if let date = df.date(from: str) {
                return date
            }
        }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: str) {
            return date
        }
        
        let isoFormatterSimple = ISO8601DateFormatter()
        return isoFormatterSimple.date(from: str)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let remainingDays: Int
    let name: String
    let sulusTarihi: Date
    let terhisTarihi: Date
}

struct SafakWidgetExtensionEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(WidgetBackgroundModifier(background: backgroundView))
    }

    var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.90, green: 0.05, blue: 0.05), // Vibrant Red
                Color(red: 0.60, green: 0.02, blue: 0.02)  // Dark Turkish Red
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct WidgetBackgroundModifier<Background: View>: ViewModifier {
    let background: Background

    func body(content: Content) -> some View {
        #if compiler(>=5.9)
        if #available(iOS 17.0, *) {
            return AnyView(
                content.containerBackground(for: .widget) {
                    background
                }
            )
        }
        #endif
        return AnyView(content.background(background))
    }
}

struct SmallWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("ŞAFAK SAYAR")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Image(systemName: "star.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.white)
            }
            
            Spacer(minLength: 0)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text("\(entry.remainingDays)")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                
                Text("GÜN")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 6)
            }
            
            Spacer(minLength: 0)
            
            Text(entry.name.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.2))
                .cornerRadius(6)
                .lineLimit(1)
        }
        .padding(14)
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Side - Big Stats
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.white)
                    Text("ŞAFAK SAYAR")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                
                Spacer(minLength: 0)
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text("\(entry.remainingDays)")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                    
                    Text("GÜN")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                }
                
                Spacer(minLength: 0)
                
                Text(statusMessage)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .lineLimit(1)
            }
            .frame(width: 120, alignment: .leading)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            // Right Side - Progress & Details
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.name.uppercased())
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Tamamlanan")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(Int(progressPercent))%")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3.5)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 7)
                            
                            RoundedRectangle(cornerRadius: 3.5)
                                .fill(Color.white)
                                .frame(width: geo.size.width * CGFloat(progress), height: 7)
                        }
                    }
                    .frame(height: 7)
                }
                
                Spacer(minLength: 0)
                
                // Dates Details
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Sülüs:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                        Text(formatDate(entry.sulusTarihi))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                    HStack {
                        Text("Terhis:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                        Text(formatDate(entry.terhisTarihi))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(16)
    }
    
    private var progress: Double {
        let total = entry.terhisTarihi.timeIntervalSince(entry.sulusTarihi)
        guard total > 0 else { return 0.0 }
        let elapsed = Date().timeIntervalSince(entry.sulusTarihi)
        return max(0.0, min(1.0, elapsed / total))
    }
    
    private var progressPercent: Double {
        return progress * 100.0
    }
    
    private var statusMessage: String {
        let days = entry.remainingDays
        if days <= 0 {
            return "Şafak Doğan Güneş!"
        } else if days <= 10 {
            return "Kayıp Şafak!"
        } else if days <= 30 {
            return "Bitiyor, son 1 ay!"
        } else if days <= 100 {
            return "Çift hanelere az kaldı!"
        } else {
            return "Vatan Sağ Olsun!"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: date)
    }
}

@main
struct SafakWidgetExtension: Widget {
    let kind: String = "SafakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SafakWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("Şafak Sayar")
        .description("Kalan askerlik sürenizi gösteren widget.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .disableContentMarginsIfNeeded()
    }
}

extension WidgetConfiguration {
    func disableContentMarginsIfNeeded() -> some WidgetConfiguration {
        #if compiler(>=5.9)
        if #available(iOS 17.0, *) {
            return self.contentMarginsDisabled()
        }
        #endif
        return self
    }
}
