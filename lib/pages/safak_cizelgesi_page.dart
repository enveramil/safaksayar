import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class SafakCizelgesiPage extends StatefulWidget {
  final String? backgroundImage;
  const SafakCizelgesiPage({super.key, this.backgroundImage});

  @override
  State<SafakCizelgesiPage> createState() => _SafakCizelgesiPageState();
}

class _SafakCizelgesiPageState extends State<SafakCizelgesiPage> {
  late String _backgroundImage;
  Map<int, String> _dayColors = {}; // Gün sayısı -> Renk değeri (Hex String)
  int _totalDays = 180;
  DateTime? _startDate;
  Color _activeColor = const Color(0xFFEF4444); // Kırmızı (Varsayılan)
  bool _isEraserMode = false;

  // Görseldeki gibi zengin renk paleti
  final List<Color> _presetColors = [
    const Color(0xFFEF4444), // Kırmızı
    const Color(0xFFF87171), // Açık Kırmızı
    const Color(0xFFEC4899), // Pembe
    const Color(0xFFD946EF), // Eflatun
    const Color(0xFF8B5CF6), // Mor
    const Color(0xFF6366F1), // İndigo
    const Color(0xFF3B82F6), // Mavi
    const Color(0xFF60A5FA), // Açık Mavi
    const Color(0xFF06B6D4), // Turkuaz
    const Color(0xFF14B8A6), // Teal
    const Color(0xFF10B981), // Yeşil
    const Color(0xFF84CC16), // Açık Yeşil
    const Color(0xFFFBBF24), // Sarı
    const Color(0xFFF97316), // Turuncu
    const Color(0xFF78350F), // Kahverengi
    const Color(0xFF64748B), // Slate Gri
    const Color(0xFF0F172A), // Lacivert/Siyah
  ];

  bool get _isDefaultTheme => _backgroundImage == 'assets/images/img0.webp';

  Color _getTextColor() {
    return _isDefaultTheme ? Colors.black87 : Colors.white;
  }


  @override
  void initState() {
    super.initState();
    _backgroundImage = widget.backgroundImage ?? 'assets/images/img0.webp';
    _loadCizelgeData();
  }

