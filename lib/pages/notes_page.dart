import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class _NoteCategoryMeta {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _NoteCategoryMeta({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _QuickTemplate {
  final String category;
  final String badge;
  final String title;
  final String subtitle;
  final String prefillTitle;
  final String prefillBody;
  final IconData icon;
  final Color accent;

  const _QuickTemplate({
    required this.category,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.prefillTitle,
    required this.prefillBody,
    required this.icon,
    required this.accent,
  });
}

class NotesScreen extends StatefulWidget {
  final BuildContext? context;

  const NotesScreen({super.key, this.context});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  Database? _database;
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';

  int _currentSafak = 0;
  String _userRole = 'asker';

  static const List<_NoteCategoryMeta> _categories = [
    _NoteCategoryMeta(
      key: 'Tümü',
      label: 'Tümü',
      icon: Icons.apps_rounded,
      color: Color(0xFF0F172A),
    ),
    _NoteCategoryMeta(
      key: 'Nöbet',
      label: 'Nöbet',
      icon: Icons.shield_outlined,
      color: Color(0xFFD97706),
    ),
    _NoteCategoryMeta(
      key: 'İhtiyaç',
      label: 'İhtiyaç',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFF0284C7),
    ),
    _NoteCategoryMeta(
      key: 'Devreler',
      label: 'Devreler',
      icon: Icons.groups_rounded,
      color: Color(0xFF4F46E5),
    ),
    _NoteCategoryMeta(
      key: 'Anı',
      label: 'Kışla Anısı',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF059669),
    ),
    _NoteCategoryMeta(
      key: 'Genel',
      label: 'Genel',
      icon: Icons.bookmark_border_rounded,
      color: Color(0xFF475569),
    ),
  ];

  List<_QuickTemplate> get _templates {
    final bool isRelative = _userRole == 'yakin';
    final String safakLabel = _currentSafak > 0 ? 'Şafak $_currentSafak' : 'Bugün';

    if (isRelative) {
      return [
        _QuickTemplate(
          category: 'Anı',
          badge: 'HASRET GÜNLÜĞÜ',
          title: 'Askerime Not',
          subtitle: 'Telefon görüşmesi veya kavuşma anısı yaz',
          prefillTitle: '$safakLabel • Askerime Notum',
          prefillBody: 'Bugün hissettiklerim:\n• \n\nTelefonda konuşacaklarımız:\n• ',
          icon: Icons.favorite_border_rounded,
          accent: const Color(0xFF059669),
        ),
        _QuickTemplate(
          category: 'İhtiyaç',
          badge: 'KOLİ & PAKET',
          title: 'Gönderilecekler',
          subtitle: 'Asker kolisi veya ziyaret ihtiyaç listesi',
          prefillTitle: 'Asker Kolisi & İhtiyaçlar',
          prefillBody: '• Termal içlik / çorap\n• Kişisel bakım ürünleri\n• Sevdiği atıştırmalıklar\n• ',
          icon: Icons.inventory_2_outlined,
          accent: const Color(0xFF0284C7),
        ),
        _QuickTemplate(
          category: 'Nöbet',
          badge: 'SAATLER',
          title: 'Görüşme & İzin',
          subtitle: 'Arama saatleri, çarşı ve yemin töreni tarihleri',
          prefillTitle: 'Önemli Tarih & Arama Saatleri',
          prefillBody: '• Telefon görüşmesi saati: \n• Yemin töreni tarihi: \n• İzin / Terhis planı: ',
          icon: Icons.schedule_rounded,
          accent: const Color(0xFFD97706),
        ),
        _QuickTemplate(
          category: 'Devreler',
          badge: 'İLETİŞİM',
          title: 'Birlik & İletişim',
          subtitle: 'Birlik adresi, komutanlık ve arkadaş bilgileri',
          prefillTitle: 'Birlik Adresi & Önemli Numaralar',
          prefillBody: 'Birlik / Bölük: \nAdres: \nDevre / Arkadaş İletişim: ',
          icon: Icons.contact_phone_outlined,
          accent: const Color(0xFF4F46E5),
        ),
      ];
    }

    return [
      _QuickTemplate(
        category: 'Nöbet',
        badge: 'VARDİYA',
        title: 'Nöbet Kaydı',
        subtitle: 'Saat, nöbet yeri, devralınan ve devredilen kişi',
        prefillTitle: '$safakLabel • Nöbet Çizelgem',
        prefillBody: '• Nöbet Saati: 02:00 - 04:00\n• Nöbet Yeri / Kule: \n• Teslim Aldığım: \n• Teslim Edeceğim: ',
        icon: Icons.shield_outlined,
        accent: const Color(0xFFD97706),
      ),
      _QuickTemplate(
        category: 'İhtiyaç',
        badge: 'ÇARŞI & KANTİN',
        title: 'Eksik Listesi',
        subtitle: 'Çarşı izninde veya kantinden alınacaklar',
        prefillTitle: 'Çarşı & Kantin İhtiyaç Listesi',
        prefillBody: '• Tıraş köpüğü & jilet\n• Haki çorap / fanila\n• Bot boyası & vatka\n• ',
        icon: Icons.shopping_bag_outlined,
        accent: const Color(0xFF0284C7),
      ),
      _QuickTemplate(
        category: 'Devreler',
        badge: 'KOĞUŞ REHBERİ',
        title: 'Devre Arkadaşları',
        subtitle: 'Tertip isimleri, memleketleri ve numaraları',
        prefillTitle: 'Koğuş & Devre Rehberi',
        prefillBody: '• İsim: \n  Memleket: \n  Telefon / Instagram: \n\n• İsim: ',
        icon: Icons.groups_rounded,
        accent: const Color(0xFF4F46E5),
      ),
      _QuickTemplate(
        category: 'Anı',
        badge: 'HATIRA',
        title: 'Kışla Anısı',
        subtitle: 'İleride tebessümle okuyacağın bugünün anısı',
        prefillTitle: '$safakLabel Hatırası',
        prefillBody: 'Bugün kışlada unutulmaz bir an:\n',
        icon: Icons.auto_stories_rounded,
        accent: const Color(0xFF059669),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadUserSafakInfo();
    _initDatabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _database?.close();
    super.dispose();
  }

  Future<void> _loadUserSafakInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? 'asker';
    final endStr = prefs.getString('end_date') ?? '';
    int safak = prefs.getInt('remainingDays') ?? 0;

    if (endStr.isNotEmpty) {
      try {
        final end = DateTime.parse(endStr);
        final diff = end.difference(DateTime.now()).inDays;
        safak = diff < 0 ? 0 : diff;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _userRole = role;
        _currentSafak = safak;
      });
    }
  }

  Future<void> _initDatabase() async {
    final dbPath = p.join(await getDatabasesPath(), 'notes.db');
    final db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            text TEXT,
            category TEXT,
            is_pinned INTEGER DEFAULT 0,
            safak_day INTEGER,
            date DATETIME
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureColumnsExist(db);
      },
      onOpen: (db) async {
        await _ensureColumnsExist(db);
      },
    );

    _database = db;
    await _loadNotes();
  }

  Future<void> _ensureColumnsExist(Database db) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info(notes)');
      final existingCols = info.map((row) => row['name']?.toString() ?? '').toSet();

      if (!existingCols.contains('title')) {
        await db.execute("ALTER TABLE notes ADD COLUMN title TEXT DEFAULT ''");
      }
      if (!existingCols.contains('category')) {
        await db.execute("ALTER TABLE notes ADD COLUMN category TEXT DEFAULT 'Genel'");
      }
      if (!existingCols.contains('is_pinned')) {
        await db.execute('ALTER TABLE notes ADD COLUMN is_pinned INTEGER DEFAULT 0');
      }
      if (!existingCols.contains('safak_day')) {
        await db.execute('ALTER TABLE notes ADD COLUMN safak_day INTEGER');
      }
    } catch (e) {
      debugPrint('Notes DB schema check error: $e');
    }
  }

  Future<void> _loadNotes() async {
    final db = _database;
    if (db == null) return;

    final List<Map<String, dynamic>> rawNotes = await db.query(
      'notes',
      orderBy: 'is_pinned DESC, date DESC, id DESC',
    );

    if (mounted) {
      setState(() {
        _notes = rawNotes;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNote({
    int? id,
    required String title,
    required String text,
    required String category,
    required bool isPinned,
    int? existingSafakDay,
  }) async {
    final db = _database;
    if (db == null) return;

    final String nowIso = DateTime.now().toIso8601String();
    final payload = <String, dynamic>{
      'title': title.trim(),
      'text': text.trim(),
      'category': category,
      'is_pinned': isPinned ? 1 : 0,
      'safak_day': existingSafakDay ?? (_currentSafak > 0 ? _currentSafak : null),
      'date': nowIso,
    };

    if (id == null) {
      await db.insert('notes', payload);
    } else {
      await db.update('notes', payload, where: 'id = ?', whereArgs: [id]);
    }

    await _loadNotes();
  }

  Future<void> _togglePin(Map<String, dynamic> note) async {
    final db = _database;
    if (db == null) return;

    HapticFeedback.lightImpact();
    final int id = note['id'] as int;
    final bool currentlyPinned = (note['is_pinned'] as int? ?? 0) == 1;

    await db.update(
      'notes',
      {'is_pinned': currentlyPinned ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadNotes();
  }

  Future<void> _deleteNote(int id) async {
    final db = _database;
    if (db == null) return;

    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    await _loadNotes();
  }

  _NoteCategoryMeta _metaForCategory(String? catKey) {
    final normalized = (catKey == null || catKey.trim().isEmpty) ? 'Genel' : catKey;
    return _categories.firstWhere(
      (c) => c.key == normalized,
      orElse: () => _categories.last,
    );
  }

  List<Map<String, dynamic>> get _filteredNotes {
    return _notes.where((note) {
      final String cat = (note['category']?.toString() ?? '').trim().isEmpty
          ? 'Genel'
          : note['category'].toString();
      if (_selectedCategory != 'Tümü' && cat != _selectedCategory) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final title = (note['title']?.toString() ?? '').toLowerCase();
        final body = (note['text']?.toString() ?? '').toLowerCase();
        return title.contains(q) || body.contains(q) || cat.toLowerCase().contains(q);
      }

      return true;
    }).toList();
  }

  int _countForCategory(String catKey) {
    if (catKey == 'Tümü') return _notes.length;
    return _notes.where((n) {
      final c = (n['category']?.toString() ?? '').trim();
      return (c.isEmpty ? 'Genel' : c) == catKey;
    }).length;
  }

  String _formatNoteDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate);
      const months = [
        'Oca',
        'Şub',
        'Mar',
        'Nis',
        'May',
        'Haz',
        'Tem',
        'Ağu',
        'Eyl',
        'Eki',
        'Kas',
        'Ara',
      ];
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hh:$mm';
    } catch (_) {
      try {
        return DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(rawDate));
      } catch (__) {
        return rawDate;
      }
    }
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotes;
    final int pinnedCount =
        _notes.where((n) => (n['is_pinned'] as int? ?? 0) == 1).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kışla Notlarım',
              style: TextStyle(
                fontSize: 18.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Nöbet, ihtiyaç, devre rehberi ve anı defteri',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        actions: [
          if (_currentSafak > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 14),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wb_sunny_rounded,
                      size: 13,
                      color: Color(0xFF34D399),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Şafak $_currentSafak',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _openNoteEditorSheet(
            initialCategory:
                _selectedCategory == 'Tümü' ? 'Genel' : _selectedCategory,
          );
        },
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 6,
        icon: const Icon(Icons.edit_note_rounded, size: 22),
        label: const Text(
          'Yeni Not Yaz',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Dark-to-Light Hero Dashboard & Search
                _buildTopControlHeader(pinnedCount: pinnedCount),

                // Category Filter Chips
                _buildCategoryFilterBar(),

                // Main Content Area
                Expanded(
                  child: _notes.isEmpty
                      ? _buildRichEmptyOnboarding()
                      : filtered.isEmpty
                          ? _buildFilteredEmptyState()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                              children: [
                                // Quick Templates Horizontal Strip
                                _buildCompactTemplatesStrip(),
                                const SizedBox(height: 12),
                                ...filtered.map(_buildNoteCard),
                              ],
                            ),
                ),
              ],
            ),
    );
  }

  // ============================================================================
  // TOP SUMMARY + SEARCH HEADER
  // ============================================================================
  Widget _buildTopControlHeader({required int pinnedCount}) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Stats Pills Row
          Row(
            children: [
              _buildStatMiniCard(
                icon: Icons.sticky_note_2_outlined,
                label: 'Toplam Not',
                value: '${_notes.length}',
                accent: const Color(0xFF38BDF8),
              ),
              const SizedBox(width: 10),
              _buildStatMiniCard(
                icon: Icons.push_pin_outlined,
                label: 'Sabitlenen',
                value: '$pinnedCount',
                accent: const Color(0xFFFBBF24),
              ),
              const SizedBox(width: 10),
              _buildStatMiniCard(
                icon: Icons.lock_outline_rounded,
                label: 'Gizlilik',
                value: 'Cihazda',
                accent: const Color(0xFF34D399),
              ),
            ],
          ),

          if (_notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Search Input
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _searchQuery.isNotEmpty
                      ? const Color(0xFF38BDF8)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Not başlığı, nöbet saati veya devre adı ara...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12.5,
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF38BDF8),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: accent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // CATEGORY FILTER BAR
  // ============================================================================
  Widget _buildCategoryFilterBar() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final bool isSelected = _selectedCategory == cat.key;
          final int count = _countForCategory(cat.key);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat.key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? cat.color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? cat.color
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cat.color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 15,
                    color: isSelected ? Colors.white : cat.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    count > 0 ? '${cat.label} ($count)' : cat.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
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

  // ============================================================================
  // RICH EMPTY STATE WITH ONE-TAP TEMPLATES (NEVER LOOKS BARE!)
  // ============================================================================
  Widget _buildRichEmptyOnboarding() {
    final templates = _templates;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Welcome Hero Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0EA5E9).withValues(alpha: 0.16),
                        const Color(0xFF6366F1).withValues(alpha: 0.16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 32,
                    color: Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Kişisel Kışla Defterin Hazır',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Buraya yazdığın tüm notlar yalnızca telefonunda saklanır ve otomatik olarak bugünkü şafak sayınla damgalanır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildFeatureHintChip(Icons.push_pin_rounded, 'Önemlileri Sabitle'),
                    _buildFeatureHintChip(Icons.wb_sunny_rounded, 'Otomatik Şafak Damgası'),
                    _buildFeatureHintChip(Icons.wifi_off_rounded, 'İnternetsiz Çalışır'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Start Templates Section Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFD97706)),
                SizedBox(width: 6),
                Text(
                  'HAZIR ŞABLONLA HEMEN BAŞLA',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ' Bir şablona dokunarak taslak dolu şekilde ilk notunu saniyeler içinde oluşturabilirsin:',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2x2 Template Bento Grid
          Row(
            children: [
              Expanded(child: _buildTemplateCard(templates[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildTemplateCard(templates[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTemplateCard(templates[2])),
              const SizedBox(width: 12),
              Expanded(child: _buildTemplateCard(templates[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHintChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF475569)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(_QuickTemplate tpl) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tpl.accent.withValues(alpha: 0.25), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _openNoteEditorSheet(
            initialCategory: tpl.category,
            prefillTitle: tpl.prefillTitle,
            prefillText: tpl.prefillBody,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tpl.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(tpl.icon, size: 19, color: tpl.accent),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: tpl.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tpl.badge,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                        color: tpl.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tpl.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tpl.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Şablonu Aç',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: tpl.accent,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: tpl.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // COMPACT TEMPLATES STRIP (SHOWN ABOVE EXISTING NOTES)
  // ============================================================================
  Widget _buildCompactTemplatesStrip() {
    final templates = _templates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            'HIZLI ŞABLON EKLE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: templates.map((tpl) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: BorderSide(color: tpl.accent.withValues(alpha: 0.28)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openNoteEditorSheet(
                        initialCategory: tpl.category,
                        prefillTitle: tpl.prefillTitle,
                        prefillText: tpl.prefillBody,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tpl.icon, size: 15, color: tpl.accent),
                          const SizedBox(width: 6),
                          Text(
                            '+ ${tpl.title}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // FILTERED EMPTY STATE
  // ============================================================================
  Widget _buildFilteredEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_list_off_rounded,
                size: 34,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Bu filtrede not bulunamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? '"$_searchQuery" aramasıyla eşleşen bir kayıt yok.'
                  : '"$_selectedCategory" kategorisinde henüz bir not eklemediniz.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'Tümü';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Tüm Notları Göster'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // NOTE CARD
  // ============================================================================
  Widget _buildNoteCard(Map<String, dynamic> note) {
    final int id = note['id'] as int;
    final String rawTitle = (note['title']?.toString() ?? '').trim();
    final String rawBody = (note['text']?.toString() ?? '').trim();
    final bool isPinned = (note['is_pinned'] as int? ?? 0) == 1;
    final int? safakDay = note['safak_day'] as int?;
    final _NoteCategoryMeta catMeta = _metaForCategory(note['category']?.toString());

    // Derive display title & body nicely even for legacy v1 notes without title
    String displayTitle = rawTitle;
    String displayBody = rawBody;
    if (displayTitle.isEmpty && rawBody.isNotEmpty) {
      final lines = rawBody.split('\n');
      displayTitle = lines.first.trim();
      displayBody = lines.length > 1 ? lines.sublist(1).join('\n').trim() : '';
    }

    return Dismissible(
      key: ValueKey('note_$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteDialog(),
      onDismissed: (_) {
        _deleteNote(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not silindi.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 6),
            Text(
              'Sil',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isPinned
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.55)
                  : const Color(0xFFE2E8F0),
              width: isPinned ? 1.5 : 1.0,
            ),
          ),
          child: InkWell(
            onTap: () => _openNoteEditorSheet(existingNote: note),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Colored Category Left Strip
                  Container(
                    width: 5,
                    color: catMeta.color,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Badges & Actions Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: catMeta.color.withValues(alpha: 0.11),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(catMeta.icon, size: 12, color: catMeta.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      catMeta.label.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                        color: catMeta.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (safakDay != null && safakDay > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Şafak $safakDay',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              // Pin Button
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _togglePin(note),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    isPinned
                                        ? Icons.push_pin_rounded
                                        : Icons.push_pin_outlined,
                                    size: 18,
                                    color: isPinned
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              // Copy Button
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  final copyContent = rawTitle.isNotEmpty
                                      ? '$rawTitle\n$rawBody'
                                      : rawBody;
                                  Clipboard.setData(ClipboardData(text: copyContent));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Not panoya kopyalandı.'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 9),

                          // Title
                          if (displayTitle.isNotEmpty)
                            Text(
                              displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),

                          // Body Preview
                          if (displayBody.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              displayBody,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.42,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Footer Date & Edit Indicator
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatNoteDate(note['date']?.toString()),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'Düzenle',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 15,
                                color: Color(0xFF0284C7),
                              ),
                            ],
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
      ),
    );
  }

  Future<bool?> _confirmDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Notu Sil?',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        content: const Text(
          'Bu not kalıcı olarak silinecektir. Onaylıyor musunuz?',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MODERN NOTE EDITOR BOTTOM SHEET
  // ============================================================================
  void _openNoteEditorSheet({
    Map<String, dynamic>? existingNote,
    String? initialCategory,
    String? prefillTitle,
    String? prefillText,
  }) {
    final int? noteId = existingNote?['id'] as int?;
    final int? existingSafakDay = existingNote?['safak_day'] as int?;
    final titleCtrl = TextEditingController(
      text: existingNote != null
          ? (existingNote['title']?.toString() ?? '')
          : (prefillTitle ?? ''),
    );
    final bodyCtrl = TextEditingController(
      text: existingNote != null
          ? (existingNote['text']?.toString() ?? '')
          : (prefillText ?? ''),
    );

    String chosenCategory = existingNote != null
        ? ((existingNote['category']?.toString() ?? '').trim().isEmpty
            ? 'Genel'
            : existingNote['category'].toString())
        : (initialCategory ?? 'Genel');
    if (chosenCategory == 'Tümü') chosenCategory = 'Genel';

    bool isPinned =
        existingNote != null && (existingNote['is_pinned'] as int? ?? 0) == 1;

    final editableCategories =
        _categories.where((c) => c.key != 'Tümü').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            final activeCatMeta = _metaForCategory(chosenCategory);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              padding: EdgeInsets.fromLTRB(18, 12, 18, bottomInset + 18),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sheet Header + Pin Toggle
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activeCatMeta.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            activeCatMeta.icon,
                            size: 20,
                            color: activeCatMeta.color,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                noteId == null ? 'Yeni Kışla Notu' : 'Notu Düzenle',
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (_currentSafak > 0 && noteId == null)
                                Text(
                                  'Şafak $_currentSafak olarak damgalanacak',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Pin Chip
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => isPinned = !isPinned);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPinned
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isPinned
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPinned
                                      ? Icons.push_pin_rounded
                                      : Icons.push_pin_outlined,
                                  size: 15,
                                  color: isPinned
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPinned ? 'Sabitlendi' : 'Sabitle',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: isPinned
                                        ? const Color(0xFFD97706)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Category Selector Pills
                    const Text(
                      'KATEGORİ',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: editableCategories.map((cat) {
                          final bool selected = chosenCategory == cat.key;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setSheetState(() => chosenCategory = cat.key);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? cat.color
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? cat.color
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat.icon,
                                      size: 14,
                                      color: selected ? Colors.white : cat.color,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      cat.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFF334155),
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

                    const SizedBox(height: 14),

                    // Title Input
                    TextField(
                      controller: titleCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Not başlığı (Örn: 02-04 Nöbeti, Çarşı Eksikleri)',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: activeCatMeta.color, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Quick Text Insertion Helpers
                    Row(
                      children: [
                        _buildEditorHelperChip(
                          label: '+ Madde (•)',
                          onTap: () {
                            final prefix = bodyCtrl.text.isEmpty ||
                                    bodyCtrl.text.endsWith('\n')
                                ? '• '
                                : '\n• ';
                            bodyCtrl.text = '${bodyCtrl.text}$prefix';
                            bodyCtrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: bodyCtrl.text.length),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildEditorHelperChip(
                          label: '+ Saat Damgası',
                          onTap: () {
                            final now = DateTime.now();
                            final stamp =
                                '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}] ';
                            final prefix = bodyCtrl.text.isEmpty ||
                                    bodyCtrl.text.endsWith('\n')
                                ? stamp
                                : '\n$stamp';
                            bodyCtrl.text = '${bodyCtrl.text}$prefix';
                            bodyCtrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: bodyCtrl.text.length),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Body Input
                    TextField(
                      controller: bodyCtrl,
                      minLines: 6,
                      maxLines: 11,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Not detaylarını, nöbet saatlerini, isimleri veya bugünün kışla anısını buraya yaz...',
                        hintStyle: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: activeCatMeta.color, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons Row
                    Row(
                      children: [
                        if (noteId != null) ...[
                          OutlinedButton.icon(
                            onPressed: () async {
                              final ok = await _confirmDeleteDialog();
                              if (ok == true) {
                                await _deleteNote(noteId);
                                if (sheetCtx.mounted) {
                                  Navigator.of(sheetCtx).pop();
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text(
                              'Sil',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (titleCtrl.text.trim().isEmpty &&
                                  bodyCtrl.text.trim().isEmpty) {
                                Navigator.of(sheetCtx).pop();
                                return;
                              }
                              HapticFeedback.mediumImpact();
                              await _saveNote(
                                id: noteId,
                                title: titleCtrl.text,
                                text: bodyCtrl.text,
                                category: chosenCategory,
                                isPinned: isPinned,
                                existingSafakDay: existingSafakDay,
                              );
                              if (sheetCtx.mounted) {
                                Navigator.of(sheetCtx).pop();
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 19),
                            label: Text(
                              noteId == null ? 'Notu Kaydet' : 'Değişiklikleri Kaydet',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditorHelperChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
