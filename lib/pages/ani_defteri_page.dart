import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:confetti/confetti.dart';
import 'package:safaksayar/Services/log_service.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class AniDefteriPage extends StatefulWidget {
  const AniDefteriPage({super.key});

  @override
  State<AniDefteriPage> createState() => _AniDefteriPageState();
}

class _AniDefteriPageState extends State<AniDefteriPage> {
  final PageController _pageController = PageController();
  late ConfettiController _confettiController;
  final GlobalKey _shareCardKey = GlobalKey();
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isPreview = false;

  // User details
  String _name = '';
  String _surname = '';
  String _sulusTarihi = '';
  String _terhisTarihi = '';
  String _kuvvet = '';
  String _rutbe = '';
  String _askerlikYeri = '';
  String _memleket = '';

  // Stats
  int _totalDurationSeconds = 0;
  int _totalClicks = 0;
  String _mostVisitedPage = 'Ana Sayfa';
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _loadAllData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString('name') ?? 'Asker';
      _surname = prefs.getString('surname') ?? '';
      _sulusTarihi = prefs.getString('sulus_tarihi') ?? '';
      _terhisTarihi = prefs.getString('end_date') ?? '';
      _kuvvet = prefs.getString('kuvvet_komutanligi') ?? 'Kara';
      _rutbe = prefs.getString('rutbe') ?? 'ER';
      _askerlikYeri = prefs.getString('askerlik_yeri') ?? 'Belirtilmedi';
      _memleket = prefs.getString('memleket') ?? 'Belirtilmedi';

      // Load Firestore stats
      final stats = await LogService.instance.getUserStats();
      _totalDurationSeconds = stats['totalDuration'] ?? 0;
      _totalClicks = stats['totalClicks'] ?? 0;
      _mostVisitedPage = stats['mostVisitedPage'] ?? 'Ana Sayfa';

      // Load local SQLite notes
      final dbPath = p.join(await getDatabasesPath(), 'notes.db');
      if (await DatabaseException(dbPath).databaseExists()) {
        final database = await openDatabase(dbPath, version: 1);
        final List<Map<String, dynamic>> loadedNotes = await database.query('notes', orderBy: 'date ASC');
        _notes = loadedNotes;
      }

