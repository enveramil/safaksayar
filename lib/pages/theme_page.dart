import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:safaksayar/state_bottom_bar.dart';

class ThemeItem {
  final String id;
  final String assetPath;
  final String title;
  final String subtitle;
  final String category;
  final bool isPro;

  const ThemeItem({
    required this.id,
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.category,
    this.isPro = true,
  });
}

class ThemeCatalog {
  static const List<String> categories = [
    'Tümü',
    'Bayrak & Vatan',
    'Özel Kuvvet',
    'Operasyon',
    'Nöbet & Hasret',
    'Klasik',
  ];

  static const List<ThemeItem> items = [
    ThemeItem(
      id: 'img0',
      assetPath: 'assets/images/img0.webp',
      title: 'Klasik Aydınlık',
      subtitle: 'Varsayılan sade görünüm',
      category: 'Klasik',
      isPro: false,
    ),
    ThemeItem(
      id: 'img12',
      assetPath: 'assets/images/img12.webp',
      title: 'Dolmabahçe Sancağı',
      subtitle: 'Tarihi kapıda şanlı al bayrak',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img19',
      assetPath: 'assets/images/img19.webp',
      title: 'Jandarma Özel Harekat',
      subtitle: 'Çelik bakış, sarsılmaz irade',
      category: 'Özel Kuvvet',
    ),
    ThemeItem(
      id: 'img22',
      assetPath: 'assets/images/img22.webp',
      title: 'Anıtkabir Huzuru',
      subtitle: ' Ata\'nın huzurunda mavi gökyüzü',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img3',
      assetPath: 'assets/images/img3.webp',
      title: 'Bordo Bereliler',
      subtitle: 'Omuz omuza yeminli birlik',
      category: 'Özel Kuvvet',
    ),
    ThemeItem(
      id: 'img13',
      assetPath: 'assets/images/img13.webp',
      title: 'Göklerde Ay Yıldız',
      subtitle: 'Bulutlara hükmeden al sancak',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img17',
      assetPath: 'assets/images/img17.webp',
      title: 'Bozkır Nöbeti',
      subtitle: 'Ufka karşı tek başına dimdik',
      category: 'Nöbet & Hasret',
    ),
    ThemeItem(
      id: 'img20',
      assetPath: 'assets/images/img20.webp',
      title: 'Saygı Nöbeti',
      subtitle: 'Dört kuvvet tek yürek yürüyüşü',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img28',
      assetPath: 'assets/images/img28.webp',
      title: 'Gece Görüş Komando',
      subtitle: 'Karanlıkta sessiz ve hazır',
      category: 'Özel Kuvvet',
    ),
    ThemeItem(
      id: 'img9',
      assetPath: 'assets/images/img9.webp',
      title: 'İstiklal Al Sancak',
      subtitle: 'Şehrin kalbinde dalgalanan gurur',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img1',
      assetPath: 'assets/images/img1.webp',
      title: 'Sıcak Temas',
      subtitle: 'Hedefe kilitlenen namlu ve barut',
      category: 'Operasyon',
    ),
    ThemeItem(
      id: 'img14',
      assetPath: 'assets/images/img14.webp',
      title: 'Kız Kulesi Nöbeti',
      subtitle: 'Boğazın ortasında vatan hatırası',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img7',
      assetPath: 'assets/images/img7.webp',
      title: 'Sıla Hasreti',
      subtitle: 'Kavuşma gününü bekleyen sabır',
      category: 'Nöbet & Hasret',
    ),
    ThemeItem(
      id: 'img2',
      assetPath: 'assets/images/img2.webp',
      title: 'Siyah Duman',
      subtitle: 'Zirvede koordinat işareti',
      category: 'Operasyon',
    ),
    ThemeItem(
      id: 'img10',
      assetPath: 'assets/images/img10.webp',
      title: 'Güller ve Ay Yıldız',
      subtitle: 'Vatan toprağının zarafeti',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img4',
      assetPath: 'assets/images/img4.webp',
      title: 'Hava İndirme',
      subtitle: 'Helikopter ve tam saha intikal',
      category: 'Operasyon',
    ),
    ThemeItem(
      id: 'img24',
      assetPath: 'assets/images/img24.webp',
      title: 'Kış Nöbeti Ateşi',
      subtitle: 'Karlı ormanda siper kardeşliği',
      category: 'Nöbet & Hasret',
    ),
    ThemeItem(
      id: 'img15',
      assetPath: 'assets/images/img15.webp',
      title: 'Tarihi Kemer & Sancak',
      subtitle: 'Gün ışığında parlayan ay yıldız',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img18',
      assetPath: 'assets/images/img18.webp',
      title: 'İkili Taktik Tim',
      subtitle: 'Sırt sırta tam koruma düzeni',
      category: 'Operasyon',
    ),
    ThemeItem(
      id: 'img6',
      assetPath: 'assets/images/img6.webp',
      title: 'Tam Teçhizat',
      subtitle: 'Göreve her an hazır duruş',
      category: 'Özel Kuvvet',
    ),
    ThemeItem(
      id: 'img11',
      assetPath: 'assets/images/img11.webp',
      title: 'Boğaz Hatırası',
      subtitle: 'Martılar ve İstanbul özlemi',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img5',
      assetPath: 'assets/images/img5.webp',
      title: 'Taş Siper',
      subtitle: 'Mevzide sarsılmaz dikkat',
      category: 'Operasyon',
    ),
    ThemeItem(
      id: 'img21',
      assetPath: 'assets/images/img21.webp',
      title: 'Günbatımı Bando',
      subtitle: 'Şafak batarken çalınan marş',
      category: 'Nöbet & Hasret',
    ),
    ThemeItem(
      id: 'img8',
      assetPath: 'assets/images/img8.webp',
      title: 'Zırhlı Gözetleme',
      subtitle: 'Periskop arkasında keskin gözler',
      category: 'Operasyon',
    ),
    ThemeItem(
      id: 'img16',
      assetPath: 'assets/images/img16.webp',
      title: 'Hilal Yansıması',
      subtitle: 'Camda beliren ay yıldız silüeti',
      category: 'Bayrak & Vatan',
    ),
    ThemeItem(
      id: 'img23',
      assetPath: 'assets/images/img23.webp',
      title: 'Mola ve Özlem',
      subtitle: 'Görev arasında memleket düşü',
      category: 'Nöbet & Hasret',
    ),
    ThemeItem(
      id: 'img25',
      assetPath: 'assets/images/img25.webp',
      title: 'Taktik Poligon',
      subtitle: 'Disiplin ve nişancılık eğitimi',
      category: 'Özel Kuvvet',
    ),
    ThemeItem(
      id: 'img26',
      assetPath: 'assets/images/img26.webp',
      title: 'Arazi Gözetleme',
      subtitle: 'Doğayla bütünleşen kamuflaj',
      category: 'Operasyon',
    ),
    ThemeItem(
      id: 'img27',
      assetPath: 'assets/images/img27.webp',
      title: 'Çift Namlulu Görev',
      subtitle: 'Kayalık arazide taktik ekipman',
      category: 'Operasyon',
    ),
    ThemeItem(
      id: 'img29',
      assetPath: 'assets/images/img29.webp',
      title: 'Tarihi Sokak & Bayrak',
      subtitle: 'Memleket sokaklarından bir kare',
      category: 'Bayrak & Vatan',
    ),
  ];
}