  Future<void> _loadCizelgeData() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.backgroundImage == null) {
      final imagePath = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
      setState(() {
        _backgroundImage = imagePath;
      });
    }

    final String? startDateStr = prefs.getString('sulus_tarihi');
    final String? endDateStr = prefs.getString('end_date');

    if (startDateStr != null && endDateStr != null) {
      try {
        final DateTime start = DateTime.parse(startDateStr);
        final DateTime end = DateTime.parse(endDateStr);
        _startDate = start;
        final days = end.difference(start).inDays + 1;
        setState(() {
          _totalDays = days > 0 ? days : 180;
        });
      } catch (e) {
        print("Tarih parse hatası: $e");
        setState(() {
          _totalDays = 180;
        });
      }
    } else {
      setState(() {
        _totalDays = 180;
      });
    }

    final String? savedColors = prefs.getString('safak_cizelgesi_colors');
    if (savedColors != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(savedColors);
        final Map<int, String> loadedColors = {};
        decoded.forEach((key, value) {
          final int? day = int.tryParse(key);
          if (day != null && value is String) {
            loadedColors[day] = value;
          }
        });
        setState(() {
          _dayColors = loadedColors;
        });
      } catch (e) {
        print("Boyama verisi yükleme hatası: $e");
      }
    }
  }

  Future<void> _saveCizelgeData() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> toSave = {};
    _dayColors.forEach((key, value) {
      toSave[key.toString()] = value;
    });
    await prefs.setString('safak_cizelgesi_colors', jsonEncode(toSave));
  }

  void _paintDay(int dayNumber) {
    if (!_isEraserMode) {
      final DateTime? date = _calculateDateForDay(dayNumber);
      if (date != null) {
        final today = DateTime.now();
        final todayMidnight = DateTime(today.year, today.month, today.day);
        final cellDateMidnight = DateTime(date.year, date.month, date.day);
        if (cellDateMidnight.isAfter(todayMidnight)) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gelecek günleri boyayamazsınız.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orangeAccent,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
      }
    }

    HapticFeedback.lightImpact();
    setState(() {
      if (_isEraserMode) {
        _dayColors.remove(dayNumber);
      } else {
        _dayColors[dayNumber] = _activeColor.toARGB32().toString();
      }
    });
    _saveCizelgeData();
  }

  void _clearCizelge() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Çizelgeyi Temizle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            'Tüm boyamalarınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Vazgeç', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _dayColors.clear();
                });
                _saveCizelgeData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Tüm boyamalar temizlendi.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Temizle'),
            ),
          ],
        );
      },
    );
  }

  void _shareProgress(BuildContext context) {
    final double percent = (_dayColors.length / _totalDays) * 100;
    final String shareText =
        'Şafak Çizelgemde ${_totalDays} günün ${_dayColors.length} gününü boyadım! 🎨\n'
        'Tamamlanma Oranı: %${percent.toStringAsFixed(1)}\n'
        'Şafak Sayar ile sen de şafağını renklendir! 🇹🇷';
    
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

  DateTime? _calculateDateForDay(int dayNumber) {
    if (_startDate == null) return null;
    return _startDate!.add(Duration(days: dayNumber - 1));
  }

  void _showDayDetails(int dayNumber) {
    HapticFeedback.mediumImpact();
    final DateTime? date = _calculateDateForDay(dayNumber);
    final String dateText = date != null
        ? DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(date)
        : 'Bilgi Yok';

    final String colorHex = _dayColors[dayNumber] ?? '';
    final bool isPainted = colorHex.isNotEmpty;

    // Gelecek gün kontrolü
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final cellDateMidnight = date != null ? DateTime(date.year, date.month, date.day) : null;
    final bool isFuture = cellDateMidnight != null && cellDateMidnight.isAfter(todayMidnight);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDark = !_isDefaultTheme;
        final Color modalBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
        final Color textCol = isDark ? Colors.white : Colors.black87;
        final Color subCol = isDark ? Colors.white70 : Colors.black54;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: modalBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$dayNumber. GÜN DETAYI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tarih', style: TextStyle(fontSize: 11, color: subCol, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(dateText, style: TextStyle(fontSize: 14, color: textCol, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    isPainted ? Icons.palette_rounded : Icons.palette_outlined,
                    color: isPainted ? Color(int.parse(colorHex)) : subCol,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Boyama Durumu', style: TextStyle(fontSize: 11, color: subCol, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          isPainted ? 'Boyandı' : 'Boyanmadı',
                          style: TextStyle(
                            fontSize: 14,
                            color: isPainted ? Color(int.parse(colorHex)) : textCol,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isFuture && !isPainted
                          ? null
                          : () {
                              Navigator.pop(context);
                              setState(() {
                                if (isPainted) {
                                  _dayColors.remove(dayNumber);
                                } else {
                                  _dayColors[dayNumber] = _activeColor.toARGB32().toString();
                                }
                              });
                              _saveCizelgeData();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPainted ? Colors.redAccent : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      icon: Icon(isFuture && !isPainted
                          ? Icons.lock_outline_rounded
                          : (isPainted ? Icons.delete_outline_rounded : Icons.brush_rounded)),
                      label: Text(isFuture && !isPainted
                          ? 'Gelecek Gün'
                          : (isPainted ? 'Boyamayı Sil' : 'Boyama Yap')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Kapat', style: TextStyle(color: textCol)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCustomColorPicker() async {
    final Color? selected = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return _CustomColorPickerDialog(initialColor: _activeColor);
      },
    );

    if (selected != null) {
      setState(() {
        _activeColor = selected;
        _isEraserMode = false;
      });
    }
  }

  // 14 Sütun x 6 Satırlık yatay matris oluşturucu (Sütun-Öncelikli Sıralama)
  List<List<int?>> _generateBlockGrid(int templateType, int startDay, int endDay) {
    List<List<int?>> grid = List.generate(6, (_) => List.generate(14, (_) => null));
    int currentDay = startDay;

    for (int col = 0; col < 14; col++) {
      List<int> activeRows = [];
      if (templateType == 0) {
        // Blok 1: Tek döngü şeridi (Days 1 - 48)
        if (col == 0 || col == 1) {
          activeRows = [5, 4, 3, 2];
        } else if (col >= 2 && col <= 11) {
          activeRows = [5, 4, 3];
        } else if (col == 12 || col == 13) {
          activeRows = [5, 4, 3, 2, 1];
        }
      } else if (templateType == 1) {
        // Blok 2: Çift döngü dikey köprülü şerit (Days 49 - 116)
        if (col == 0 || col == 1 || col == 6 || col == 7 || col == 12 || col == 13) {
          activeRows = [5, 4, 3, 2, 1, 0];
        } else {
          activeRows = [5, 4, 1, 0];
        }
      } else {
        // Blok 3: Geniş tek döngü şeridi (Days 117 - 180)
        if (col == 0 || col == 1 || col == 12 || col == 13) {
          activeRows = [5, 4, 3, 2, 1, 0];
        } else {
          activeRows = [5, 4, 1, 0];
        }
      }

      for (int row in activeRows) {
        if (currentDay <= endDay) {
          grid[row][col] = currentDay;
          currentDay++;
        }
      }
    }
    return grid;
  }

  // Dinamik olarak günleri blok şablonlarına bölen ve listeyi oluşturan fonksiyon
  List<Widget> _buildBlockWidgets() {
    List<Widget> widgets = [];
    int currentDay = 1;
    int blockIndex = 0;

    while (currentDay <= _totalDays) {
      final int templateType = blockIndex % 3; // 0, 1, 2 döngüsü
      final int maxDaysInBlock = templateType == 0 ? 48 : (templateType == 1 ? 68 : 64);
      final int start = currentDay;
      final int end = (currentDay + maxDaysInBlock - 1).clamp(1, _totalDays);

      widgets.add(_buildBlockCard(templateType, start, end, blockIndex + 1));

      currentDay = end + 1;
      blockIndex++;
    }

    // Görseldeki gibi 180. günden 1. güne doğru azalan dikey sırada listeleme
    return widgets.reversed.toList();
  }

  Widget _buildBlockCard(int templateType, int startDay, int endDay, int blockNum) {
    final List<List<int?>> grid = _generateBlockGrid(templateType, startDay, endDay);
    final Color textColor = _getTextColor();
    final bool isDark = !_isDefaultTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double spacing = 4.0;
          const int columns = 14;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(6, (rowIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: rowIndex == 5 ? 0 : spacing),
                child: Row(
                  children: List.generate(columns, (colIndex) {
                    final dayNumber = grid[5 - rowIndex][colIndex];
                    
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: colIndex == columns - 1 ? 0 : spacing),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: dayNumber == null
                              ? const SizedBox.shrink()
                              : _buildCellWidget(dayNumber, textColor, isDark),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildCellWidget(int dayNumber, Color textColor, bool isDark) {
    final String? colorHex = _dayColors[dayNumber];
    final Color? cellColor = colorHex != null ? Color(int.parse(colorHex)) : null;
    final bool isCellPainted = cellColor != null;

    Color cellTextColor;
    if (isCellPainted) {
      cellTextColor = cellColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    } else {
      cellTextColor = isDark ? Colors.white60 : Colors.black54;
    }

    return GestureDetector(
      onTap: () => _paintDay(dayNumber),
      onLongPress: () => _showDayDetails(dayNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cellColor ?? (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCellPainted
                ? cellColor.withValues(alpha: 0.9)
                : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isCellPainted ? 1.0 : 0.8,
          ),
        ),
        child: Text(
          '$dayNumber',
          style: TextStyle(
            color: cellTextColor,
            fontSize: 8.5,
            fontWeight: isCellPainted ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double percent = _totalDays > 0 ? (_dayColors.length / _totalDays) : 0;
    final bool isDark = !_isDefaultTheme;
    final Color textColor = _getTextColor();

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: _isDefaultTheme
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Şafak Çizelgesi',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            // Kaydırılabilir Dikey Çizelge Blokları
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: _buildBlockWidgets(),
                ),
              ),
            ),

            // Alt Kontrol ve İnce Detay Paleti (Glassmorphic)
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.only(
                    top: 10,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.8),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Renk Seçim Paleti (Yatay)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            // Silgi Butonu
                            GestureDetector(
                              onTap: () => setState(() => _isEraserMode = true),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _isEraserMode
                                      ? Colors.redAccent.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isEraserMode ? Colors.redAccent : (isDark ? Colors.white24 : Colors.grey.shade400),
                                    width: _isEraserMode ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.cleaning_services_rounded,
                                  size: 15,
                                  color: _isEraserMode ? Colors.redAccent : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Özel Renk Seçici
                            GestureDetector(
                              onTap: _openCustomColorPicker,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade400, width: 1.0),
                                  gradient: const SweepGradient(
                                    colors: [
                                      Colors.red,
                                      Colors.orange,
                                      Colors.yellow,
                                      Colors.green,
                                      Colors.blue,
                                      Colors.purple,
                                      Colors.red,
                                    ],
                                  ),
                                ),
                                child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Yatay Renk Listesi
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _presetColors.length,
                                  itemBuilder: (context, index) {
                                    final Color color = _presetColors[index];
                                    final bool isSelected = !_isEraserMode && _activeColor == color;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _activeColor = color;
                                          _isEraserMode = false;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        width: 32,
                                        height: 32,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected ? textColor : Colors.transparent,
                                            width: isSelected ? 2.5 : 0.0,
                                          ),
                                        ),
                                        child: isSelected
                                            ? Icon(
                                                Icons.check_rounded,
                                                size: 14,
                                                color: (color.computeLuminance() > 0.5)
                                                    ? Colors.black87
                                                    : Colors.white,
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // "Sevgi Takvimi" Alt Banner Kartı
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.grey.shade300,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // İlerleme Çemberi
                              SizedBox(
                                width: 42,
                                height: 42,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: percent,
                                      strokeWidth: 4.5,
                                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade300,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent.shade400),
                                    ),
                                    Text(
                                      '%${(percent * 100).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Metinler
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sevgi Takvimi',
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_dayColors.length} / $_totalDays Gün Boyandı',
                                      style: TextStyle(
                                        color: _isDefaultTheme ? Colors.black54 : Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Aksiyon Butonları (Paylaş ve Sıfırla)
                              Builder(
                                builder: (buttonContext) {
                                  return IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(6),
                                    icon: Icon(Icons.share_outlined, color: textColor, size: 18),
                                    tooltip: 'Paylaş',
                                    onPressed: () => _shareProgress(buttonContext),
                                  );
                                },
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 18),
                                tooltip: 'Sıfırla',
                                onPressed: _clearCizelge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _CustomColorPickerDialog({required this.initialColor});

  @override
  State<_CustomColorPickerDialog> createState() => _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<_CustomColorPickerDialog> {
  late int _r;
  late int _g;
  late int _b;

  @override
  void initState() {
    super.initState();
    _r = (widget.initialColor.r * 255.0).round().clamp(0, 255);
    _g = (widget.initialColor.g * 255.0).round().clamp(0, 255);
    _b = (widget.initialColor.b * 255.0).round().clamp(0, 255);
  }

  @override
  Widget build(BuildContext context) {
    final Color currentColor = Color.fromARGB(255, _r, _g, _b);
    final String hexCode = '#${_r.toRadixString(16).padLeft(2, '0')}${_g.toRadixString(16).padLeft(2, '0')}${_b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Özel Renk Oluştur',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color Preview
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Center(
              child: Text(
                hexCode,
                style: TextStyle(
                  color: (currentColor.computeLuminance() > 0.5) ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // RGB Sliders
          _buildRGBSlider('Kırmızı (R)', _r, Colors.red, (val) => setState(() => _r = val)),
          const SizedBox(height: 8),
          _buildRGBSlider('Yeşil (G)', _g, Colors.green, (val) => setState(() => _g = val)),
          const SizedBox(height: 8),
          _buildRGBSlider('Mavi (B)', _b, Colors.blue, (val) => setState(() => _b = val)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(currentColor),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Uygula'),
        ),
      ],
    );
  }

  Widget _buildRGBSlider(String label, int value, Color color, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
            Text(value.toString(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 255,
          activeColor: color,
          inactiveColor: Colors.white12,
          divisions: 255,
          onChanged: (val) => onChanged(val.round()),
        ),
      ],
    );
  }
}