      // Check if service is completed
      if (_terhisTarihi.isNotEmpty) {
        try {
          final terhis = DateTime.parse(_terhisTarihi);
          _isPreview = DateTime.now().isBefore(terhis);
        } catch (_) {
          _isPreview = false;
        }
      }
    } catch (e) {
      debugPrint('Error loading memory book data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _confettiController.play();
      }
    }
  }

  // Determine theme colors based on Kuvvet Komutanlığı
  Color _getPrimaryColor() {
    switch (_kuvvet.toLowerCase()) {
      case 'deniz':
        return const Color(0xFF0F3156); // Deep Navy Blue
      case 'hava':
        return const Color(0xFF2C5E8A); // Air Force Blue/Gray
      case 'kara':
      case 'jandarma':
        return const Color(0xFF3B533E); // Camo/Olive Green
      default:
        return const Color(0xFFB8860B); // Brass/Gold
    }
  }

  Color _getAccentColor() {
    switch (_kuvvet.toLowerCase()) {
      case 'deniz':
        return const Color(0xFFF9A825); // Ocean Amber/Gold
      case 'hava':
        return const Color(0xFF00E5FF); // Cyber Sky Blue
      case 'kara':
      case 'jandarma':
        return const Color(0xFFC5A059); // Camo Brass Gold
      default:
        return const Color(0xFFFFD700); // Gold
    }
  }

  String _getKuvvetBadgeAsset() {
    switch (_kuvvet.toLowerCase()) {
      case 'deniz':
        return 'assets/images/Deniz.webp';
      case 'hava':
        return 'assets/images/Hava.webp';
      case 'kara':
        return 'assets/images/Kara.webp';
      case 'jandarma':
        return 'assets/images/Jandarma.webp';
      default:
        return 'assets/images/app_logo.png';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '0 saniye';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours saat $minutes dakika';
    }
    return '$minutes dakika';
  }

  String _formatDateString(String isoString) {
    if (isoString.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return isoString;
    }
  }

  void _shareJourneyText(BuildContext context) {
    final sDate = _formatDateString(_sulusTarihi);
    final tDate = _formatDateString(_terhisTarihi);
    
    final shareText = _isPreview 
        ? '''
🫡 VATAN BORCU ÖDENİYOR! ŞAFAK SAYAR GÜNLÜĞÜM 🇹🇷

Askerlik şerefli görevime devam ediyorum! Bu süreçte Şafak Sayar uygulaması ile tuttuğum günlüğümün ve istatistiklerimin ön izlemesi:

🎖️ Rütbe: $_rutbe
📍 Görev Yeri: $_askerlikYeri
📅 Sülüs Tarihi: $sDate
📅 Terhis Tarihi: $tDate
📝 Şu Ama Kadar Kaydedilen Anı/Not: ${_notes.length} adet
⏱️ Uygulamada Geçen Vakit: ${_formatDuration(_totalDurationSeconds)}
🎯 Toplam Kontrol & Clicks: $_totalClicks kez

Bizimle bu kutlu yolda yürüyen herkese selamlar! Vatan Sağ Olsun! 🇹🇷🫡
'''
        : '''
🫡 GÖREV TAMAMLANDI! ŞAFAK BİTTİ! 🇹🇷

Askerlik şerefli görevimi tamamladım ve terhis oldum! Bu süreçte Şafak Sayar uygulaması ile tuttuğum günlük ve istatistiklerim:

🎖️ Rütbe: $_rutbe
📍 Görev Yeri: $_askerlikYeri
📅 Sülüs Tarihi: $sDate
📅 Terhis Tarihi: $tDate
📝 Kaydedilen Anı/Not: ${_notes.length} adet
⏱️ Uygulamada Geçen Vakit: ${_formatDuration(_totalDurationSeconds)}
🎯 Toplam Kontrol & Clicks: $_totalClicks kez

Bizimle bu kutlu yolda yürüyen herkese teşekkürler! Vatan Sağ Olsun! 🇹🇷🫡
''';
    
    final box = context.findRenderObject() as RenderBox?;
    Rect? sharePositionOrigin;
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
    } else {
      final double screenWidth = MediaQuery.sizeOf(context).width;
      final double screenHeight = MediaQuery.sizeOf(context).height;
      sharePositionOrigin = Rect.fromLTWH(
        screenWidth / 2 - 10,
        screenHeight / 2 - 10,
        20,
        20,
      );
    }
    Share.share(shareText, sharePositionOrigin: sharePositionOrigin);
  }

  Future<void> _shareJourney(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return const Center(
            child: Card(
              color: Color(0xFF131A26),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(width: 16),
                    Text(
                      'Paylaşım görseli hazırlanıyor...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Give frame a brief moment to render (just in case)
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _shareCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('RenderRepaintBoundary not found');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Could not convert image to bytes');
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/safak_gunlugu.png');
      await file.writeAsBytes(pngBytes);

      if (context.mounted) {
        Navigator.of(context).pop();
      }

      final box = context.findRenderObject() as RenderBox?;
      Rect? sharePositionOrigin;
      if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
        sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
      } else {
        final double screenWidth = MediaQuery.sizeOf(context).width;
        final double screenHeight = MediaQuery.sizeOf(context).height;
        sharePositionOrigin = Rect.fromLTWH(
          screenWidth / 2 - 10,
          screenHeight / 2 - 10,
          20,
          20,
        );
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: _isPreview 
            ? 'Vatan Borcu Ödeniyor! Şafak Sayar Günlüğüm 🇹🇷'
            : 'Görev Tamamlandı! Şafak Bitti! 🇹🇷',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      debugPrint('Error sharing memory card image: $e');
      if (context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (_) {}
      }
      _shareJourneyText(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = _getPrimaryColor();
    final Color accentColor = _getAccentColor();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0A0F1D),
                primaryColor.withValues(alpha: 0.15),
                const Color(0xFF03070E),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Stack(
                    children: [
                      // Confetti Effect
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          shouldLoop: false,
                          colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
                          gravity: 0.3,
                        ),
                      ),

                      Column(
                        children: [
                          // Custom Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                                ),
                                Text(
                                  'ŞAFAK GÜNLÜĞÜ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: accentColor,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _confettiController.play();
                                  },
                                  icon: Icon(Icons.celebration_rounded, color: accentColor, size: 24),
                                ),
                              ],
                            ),
                          ),

                          // Pages Indicator
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                            child: Row(
                              children: List.generate(4, (index) {
                                final bool isActive = _currentPage == index;
                                return Expanded(
                                  child: Container(
                                    height: 5,
                                    margin: EdgeInsets.only(left: index == 0 ? 0 : 6),
                                    decoration: BoxDecoration(
                                      color: isActive ? accentColor : Colors.white24,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),

                          if (_isPreview) ...[
                            const SizedBox(height: 8),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ÖN İZLEME: Askerliğin bittiğinde tam sürüm açılacaktır!',
                                      style: TextStyle(
                                        color: Colors.amber.shade200,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),

                          // Scrollable Pages
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: (page) {
                                setState(() {
                                  _currentPage = page;
                                });
                              },
                              children: [
                                _buildCertificatePage(accentColor),
                                _buildStatsPage(accentColor),
                                _buildNotesPage(accentColor),
                                _buildSharePage(accentColor),
                              ],
                            ),
                          ),

                          // Swipe Hint or Action Button
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_currentPage > 0)
                                  TextButton.icon(
                                    onPressed: () {
                                      _pageController.previousPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                                    label: const Text('Geri', style: TextStyle(color: Colors.white70)),
                                  )
                                else
                                  const SizedBox.shrink(),
                                
                                if (_currentPage < 3)
                                  ElevatedButton(
                                    onPressed: () {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text('İleri', style: TextStyle(fontWeight: FontWeight.bold)),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                                  )
                                else
                                  Builder(
                                    builder: (buttonContext) {
                                      return ElevatedButton.icon(
                                        onPressed: () => _shareJourney(buttonContext),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        icon: const Icon(Icons.share_rounded, size: 18),
                                        label: const Text('Hatırayı Paylaş', style: TextStyle(fontWeight: FontWeight.bold)),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // --- PAGES ---

  // Page 1: Terhis Belgesi
  Widget _buildCertificatePage(Color accentColor) {
    final sDate = _formatDateString(_sulusTarihi);
    final tDate = _formatDateString(_terhisTarihi);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Emblem Header
            Image.asset(
              _getKuvvetBadgeAsset(),
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.military_tech, color: Colors.white38, size: 70),
            ),
            const SizedBox(height: 16),
            const Text(
              'T.C.\nMİLLÎ SAVUNMA BAKANLIĞI',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 1.5,
              width: 100,
              color: accentColor,
            ),
            const SizedBox(height: 24),
            Text(
              _isPreview ? 'DİJİTAL TERHİS ANISI (ÖN İZLEME)' : 'DİJİTAL TERHİS ANISI',
              style: TextStyle(
                color: accentColor,
                fontSize: _isPreview ? 14 : 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 28),
            
            // Certificate Details
            _buildCertificateRow('YİĞİT ASKER:', '${_name.toUpperCase()} ${_surname.toUpperCase()}'),
            _buildCertificateRow('RÜTBE:', _rutbe.toUpperCase()),
            _buildCertificateRow('KUVVET:', _kuvvet.toUpperCase() + ' KOMUTANLIĞI'),
            _buildCertificateRow('MEMLEKET:', _memleket),
            _buildCertificateRow('GÖREV YERİ:', _askerlikYeri),
            _buildCertificateRow('SÜLÜS TARİHİ:', sDate),
            _buildCertificateRow('TERHİS TARİHİ:', tDate),

            const SizedBox(height: 32),
            Text(
              'Bu belge, vatan borcunu başarıyla ve onurla ifa eden kahraman askerimizin Şafak Sayar günlerini yaşatmak adına düzenlenmiştir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Şafak Sayar Ailesi',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '🫡 Vatan Sağ Olsun!',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 12),
        ],
      ),
    );
  }

  // Page 2: Rakamlarla Yolculuk
  Widget _buildStatsPage(Color accentColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RAKAMLARLA YOLCULUĞUN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Şafak sayarken geçirdiğin günlerde uygulamadaki ayak izlerin:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white60,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Stats Grid/Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Toplam Vakit', _formatDuration(_totalDurationSeconds), Icons.hourglass_top_rounded, accentColor)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Günlük Notların', '${_notes.length} Adet', Icons.edit_note_rounded, accentColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('Şafak Tıklama', '$_totalClicks Kez', Icons.ads_click_rounded, accentColor)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Gözde Sayfan', _mostVisitedPage, Icons.star_outline_rounded, accentColor)),
            ],
          ),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131A26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.military_tech_rounded, color: accentColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Uygulamadaki her ziyaretinde şafak hasretini dindirmeye ve sana yol arkadaşı olmaya çalıştık. Seninle gurur duyuyoruz!',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: accentColor, size: 22),
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Page 3: Askerlik Günlüğü (Notlar)
  Widget _buildNotesPage(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASKERLİK GÜNLÜĞÜN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hizmet süresince kaydettiğin anılar ve notlar:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: _notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 48, color: Colors.white24),
                        const SizedBox(height: 12),
                        const Text(
                          'Kayıtlı not bulunamadı.',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Süreç boyunca not eklenmemiş.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white24, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      String formattedDate = '';
                      try {
                        final parsed = DateTime.parse(note['date']);
                        formattedDate = DateFormat('dd MMM yyyy HH:mm').format(parsed);
                      } catch (_) {
                        formattedDate = note['date'] ?? '';
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A26),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: accentColor,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              note['text'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Page 4: Paylaşım Sayfası
  Widget _buildSharePage(Color accentColor) {
    final sDate = _formatDateString(_sulusTarihi);
    final tDate = _formatDateString(_terhisTarihi);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          RepaintBoundary(
            key: _shareCardKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1B263B), _getPrimaryColor()],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _isPreview ? '🇹🇷 ŞAFAK GÜNLÜĞÜ (ÖN İZLEME) 🫡' : '🇹🇷 GÖREV TAMAMLANDI 🫡',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Image.asset(
                    _getKuvvetBadgeAsset(),
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_name.toUpperCase()} ${_surname.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rütbe: ${_rutbe.toUpperCase()}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  
                  _buildShareSummaryRow('📅 Sülüs', sDate),
                  _buildShareSummaryRow('📅 Terhis', tDate),
                  _buildShareSummaryRow('📝 Yazılan Not', '${_notes.length} Adet'),
                  _buildShareSummaryRow('⏱️ Geçen Vakit', _formatDuration(_totalDurationSeconds)),
                  _buildShareSummaryRow('📍 Görev Yeri', _askerlikYeri),

                  const SizedBox(height: 16),
                  Text(
                    _isPreview ? '#ŞafakSavar #YolculukDevamEdiyor' : '#ŞafakBitti #TerhisOldum',
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isPreview
                ? 'Şafak yolculuğunu tek tıkla sosyal medyada paylaş ve ön izleme günlüğünü arkadaşlarına göster!'
                : 'Terhis hikayeni tek tıkla sosyal medyada paylaş ve arkadaşlarınla bu gururu yaşa!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Safely throw exception to check path existence
class DatabaseException {
  final String path;
  DatabaseException(this.path);

  Future<bool> databaseExists() async {
    try {
      return await File(path).exists();
    } catch (_) {
      return false;
    }
  }
}