class UserPreviewSnapshot {
  final String fullName;
  final String rutbe;
  final String kuvvetLogo;
  final String askerlikYeri;
  final String memleket;
  final String userRole;
  final String? relationship;
  final int remainingDays;

  const UserPreviewSnapshot({
    required this.fullName,
    required this.rutbe,
    required this.kuvvetLogo,
    required this.askerlikYeri,
    required this.memleket,
    required this.userRole,
    this.relationship,
    required this.remainingDays,
  });

  static Future<UserPreviewSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name') ?? '';
    final surname = prefs.getString('surname') ?? '';
    final rutbe = prefs.getString('rutbe') ?? 'ER';
    final kuvvet = (prefs.getString('kuvvet_komutanligi') ?? '').trim().toLowerCase();
    final askerlikYeri = prefs.getString('askerlik_yeri') ?? 'Belirtilmedi';
    final memleket = prefs.getString('memleket') ?? 'Belirtilmedi';
    final userRole = prefs.getString('user_role') ?? 'asker';
    final relationship = prefs.getString('relationship');
    final endDateStr = prefs.getString('end_date') ?? '';

    String logo = 'assets/images/app_logo.png';
    if (kuvvet == 'kara') {
      logo = 'assets/images/Kara.webp';
    } else if (kuvvet == 'deniz') {
      logo = 'assets/images/Deniz.webp';
    } else if (kuvvet == 'hava') {
      logo = 'assets/images/Hava.webp';
    } else if (kuvvet == 'jandarma') {
      logo = 'assets/images/Jandarma.webp';
    }

    int remDays = 84;
    if (endDateStr.isNotEmpty) {
      try {
        final endDate = DateTime.parse(endDateStr);
        final diff = endDate.difference(DateTime.now()).inDays;
        remDays = diff < 0 ? 0 : diff;
      } catch (_) {}
    }

    final full = (name.isNotEmpty || surname.isNotEmpty)
        ? '${name.toUpperCase()} ${surname.toUpperCase()}'.trim()
        : (userRole == 'yakin' ? 'ASKERİM' : 'MEHMETÇİK');

    return UserPreviewSnapshot(
      fullName: full,
      rutbe: rutbe.isNotEmpty ? rutbe.toUpperCase() : 'ER',
      kuvvetLogo: logo,
      askerlikYeri: askerlikYeri.isNotEmpty ? askerlikYeri : 'Belirtilmedi',
      memleket: memleket.isNotEmpty ? memleket : 'Belirtilmedi',
      userRole: userRole,
      relationship: relationship,
      remainingDays: remDays,
    );
  }
}

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  String _activeThemePath = 'assets/images/img0.webp';
  String _selectedCategory = 'Tümü';
  UserPreviewSnapshot? _userSnapshot;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
    final snapshot = await UserPreviewSnapshot.load();
    if (mounted) {
      setState(() {
        _activeThemePath = savedTheme;
        _userSnapshot = snapshot;
      });
    }
  }

  List<ThemeItem> get _filteredThemes {
    if (_selectedCategory == 'Tümü') {
      return ThemeCatalog.items;
    }
    return ThemeCatalog.items
        .where((item) => item.category == _selectedCategory)
        .toList();
  }

  int _countForCategory(String category) {
    if (category == 'Tümü') return ThemeCatalog.items.length;
    return ThemeCatalog.items.where((i) => i.category == category).length;
  }

  Future<void> _openPreview(ThemeItem tappedItem) async {
    HapticFeedback.lightImpact();
    final list = _filteredThemes;
    final initialIdx = list.indexWhere((e) => e.id == tappedItem.id);

    await Navigator.of(context).push(
      PageRouteBuilder(
        settings: const RouteSettings(name: 'ThemePreviewPage'),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ThemePreviewPage(
              themes: list,
              initialIndex: initialIdx >= 0 ? initialIdx : 0,
              activeThemePath: _activeThemePath,
              userSnapshot: _userSnapshot,
            ),
          );
        },
      ),
    );

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _activeThemePath = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themes = _filteredThemes;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B0F19),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arka Plan & Temalar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                'Temayı seç, canlı önizle ve uygula',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: RevenueCatService.instance.isPremiumNotifier,
              builder: (context, isPremium, _) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      PremiumPaywallPage.show(context, source: 'theme_page_appbar');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPremium
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFFFFD700), const Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isPremium ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                            size: 14,
                            color: isPremium ? Colors.white : const Color(0xFF1F1600),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPremium ? 'VIP' : 'PRO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: isPremium ? Colors.white : const Color(0xFF1F1600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Top PRO / Preview Info Banner
            _buildTopBanner(),

            // Category Filter Chips
            _buildCategoryFilterBar(),

            const SizedBox(height: 6),

            // Themes Grid
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: RevenueCatService.instance.isPremiumNotifier,
                builder: (context, isPremium, _) {
                  return GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 6,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.59,
                    ),
                    itemCount: themes.length,
                    itemBuilder: (context, index) {
                      final item = themes[index];
                      final isActive = _activeThemePath == item.assetPath;
                      return _buildThemeCard(
                        item: item,
                        isActive: isActive,
                        isPremium: isPremium,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return ValueListenableBuilder<bool>(
      valueListenable: RevenueCatService.instance.isPremiumNotifier,
      builder: (context, isPremium, _) {
        if (isPremium) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF064E3B).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PRO ayrıcalıkların aktif! Tüm özel askeri ve vatan temalarını önizleyip sınırsız uygulayabilirsin.',
                    style: TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            PremiumPaywallPage.show(context, source: 'theme_page_banner');
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF111827)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.wallpaper_rounded,
                    color: Color(0xFF1F1600),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'PRO TEMA KOLEKSİYONU',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Herhangi bir temaya dokunarak şafak kartınla canlı önizle. Özel temalar PRO\'ya dahildir.',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFFBBF24),
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ThemeCatalog.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = ThemeCatalog.categories[index];
          final isSelected = _selectedCategory == category;
          final count = _countForCategory(category);

          return GestureDetector(
            onTap: () {
              if (_selectedCategory != category) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategory = category;
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF151C2C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF0B0F19) : Colors.white70,
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF475569)
                          : Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeCard({
    required ThemeItem item,
    required bool isActive,
    required bool isPremium,
  }) {
    final bool isClassicWhite = item.assetPath == 'assets/images/img0.webp';

    return GestureDetector(
      onTap: () => _openPreview(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF10B981)
                : (item.isPro && !isPremium
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.12)),
            width: isActive ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? const Color(0xFF10B981).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Wallpaper Image
              Hero(
                tag: 'theme_hero_${item.id}',
                child: isClassicWhite
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.wb_sunny_outlined,
                                  color: Color(0xFF334155),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sade Beyaz',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Image.asset(
                        item.assetPath,
                        fit: BoxFit.cover,
                        cacheWidth: 500,
                      ),
              ),

              // Subtle Top & Bottom Gradient Scrim
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ),

              // Mini Mockup Lines in Center (subtle phone UI hint)
              if (!isClassicWhite)
                Positioned(
                  top: 46,
                  left: 14,
                  right: 14,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.72,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ŞAFAK',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  '${_userSnapshot?.remainingDays ?? 84}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: Colors.white24,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'ATARSA',
                                  style: TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  '${((_userSnapshot?.remainingDays ?? 84) - 1).clamp(0, 999)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Top Status Badges
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 11),
                            SizedBox(width: 3),
                            Text(
                              'AKTİF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!item.isPro)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          'ÜCRETSİZ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    if (item.isPro)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPremium
                                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                : [const Color(0xFFFFD700), const Color(0xFFF59E0B)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPremium
                                  ? Icons.lock_open_rounded
                                  : Icons.workspace_premium_rounded,
                              size: 11,
                              color: isPremium ? Colors.white : const Color(0xFF1F1600),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'PRO',
                              style: TextStyle(
                                color: isPremium ? Colors.white : const Color(0xFF1F1600),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom Title + Preview CTA
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Önizle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CANLI UYGULAMA ÖNİZLEME EKRANI (THEME PREVIEW PAGE)
// ============================================================================
class ThemePreviewPage extends StatefulWidget {
  final List<ThemeItem> themes;
  final int initialIndex;
  final String activeThemePath;
  final UserPreviewSnapshot? userSnapshot;

  const ThemePreviewPage({
    super.key,
    required this.themes,
    required this.initialIndex,
    required this.activeThemePath,
    this.userSnapshot,
  });

  @override
  State<ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<ThemePreviewPage> {
  late PageController _pageController;
  late int _currentIndex;
  late String _activeThemePath;
  UserPreviewSnapshot? _snapshot;

  // 0: Profil & Kartlar Önizlemesi, 1: Şafak Sayaç Önizlemesi, 2: Sade Duvar Kağıdı
  int _previewMode = 0;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _activeThemePath = widget.activeThemePath;
    _snapshot = widget.userSnapshot;
    _pageController = PageController(initialPage: widget.initialIndex);

    if (_snapshot == null) {
      UserPreviewSnapshot.load().then((val) {
        if (mounted) {
          setState(() => _snapshot = val);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ThemeItem get _currentTheme => widget.themes[_currentIndex];

  Future<void> _handleApplyPressed() async {
    if (_isApplying) return;
    final item = _currentTheme;

    if (item.assetPath == _activeThemePath) {
      HapticFeedback.selectionClick();
      return;
    }

    final bool isPremium = RevenueCatService.instance.isPremium;

    // PRO gerektiren tema ve kullanıcı henüz PRO değilse -> PRO ayrıcalığı olduğunu göster ve Paywall'a yönlendir
    if (item.isPro && !isPremium) {
      HapticFeedback.mediumImpact();
      await _showProPrivilegeGateSheet(item);
      return;
    }

    await _applyThemeAndNavigate(item);
  }

  Future<void> _applyThemeAndNavigate(ThemeItem item) async {
    setState(() => _isApplying = true);
    HapticFeedback.heavyImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeImage', item.assetPath);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'ManagePages'),
        builder: (context) => ManagePages(backgroundImage: item.assetPath),
      ),
      (route) => false,
    );
  }

  Future<void> _showProPrivilegeGateSheet(ThemeItem item) async {
    final bool? goToPaywall = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 14,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),

              // Theme Preview Thumbnail + PRO Crown Badge
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 62,
                          height: 82,
                          child: Image.asset(
                            item.assetPath,
                            fit: BoxFit.cover,
                            cacheWidth: 250,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 14,
                            color: Color(0xFF1F1600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO AYRICALIĞI',
                            style: TextStyle(
                              color: Color(0xFF1F1600),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${item.title} Teması',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Özel arka plan değiştirme özelliği Şafak Sayar PRO ayrıcalıklarına aittir.',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // PRO Perks Summary Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPerkItem(
                      Icons.wallpaper_rounded,
                      'Tüm özel askeri, bayrak ve vatan temalarına sınırsız erişim',
                    ),
                    const SizedBox(height: 10),
                    _buildPerkItem(
                      Icons.block_rounded,
                      'Sıfır reklam ile kesintisiz ve akıcı şafak takibi',
                    ),
                    const SizedBox(height: 10),
                    _buildPerkItem(
                      Icons.favorite_rounded,
                      'Sevdiklerinle canlı şafak takip kodu & zaman kapsülü',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Primary CTA -> Redirect to Paywall
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  icon: const Icon(
                    Icons.lock_open_rounded,
                    size: 18,
                    color: Color(0xFF1F1600),
                  ),
                  label: const Text(
                    'PRO\'YA GEÇ & BU TEMAYI UYGULA',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F1600),
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF1F1600),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Önizlemeye Dön',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (goToPaywall == true && mounted) {
      await PremiumPaywallPage.show(context, source: 'theme_preview');
      // Kullanıcı Paywall'da PRO üyeliği başlattıysa seçtiği temayı otomatik olarak uygula!
      if (mounted && RevenueCatService.instance.isPremium) {
        await _applyThemeAndNavigate(item);
      }
    }
  }

  Widget _buildPerkItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFFFBBF24)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _currentTheme;
    final bool isDefaultWhite = item.assetPath == 'assets/images/img0.webp';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDefaultWhite && _previewMode != 2
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: isDefaultWhite ? Colors.white : const Color(0xFF0B0F19),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Swipeable Full-Screen Background Wallpaper
            PageView.builder(
              controller: _pageController,
              itemCount: widget.themes.length,
              onPageChanged: (idx) {
                HapticFeedback.selectionClick();
                setState(() {
                  _currentIndex = idx;
                });
              },
              itemBuilder: (context, index) {
                final pageItem = widget.themes[index];
                final isWhite = pageItem.assetPath == 'assets/images/img0.webp';
                return Hero(
                  tag: 'theme_hero_${pageItem.id}',
                  child: isWhite
                      ? Container(color: Colors.white)
                      : Image.asset(
                          pageItem.assetPath,
                          fit: BoxFit.cover,
                        ),
                );
              },
            ),

            // 2. Simulated Live App UI Overlay (unless hidden in mode 2)
            SafeArea(
              child: Column(
                children: [
                  // Top Bar (Back + Preview Indicator + Mode Switcher)
                  _buildPreviewTopBar(isDefaultWhite),

                  // Mode Selector Pills (Profil Görünümü / Sayaç Görünümü / Sade Görsel)
                  _buildPreviewModeSelector(isDefaultWhite),

                  // Simulated App Content Area
                  Expanded(
                    child: IgnorePointer(
                      ignoring: true,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: _previewMode == 2
                            ? const SizedBox.expand(key: ValueKey('raw_wallpaper'))
                            : _previewMode == 0
                                ? _buildSimulatedProfilePreview(
                                    key: const ValueKey('profile_sim'),
                                    isDefaultTheme: isDefaultWhite,
                                  )
                                : _buildSimulatedHomePreview(
                                    key: const ValueKey('home_sim'),
                                    isDefaultTheme: isDefaultWhite,
                                  ),
                      ),
                    ),
                  ),

                  // Swipe Hint
                  if (widget.themes.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '‹ Kaydırarak diğer temaları dene (${_currentIndex + 1}/${widget.themes.length}) ›',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Bottom Apply Action Dock
                  _buildBottomApplyDock(item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTopBar(bool isDefaultWhite) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
                      SizedBox(width: 5),
                      Text(
                        'Temalar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Live Preview Badge
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'CANLI ÖNİZLEME',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Quick Raw Wallpaper Toggle
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _previewMode = _previewMode == 2 ? 0 : 2;
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _previewMode == 2
                        ? const Color(0xFFF59E0B)
                        : Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Icon(
                    _previewMode == 2
                        ? Icons.layers_rounded
                        : Icons.fullscreen_rounded,
                    color: _previewMode == 2 ? const Color(0xFF1F1600) : Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewModeSelector(bool isDefaultWhite) {
    final modes = [
      (0, Icons.badge_outlined, 'Profil Kartı'),
      (1, Icons.timer_outlined, 'Şafak Ekranı'),
      (2, Icons.image_outlined, 'Tam Görsel'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              children: modes.map((m) {
                final bool selected = _previewMode == m.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _previewMode = m.$1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            m.$2,
                            size: 14,
                            color: selected ? const Color(0xFF0F172A) : Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            m.$3,
                            style: TextStyle(
                              color: selected ? const Color(0xFF0F172A) : Colors.white70,
                              fontSize: 11,
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // SIMULATED PROFILE VIEW (Gerçek kullanıcı verileriyle canlı önizleme)
  // ============================================================================
  Widget _buildSimulatedProfilePreview({
    required Key key,
    required bool isDefaultTheme,
  }) {
    final snap = _snapshot;
    final bool isDark = !isDefaultTheme;
    final Color cardColor = isDefaultTheme
        ? Colors.white.withValues(alpha: 0.92)
        : Colors.black.withValues(alpha: 0.48);
    final Color borderColor = isDefaultTheme
        ? Colors.grey.shade300
        : Colors.white.withValues(alpha: 0.16);
    final Color textColor = isDefaultTheme ? Colors.black : Colors.white;
    final Color subColor = isDefaultTheme ? Colors.black54 : Colors.white70;
    final bool isRelative = snap?.userRole == 'yakin';

    return SingleChildScrollView(
      key: key,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Simulated ID Card (matches ProfileScreen._buildIDCard)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDefaultTheme ? 0.06 : 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(
                        snap?.kuvvetLogo ?? 'assets/images/app_logo.png',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isRelative)
                            const Text(
                              'TAKİP EDİLEN ASKER',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.pinkAccent,
                                letterSpacing: 0.7,
                              ),
                            ),
                          Text(
                            snap?.fullName ?? 'MEHMETÇİK',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: isRelative
                                  ? Colors.pinkAccent.withValues(alpha: 0.15)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.14)
                                      : Colors.blueAccent.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isRelative
                                  ? SoldierMatchService.getRelationshipLabel(snap?.relationship)
                                      .toUpperCase()
                                  : (snap?.rutbe ?? 'ER'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isRelative
                                    ? Colors.pinkAccent
                                    : (isDark ? Colors.white : Colors.blueAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  height: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSimDetail(
                        Icons.location_on_outlined,
                        isRelative ? 'ASKERİN BİRLİĞİ' : 'GÖREV YERİ',
                        snap?.askerlikYeri ?? 'Belirtilmedi',
                        textColor,
                        subColor,
                      ),
                    ),
                    Expanded(
                      child: _buildSimDetail(
                        Icons.home_outlined,
                        'MEMLEKET',
                        snap?.memleket ?? 'Belirtilmedi',
                        textColor,
                        subColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Simulated Settings Tiles
          _buildSimTile(
            icon: Icons.military_tech_rounded,
            title: 'Askeri Temalar Kullan',
            trailingText: _currentTheme.title,
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            isDark: isDark,
            accent: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 8),
          _buildSimTile(
            icon: Icons.notifications_active_outlined,
            title: 'Bildirim Saati',
            trailingText: '21:00',
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            isDark: isDark,
            accent: Colors.deepOrange,
          ),
          const SizedBox(height: 8),
          _buildSimTile(
            icon: Icons.auto_stories_rounded,
            title: 'Terhis Anı Defteri',
            trailingText: '',
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            isDark: isDark,
            accent: Colors.teal,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SIMULATED HOME / ŞAFAK VIEW
  // ============================================================================
  Widget _buildSimulatedHomePreview({
    required Key key,
    required bool isDefaultTheme,
  }) {
    final snap = _snapshot;
    final bool isDark = !isDefaultTheme;
    final Color cardColor = isDefaultTheme
        ? Colors.white.withValues(alpha: 0.92)
        : Colors.black.withValues(alpha: 0.48);
    final Color borderColor = isDefaultTheme
        ? Colors.grey.shade300
        : Colors.white.withValues(alpha: 0.16);
    final Color textColor = isDefaultTheme ? Colors.black : Colors.white;
    final Color subColor = isDefaultTheme ? Colors.black54 : Colors.white70;
    final int rem = snap?.remainingDays ?? 84;
    final int atarsa = (rem - 1).clamp(0, 999);
    final bool isRelative = snap?.userRole == 'yakin';

    return SingleChildScrollView(
      key: key,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Dual Şafak & Atarsa Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (isRelative ? const Color(0xFF831843) : const Color(0xFF1E3A8A))
                            .withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.62),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: (isRelative ? Colors.pinkAccent : Colors.blueAccent)
                          .withValues(alpha: 0.5),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRelative ? 'KAVUŞMAYA' : 'ŞAFAK',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isRelative ? Colors.pink.shade200 : Colors.blue.shade200,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$rem',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'GÜN KALDI',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7C2D12).withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.62),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.orangeAccent.withValues(alpha: 0.5),
                      width: 1.4,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRelative ? 'YARIN ŞAFAK' : 'ATARSA',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange.shade200,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$atarsa',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'BİR SONRAKİ GÜN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quote Card over Theme Wallpaper
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_quote_rounded,
                      size: 18,
                      color: isDark ? Colors.amberAccent : Colors.blueAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'GÜNÜN ASKERİ SÖZÜ',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"Şafak ne kadar karanlık olursa olsun, güneşin doğuşu o kadar muhteşem olacaktır."',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimDetail(
    IconData icon,
    String label,
    String value,
    Color textColor,
    Color subColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 15, color: subColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: subColor,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimTile({
    required IconData icon,
    required String title,
    required String trailingText,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required bool isDark,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark ? Colors.white : accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailingText.isNotEmpty) ...[
            Text(
              trailingText,
              style: TextStyle(
                color: isDark ? Colors.white70 : accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: isDark ? Colors.white54 : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BOTTOM APPLY DOCK
  // ============================================================================
  Widget _buildBottomApplyDock(ThemeItem item) {
    final bool isCurrentlyActive = item.assetPath == _activeThemePath;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: ValueListenableBuilder<bool>(
            valueListenable: RevenueCatService.instance.isPremiumNotifier,
            builder: (context, isPremium, _) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F19).withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selected Theme Info Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (item.isPro)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isPremium
                                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                              : [const Color(0xFFFFD700), const Color(0xFFF59E0B)],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPremium
                                                ? Icons.verified_rounded
                                                : Icons.workspace_premium_rounded,
                                            size: 11,
                                            color: isPremium
                                                ? Colors.white
                                                : const Color(0xFF1F1600),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'PRO',
                                            style: TextStyle(
                                              color: isPremium
                                                  ? Colors.white
                                                  : const Color(0xFF1F1600),
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'VARSAYILAN',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.category} • ${item.subtitle.trim()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Primary Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isCurrentlyActive || _isApplying
                            ? null
                            : _handleApplyPressed,
                        icon: _isApplying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                isCurrentlyActive
                                    ? Icons.check_circle_rounded
                                    : Icons.check_rounded,
                                size: 20,
                              ),
                        label: Text(
                          isCurrentlyActive
                              ? 'Şu Anda Aktif Tema'
                              : 'Temayı Uygula',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrentlyActive
                              ? const Color(0xFF10B981).withValues(alpha: 0.25)
                              : Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF10B981).withValues(alpha: 0.22),
                          disabledForegroundColor: const Color(0xFF34D399),
                          foregroundColor: const Color(0xFF0B0F19),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
