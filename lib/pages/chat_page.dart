import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/Services/millionaire_duel_service.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';

// Alias ForumScreen to ChatScreen for backward compatibility
typedef ForumScreen = ChatScreen;

class ChatScreen extends StatefulWidget {
  final String backgroundImage;
  const ChatScreen({super.key, required this.backgroundImage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  // Mode: 0 -> Canlı Telsiz (Live Chat), 1 -> Karargah Forum (Discussions)
  int _activeMode = 1; // Default to Forum

  // Scope: true -> Genel, false -> Bölge
  bool _isGeneralSelected = true;

  // Forum filters
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _chatInputController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _isLoading = true;

  // User details
  String _userId = '';
  String _name = 'Asker';
  String _surname = '';
  String _rutbe = 'ER';
  String _kuvvetKomutanligi = 'Kara';
  String _askerlikYeri = 'Belirtilmedi';
  bool _eulaAccepted = false;
  List<String> _blockedUserIds = [];

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Tümü', 'icon': Icons.grid_view_rounded, 'color': Color(0xFF64748B)},
    {'name': 'Genel', 'icon': Icons.chat_bubble_outline_rounded, 'color': Color(0xFF2563EB)},
    {'name': 'Tavsiye & Deneyim', 'icon': Icons.lightbulb_outline_rounded, 'color': Color(0xFFD97706)},
    {'name': 'Birlik & Acemi', 'icon': Icons.shield_outlined, 'color': Color(0xFF059669)},
    {'name': 'Şafak & Terhis', 'icon': Icons.hourglass_top_rounded, 'color': Color(0xFFDC2626)},
    {'name': 'Soru - Cevap', 'icon': Icons.help_outline_rounded, 'color': Color(0xFF7C3AED)},
    {'name': 'Malzeme & Çanta', 'icon': Icons.backpack_outlined, 'color': Color(0xFF0D9488)},
  ];

  @override
  void initState() {
    super.initState();
    RevenueCatService.instance.isPremiumNotifier.addListener(_onPremiumStatusChanged);
    _loadUserInfo();
  }

  void _onPremiumStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    RevenueCatService.instance.isPremiumNotifier.removeListener(_onPremiumStatusChanged);
    _searchController.dispose();
    _chatInputController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userId = prefs.getString('userId') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
          _name = prefs.getString('name') ?? 'Asker';
          _surname = prefs.getString('surname') ?? '';
          _rutbe = prefs.getString('rutbe') ?? 'ER';
          _kuvvetKomutanligi = prefs.getString('kuvvet_komutanligi') ?? 'Kara';
          _askerlikYeri = prefs.getString('askerlik_yeri') ?? 'Bilinmiyor';
          _eulaAccepted = prefs.getBool('eulaAccepted') ?? false;
          _blockedUserIds = prefs.getStringList('blockedUsers') ?? [];
          _isLoading = false;
        });
        _ensureInitialTopics();
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _ensureInitialTopics() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('forum_topics').limit(1).get();
      if (snapshot.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        final topicsRef = FirebaseFirestore.instance.collection('forum_topics');

        final doc1 = topicsRef.doc();
        batch.set(doc1, {
          'title': '🇹🇷 Asker Karargahı & Dayanışma Alanına Hoş Geldiniz!',
          'content': 'Değerli silah arkadaşlarımız ve asker yakınları, platformumuza hoş geldiniz!\n\nBurada hem üstteki Canlı Telsiz bölümünden anlık sohbet edebilir, hem de Karargah Forumu üzerinden deneyimlerinizi, sorularınızı ve şafak notlarınızı paylaşabilirsiniz.\n\nSaygılı, kardeşlik ve dayanışma dolu paylaşımlar dileriz. Şafağınız aydınlık olsun!',
          'category': 'Genel',
          'isGeneral': true,
          'location': 'Türkiye Geneli',
          'senderId': 'admin_safak',
          'senderName': 'Şafak Sayar Rehberi',
          'senderRank': 'ASTSUBAY',
          'senderKuvvet': 'Kara',
          'timestamp': FieldValue.serverTimestamp(),
          'likes': ['admin_safak'],
          'likeCount': 1,
          'replyCount': 0,
          'isPinned': true,
          'lastActivity': FieldValue.serverTimestamp(),
        });

        final doc2 = topicsRef.doc();
        batch.set(doc2, {
          'title': '🎒 Acemi Birliği Çantası: Yanınıza Kesinlikle Almanız Gerekenler',
          'content': 'İlk teslim günü yanınızda bulunması gereken en can alıcı malzemeler:\n\n1. Silikon vatka ve tabanlık (bot vurmalarını engeller).\n2. Bol miktarda dikişsiz asker çorabı.\n3. Pudra (ayak ve pişik için vazgeçilmez).\n4. Askercell uyumlu tuşlu telefon.\n5. Boyuna asılan ipli cüzdan ve dolap kilitleri.',
          'category': 'Malzeme & Çanta',
          'isGeneral': true,
          'location': 'Türkiye Geneli',
          'senderId': 'devre_mehmet',
          'senderName': 'Mehmet T.',
          'senderRank': 'ÇAVUŞ',
          'senderKuvvet': 'Kara',
          'timestamp': FieldValue.serverTimestamp(),
          'likes': [],
          'likeCount': 4,
          'replyCount': 0,
          'isPinned': false,
          'lastActivity': FieldValue.serverTimestamp(),
        });

        final doc3 = topicsRef.doc();
        batch.set(doc3, {
          'title': '⏳ Şafak sayarken günler nasıl daha çabuk biter? Taktikleriniz neler?',
          'content': 'Şafak daraldıkça zaman duruyor gibi hissedilen günlerde nöbette veya koğuşta vakti verimli kılan tavsiyelerinizi bekliyoruz devreler!',
          'category': 'Tavsiye & Deneyim',
          'isGeneral': true,
          'location': 'Türkiye Geneli',
          'senderId': 'asker_emre',
          'senderName': 'Emre C.',
          'senderRank': 'ONBAŞI',
          'senderKuvvet': 'Hava',
          'timestamp': FieldValue.serverTimestamp(),
          'likes': [],
          'likeCount': 3,
          'replyCount': 0,
          'isPinned': false,
          'lastActivity': FieldValue.serverTimestamp(),
        });

        await batch.commit();
      }
    } catch (e) {
      debugPrint('Initial topics seed info: $e');
    }
  }

  bool get _isDefaultTheme => widget.backgroundImage == 'assets/images/img0.webp';

  Color _getTextColor() {
    return _isDefaultTheme ? const Color(0xFF0F172A) : Colors.white;
  }

  Color _getSubtitleColor() {
    return _isDefaultTheme ? const Color(0xFF475569) : Colors.white70;
  }

  Color _getLineColor() {
    return _isDefaultTheme
        ? Colors.grey.shade300
        : Colors.white.withValues(alpha: 0.12);
  }

  Color _getSurfaceColor() {
    return _isDefaultTheme
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF0F172A).withValues(alpha: 0.85);
  }

  Color _getKuvvetColor(String kuvvet) {
    switch (kuvvet.trim().toLowerCase()) {
      case 'kara':
        return const Color(0xFF15803D);
      case 'deniz':
        return const Color(0xFF0284C7);
      case 'hava':
        return const Color(0xFF0EA5E9);
      case 'jandarma':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatKuvvet(String kuvvet) {
    switch (kuvvet.trim().toLowerCase()) {
      case 'kara':
        return 'KARA';
      case 'deniz':
        return 'DENİZ';
      case 'hava':
        return 'HAVA';
      case 'jandarma':
        return 'JANDARMA';
      default:
        return kuvvet.toUpperCase();
    }
  }

  String _formatDisplayName(String first, String last) {
    if (last.isEmpty) return first;
    return '$first ${last[0]}.';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} sa';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} g';
    } else {
      return DateFormat('d MMM', 'tr_TR').format(dateTime);
    }
  }

  // Live Chat Send Message
  void _sendLiveChatMessage() async {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    _chatInputController.clear();

    final bool isPrem = RevenueCatService.instance.isPremium;
    final messageData = {
      'senderId': _userId,
      'senderName': _formatDisplayName(_name, _surname),
      'senderRank': _rutbe,
      'senderKuvvet': _kuvvetKomutanligi,
      'isPremium': isPrem,
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
      'location': _askerlikYeri,
    };

    try {
      if (_isGeneralSelected) {
        await FirebaseFirestore.instance.collection('general_chat').add(messageData);
      } else {
        await FirebaseFirestore.instance
            .collection('local_chats')
            .doc(_askerlikYeri)
            .collection('messages')
            .add(messageData);
      }
    } catch (e) {
      debugPrint('Error sending live message: $e');
    }
  }

  void _openCreateTopicModal() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTopicSheet(
        isDefaultTheme: _isDefaultTheme,
        userId: _userId,
        name: _formatDisplayName(_name, _surname),
        rutbe: _rutbe,
        kuvvet: _kuvvetKomutanligi,
        askerlikYeri: _askerlikYeri,
        categories: _categories.where((c) => c['name'] != 'Tümü').toList(),
        initialIsGeneral: _isGeneralSelected,
      ),
    );
  }

  void _toggleTopicLike(String topicId, List<dynamic> likes) async {
    HapticFeedback.lightImpact();
    final bool isLiked = likes.contains(_userId);
    final docRef = FirebaseFirestore.instance.collection('forum_topics').doc(topicId);

    try {
      if (isLiked) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([_userId]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([_userId]),
          'likeCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      );
    }

    final double bottomNavHeight = 68.0 + MediaQuery.of(context).padding.bottom;

    if (!_eulaAccepted) {
      return _buildEulaOverlay(bottomNavHeight);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Tactical Command Header (Dual-Mode & Scope Switcher)
              _buildTacticalHeader(),

              // Body Switcher with Smooth Slide & Fade Transition
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final bool isForum = (child.key as ValueKey<String>?)?.value == 'forum_view';
                    final Offset beginOffset = isForum
                        ? const Offset(0.08, 0)
                        : const Offset(-0.08, 0);

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: beginOffset,
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _activeMode == 0
                      ? KeyedSubtree(
                          key: const ValueKey<String>('live_chat_view'),
                          child: _buildLiveChatView(bottomNavHeight),
                        )
                      : KeyedSubtree(
                          key: const ValueKey<String>('forum_view'),
                          child: _buildForumTimelineView(bottomNavHeight),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP TACTICAL COMMAND HEADER (Clean Modern Glass, NOT a Card)
  // -------------------------------------------------------------
  Widget _buildTacticalHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      decoration: BoxDecoration(
        color: _getSurfaceColor(),
        border: Border(bottom: BorderSide(color: _getLineColor(), width: 1)),
      ),
      child: Column(
        children: [
          // Row 1: Dual Mode Pill: [ 📻 Canlı Telsiz | 📑 Karargah Forum ]
          Container(
            height: 42,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _isDefaultTheme ? Colors.grey.shade200 : Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                // Live Chat Option
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_activeMode != 0) {
                        HapticFeedback.selectionClick();
                        setState(() => _activeMode = 0);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _activeMode == 0
                            ? (_isDefaultTheme ? Colors.white : const Color(0xFF1E293B))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _activeMode == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sensors_rounded,
                            size: 16,
                            color: _activeMode == 0 ? Colors.greenAccent.shade700 : _getSubtitleColor(),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Canlı Telsiz',
                            style: TextStyle(
                              color: _activeMode == 0 ? _getTextColor() : _getSubtitleColor(),
                              fontWeight: _activeMode == 0 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Forum Topics Option
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_activeMode != 1) {
                        HapticFeedback.selectionClick();
                        setState(() => _activeMode = 1);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _activeMode == 1
                            ? (_isDefaultTheme ? Colors.white : const Color(0xFF1E293B))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _activeMode == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 16,
                            color: _activeMode == 1 ? const Color(0xFF2563EB) : _getSubtitleColor(),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Karargah Forum',
                            style: TextStyle(
                              color: _activeMode == 1 ? _getTextColor() : _getSubtitleColor(),
                              fontWeight: _activeMode == 1 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 11.5,
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

          const SizedBox(height: 8),

          // Row 2: Scope Selector (Genel vs Bölge) & Live Frequency Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Scope Segmented Chips
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!_isGeneralSelected) {
                        HapticFeedback.lightImpact();
                        setState(() => _isGeneralSelected = true);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isGeneralSelected
                            ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isGeneralSelected ? const Color(0xFF2563EB) : _getLineColor(),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇹🇷', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            'Türkiye Geneli',
                            style: TextStyle(
                              color: _isGeneralSelected ? const Color(0xFF2563EB) : _getSubtitleColor(),
                              fontSize: 10,
                              fontWeight: _isGeneralSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      if (_isGeneralSelected) {
                        HapticFeedback.lightImpact();
                        setState(() => _isGeneralSelected = false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: !_isGeneralSelected
                            ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isGeneralSelected ? const Color(0xFF2563EB) : _getLineColor(),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: !_isGeneralSelected ? const Color(0xFF2563EB) : _getSubtitleColor(),
                          ),
                          const SizedBox(width: 3),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              _askerlikYeri.isEmpty || _askerlikYeri == 'Bilinmiyor'
                                  ? 'Bölgem'
                                  : _askerlikYeri,
                              style: TextStyle(
                                color: !_isGeneralSelected ? const Color(0xFF2563EB) : _getSubtitleColor(),
                                fontSize: 10,
                                fontWeight: !_isGeneralSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // VIP Badge & Frequency Status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: RevenueCatService.instance.isPremiumNotifier,
                    builder: (context, isPrem, _) {
                      return GestureDetector(
                        onTap: () {
                          if (!isPrem) {
                            HapticFeedback.lightImpact();
                            PremiumPaywallPage.show(context, source: 'chat_header_badge');
                          }
                        },
                        onLongPress: () async {
                          HapticFeedback.heavyImpact();
                          final nextState = !isPrem;
                          await RevenueCatService.instance.setPremiumManually(nextState);
                          await MillionaireDuelService.instance.syncPremiumStatus();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      nextState ? Icons.workspace_premium_rounded : Icons.info_outline_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(nextState
                                        ? '🎖️ VIP Asker Modu AÇILDI (Test)'
                                        : 'VIP Modu KAPATILDI (Test)'),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: nextState ? const Color(0xFFD97706) : Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: isPrem
                                ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                                : null,
                            color: isPrem ? null : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withValues(alpha: isPrem ? 0.9 : 0.45),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPrem ? Icons.workspace_premium_rounded : Icons.star_rounded,
                                size: 11,
                                color: isPrem ? Colors.white : const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isPrem ? 'VIP ASKER' : 'PRO',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: isPrem ? Colors.white : const Color(0xFFF59E0B),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _activeMode == 0 ? 'CANLI TELSİZ' : 'DİVAN AKTİF',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // VIEW 1: CANLI TELSİZ (Live Chat Stream without boxy cards)
  // -------------------------------------------------------------
  Widget _buildLiveChatView(double bottomNavHeight) {
    final Stream<QuerySnapshot> liveChatStream = _isGeneralSelected
        ? FirebaseFirestore.instance
            .collection('general_chat')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots()
        : FirebaseFirestore.instance
            .collection('local_chats')
            .doc(_askerlikYeri)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots();

    return Column(
      children: [
        // Live Chat Messages River
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: liveChatStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data?.docs ?? [];
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String senderId = data['senderId'] ?? '';
                return !_blockedUserIds.contains(senderId);
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sensors_off_rounded, size: 48, color: _getSubtitleColor().withValues(alpha: 0.4)),
                      const SizedBox(height: 10),
                      Text(
                        'Telsizde Henüz Ses Yok',
                        style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aşağıdan ilk telsiz mesajını sen bırak!',
                        style: TextStyle(color: _getSubtitleColor(), fontSize: 11.5),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                controller: _chatScrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return _buildLiveMessageItem(doc);
                },
              );
            },
          ),
        ),

        // Live Chat Input Bar
        _buildLiveChatInputBar(bottomNavHeight),
      ],
    );
  }

  // Fluid message line (Discord/Telegram style, NOT a big box card)
  Widget _buildLiveMessageItem(QueryDocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final String senderId = data['senderId'] ?? '';
    final String senderName = data['senderName'] ?? 'Asker';
    final String senderRank = data['senderRank'] ?? 'ER';
    final String senderKuvvet = data['senderKuvvet'] ?? 'Kara';
    final String messageText = data['message'] ?? '';
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
    final DateTime messageDate = timestamp != null ? timestamp.toDate() : DateTime.now();

    final bool isMe = senderId == _userId;
    final bool isSenderPremium = (data['isPremium'] == true) || (isMe && RevenueCatService.instance.isPremium);
    final Color badgeColor = _getKuvvetColor(senderKuvvet);

    return GestureDetector(
      onLongPress: () {
        _showReportBlockSheet(
          targetType: 'chat_message',
          contentId: doc.id,
          senderId: senderId,
          senderName: senderName,
          text: messageText,
          isMe: isMe,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSenderPremium
              ? const Color(0xFFF59E0B).withValues(alpha: isMe ? 0.16 : 0.08)
              : (isMe
                  ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                  : _getSurfaceColor()),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: isSenderPremium
                  ? const Color(0xFFF59E0B)
                  : (isMe ? const Color(0xFF2563EB) : badgeColor),
              width: isSenderPremium ? 4.0 : 3.5,
            ),
          ),
          boxShadow: isSenderPremium
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.09),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender line
            Row(
              children: [
                // VIP ASKER Künye Brövesi
                if (isSenderPremium) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 8.5),
                        SizedBox(width: 2),
                        Text(
                          'VIP ASKER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getTextColor().withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    senderRank.toUpperCase(),
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatKuvvet(senderKuvvet),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isMe ? 'Sen' : senderName,
                    style: TextStyle(
                      color: isSenderPremium ? const Color(0xFFFBBF24) : _getTextColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTimeAgo(messageDate),
                  style: TextStyle(color: _getSubtitleColor(), fontSize: 9),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Message Content
            SelectableText(
              messageText,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveChatInputBar(double bottomNavHeight) {
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardInset > 0;
    final double safeBottom = MediaQuery.of(context).padding.bottom;

    // Calculate a snug, ergonomic bottom padding so the input bar sits right above the bottom nav bar
    final double bottomPadding = isKeyboardOpen
        ? 10.0
        : (safeBottom > 0 ? (bottomNavHeight - 30.0) : (bottomNavHeight - 18.0));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 8,
        bottom: bottomPadding,
      ),
      decoration: BoxDecoration(
        color: _getSurfaceColor(),
        border: Border(top: BorderSide(color: _getLineColor(), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _isDefaultTheme ? Colors.grey.shade100 : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _getLineColor()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _chatInputController,
                  maxLength: 400,
                  style: TextStyle(color: _getTextColor(), fontSize: 12),
                  decoration: InputDecoration(
                    hintText: _isGeneralSelected
                        ? 'Telsizden genel mesaj bırak...'
                        : '$_askerlikYeri telsizine yaz...',
                    hintStyle: TextStyle(
                      color: _getSubtitleColor().withValues(alpha: 0.6),
                      fontSize: 11.5,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendLiveChatMessage,
            child: Container(
              height: 42,
              width: 42,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 19),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumTimelineView(double bottomNavHeight) {
    return Column(
      children: [
        // Category Pills (Minimal Underline Bar)
        _buildCategoryPillsBar(),

        // Search Bar with Integrated Action
        _buildForumSearchBar(),

        // Interactive Composer Prompt
        _buildQuickPostPrompt(),

        // Timeline Feed Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('forum_topics').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data?.docs ?? [];

              // Filter Scope
              var filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final bool isDocGeneral = data['isGeneral'] ?? true;
                if (_isGeneralSelected) {
                  return isDocGeneral;
                } else {
                  if (isDocGeneral) return false;
                  if (_askerlikYeri.isNotEmpty && _askerlikYeri != 'Bilinmiyor') {
                    final loc = (data['location'] ?? '').toString().trim().toLowerCase();
                    final myLoc = _askerlikYeri.trim().toLowerCase();
                    if (loc.isNotEmpty && loc != myLoc) return false;
                  }
                  return true;
                }
              }).toList();

              // Filter Blocked Users
              filteredDocs = filteredDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String senderId = data['senderId'] ?? '';
                return !_blockedUserIds.contains(senderId);
              }).toList();

              // Filter Category
              if (_selectedCategory != 'Tümü') {
                filteredDocs = filteredDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['category'] ?? '') == _selectedCategory;
                }).toList();
              }

              // Filter Search Query
              if (_searchQuery.trim().isNotEmpty) {
                final queryLower = _searchQuery.toLowerCase().trim();
                filteredDocs = filteredDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final content = (data['content'] ?? '').toString().toLowerCase();
                  final author = (data['senderName'] ?? '').toString().toLowerCase();
                  return title.contains(queryLower) ||
                      content.contains(queryLower) ||
                      author.contains(queryLower);
                }).toList();
              }

              // In-Memory Sorting (Pinned first, then Newest)
              filteredDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;

                final aPinned = aData['isPinned'] == true;
                final bPinned = bData['isPinned'] == true;
                if (aPinned && !bPinned) return -1;
                if (!aPinned && bPinned) return 1;

                final aTs = aData['timestamp'] as Timestamp?;
                final bTs = bData['timestamp'] as Timestamp?;
                if (aTs == null && bTs == null) return 0;
                if (aTs == null) return 1;
                if (bTs == null) return -1;
                return bTs.compareTo(aTs);
              });

              if (filteredDocs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(28.0, 28.0, 28.0, bottomNavHeight + 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.feed_outlined, size: 52, color: _getSubtitleColor().withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          'Bu Kategoride Konu Yok',
                          style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'İlk başlığı açarak diğer silah arkadaşlarınla tartışma başlatabilirsin!',
                          style: TextStyle(color: _getSubtitleColor(), fontSize: 11.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openCreateTopicModal,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('İlk Konuyu Sen Başlat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 8, 16, bottomNavHeight + 70),
                physics: const BouncingScrollPhysics(),
                itemCount: filteredDocs.length,
                separatorBuilder: (context, index) => Divider(
                  color: _getLineColor(),
                  height: 24,
                  thickness: 0.8,
                ),
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  return _buildTimelineTopicItem(doc);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPillsBar() {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final String catName = cat['name'];
          final IconData catIcon = cat['icon'];
          final Color catColor = cat['color'];
          final bool isSelected = _selectedCategory == catName;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedCategory = catName);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? catColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? catColor : _getLineColor(),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(catIcon, size: 12, color: isSelected ? Colors.white : catColor),
                    const SizedBox(width: 4),
                    Text(
                      catName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : _getTextColor(),
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForumSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: _isDefaultTheme ? Colors.grey.shade100 : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getLineColor()),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Icon(Icons.search_rounded, size: 16, color: _getSubtitleColor()),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: _getTextColor(), fontSize: 11.5),
                      decoration: InputDecoration(
                        hintText: 'Başlıklarda ara...',
                        hintStyle: TextStyle(
                          color: _getSubtitleColor().withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 15),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Integrated "Konu Aç" Button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openCreateTopicModal,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Konu Aç',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Quick Dispatch Composer (Twitter/Reddit style prompt)
  Widget _buildQuickPostPrompt() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openCreateTopicModal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _isDefaultTheme
                ? Colors.grey.shade50
                : const Color(0xFF1E293B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _getLineColor(), width: 0.9),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _getKuvvetColor(_kuvvetKomutanligi),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _name.isNotEmpty ? _name[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aklında bir soru veya askerlik tecrübesi mi var? Paylaş...',
                  style: TextStyle(
                    color: _getSubtitleColor().withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TIMELINE MAGAZINE ITEM (Zero card view - Typography & Timeline stream)
  // -------------------------------------------------------------
  Widget _buildTimelineTopicItem(QueryDocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final String topicId = doc.id;
    final String title = data['title'] ?? 'Başlıksız';
    final String content = data['content'] ?? '';
    final String category = data['category'] ?? 'Genel';
    final String senderId = data['senderId'] ?? '';
    final String senderName = data['senderName'] ?? 'Asker';
    final String senderRank = data['senderRank'] ?? 'ER';
    final String senderKuvvet = data['senderKuvvet'] ?? 'Kara';
    final String location = data['location'] ?? '';
    final bool isPinned = data['isPinned'] ?? false;
    final List<dynamic> likes = data['likes'] ?? [];
    final int likeCount = data['likeCount'] ?? likes.length;
    final int replyCount = data['replyCount'] ?? 0;
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
    final DateTime createdAt = timestamp != null ? timestamp.toDate() : DateTime.now();

    final bool isMe = senderId == _userId;
    final bool isLiked = likes.contains(_userId);
    final bool isAuthorPremium = (data['isPremium'] == true) || (isMe && RevenueCatService.instance.isPremium);
    final Color badgeColor = _getKuvvetColor(senderKuvvet);

    // Find category info
    final catItem = _categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => {'color': const Color(0xFF2563EB), 'icon': Icons.chat_bubble_outline_rounded},
    );
    final Color catColor = catItem['color'] as Color;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ForumDetailScreen(
              topicId: topicId,
              topicData: data,
              isDefaultTheme: _isDefaultTheme,
              userId: _userId,
              userName: _formatDisplayName(_name, _surname),
              userRank: _rutbe,
              userKuvvet: _kuvvetKomutanligi,
              onReport: (id, name, text) => _reportContent(
                targetType: 'forum_topic',
                contentId: id,
                senderId: senderId,
                senderName: name,
                contentText: text,
              ),
              onBlock: (sId, name) => _blockUser(sId, name, topicId, title),
              onDelete: () => _deleteTopic(topicId),
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Tactical Timeline Indicator Node
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isPinned ? Colors.amber.shade600 : catColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPinned ? Colors.amber.shade700 : catColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isPinned ? Icons.push_pin_rounded : catItem['icon'] as IconData,
                  size: 15,
                  color: isPinned ? Colors.white : catColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Main Magazine Article Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Time & Pinned line
                Row(
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        color: catColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('•', style: TextStyle(color: _getSubtitleColor(), fontSize: 9.5)),
                    const SizedBox(width: 5),
                    Text(
                      _formatTimeAgo(createdAt),
                      style: TextStyle(color: _getSubtitleColor(), fontSize: 9.5),
                    ),
                    if (isPinned) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SABİT',
                          style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: _getTextColor(),
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),

                // Excerpt preview
                Text(
                  content,
                  style: TextStyle(
                    color: _getSubtitleColor(),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),

                // Inline Author & Interaction Footprint
                Row(
                  children: [
                    // Author pill with flexible text
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAuthorPremium) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  margin: const EdgeInsets.only(right: 3),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'VIP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                              Text(
                                senderRank.toUpperCase(),
                                style: TextStyle(
                                  color: badgeColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  isMe ? 'Sen' : senderName,
                                  style: TextStyle(
                                    color: isAuthorPremium ? const Color(0xFFFBBF24) : _getTextColor(),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (location.isNotEmpty && location != 'Belirtilmedi') ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '• $location',
                                    style: TextStyle(color: _getSubtitleColor(), fontSize: 9),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Replies count
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.comment_outlined, size: 13, color: _getSubtitleColor()),
                        const SizedBox(width: 3),
                        Text(
                          '$replyCount',
                          style: TextStyle(
                            color: _getSubtitleColor(),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Like button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _toggleTopicLike(topicId, likes),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 13,
                            color: isLiked ? Colors.redAccent : _getSubtitleColor(),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$likeCount',
                            style: TextStyle(
                              color: isLiked ? Colors.redAccent : _getSubtitleColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text('Bağlantı Hatası', style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(error, style: TextStyle(color: _getSubtitleColor(), fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showReportBlockSheet({
    required String targetType,
    required String contentId,
    required String senderId,
    required String senderName,
    required String text,
    required bool isMe,
  }) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Material(
        color: _isDefaultTheme ? Colors.white : const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  isMe ? 'Kendi Mesajınız' : '$senderName Kullanıcısı',
                  style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: _getLineColor()),
              if (!isMe) ...[
                ListTile(
                  leading: const Icon(Icons.flag_rounded, color: Colors.amber),
                  title: Text('Şikayet Et', style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _reportContent(
                      targetType: targetType,
                      contentId: contentId,
                      senderId: senderId,
                      senderName: senderName,
                      contentText: text,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
                  title: Text('Kullanıcıyı Engelle', style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _blockUser(senderId, senderName, contentId, text);
                  },
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Kendi mesajınız için işlem yapılamaz.', style: TextStyle(color: _getSubtitleColor(), fontSize: 13)),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteTopic(String topicId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDefaultTheme ? Colors.white : const Color(0xFF1E293B),
        title: Text('Konuyu Sil?', style: TextStyle(color: _getTextColor())),
        content: Text('Bu konu kalıcı olarak kaldırılacaktır.', style: TextStyle(color: _getSubtitleColor())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await FirebaseFirestore.instance.collection('forum_topics').doc(topicId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konu silindi.')));
      }
    } catch (e) {
      debugPrint('Error deleting topic: $e');
    }
  }

  void _reportContent({
    required String targetType,
    required String contentId,
    required String senderId,
    required String senderName,
    required String contentText,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'type': targetType,
        'reportedContentId': contentId,
        'reportedSenderId': senderId,
        'reportedSenderName': senderName,
        'reportedContentText': contentText,
        'reporterUserId': _userId,
        'reporterUserName': _formatDisplayName(_name, _surname),
        'timestamp': FieldValue.serverTimestamp(),
        'actionTaken': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şikayetiniz iletildi. 24 saatte incelenecektir.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error reporting content: $e');
    }
  }

  void _blockUser(String senderId, String senderName, String relatedId, String relatedText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentBlocks = prefs.getStringList('blockedUsers') ?? [];
      if (!currentBlocks.contains(senderId)) {
        currentBlocks.add(senderId);
        await prefs.setStringList('blockedUsers', currentBlocks);
      }

      setState(() => _blockedUserIds = currentBlocks);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$senderName engellendi ve içerikleri gizlendi.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }

  Widget _buildEulaOverlay(double bottomNavHeight) {
    return Container(
      color: _isDefaultTheme ? Colors.white : const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const Icon(Icons.gavel_rounded, size: 54, color: Color(0xFF2563EB)),
                    const SizedBox(height: 16),
                    Text(
                      'Asker Topluluğu Sözleşmesi (EULA)',
                      style: TextStyle(color: _getTextColor(), fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Telsiz ve Forum alanlarını kullanırken küfür, hakaret, nefret söylemi, askeri gizlilik içeren operasyonel bilgi paylaşımı KESİNLİKLE YASAKTIR.\n\nKurallara uymayan kullanıcılar 24 saat içinde sistemden kalıcı olarak uzaklaştırılır.',
                      style: TextStyle(color: _getTextColor(), fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, bottomNavHeight + 16),
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('eulaAccepted', true);
                  setState(() => _eulaAccepted = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Okudum, Kabul Ediyorum', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// NEW TOPIC SHEET
// -------------------------------------------------------------
class CreateTopicSheet extends StatefulWidget {
  final bool isDefaultTheme;
  final String userId;
  final String name;
  final String rutbe;
  final String kuvvet;
  final String askerlikYeri;
  final List<Map<String, dynamic>> categories;
  final bool initialIsGeneral;

  const CreateTopicSheet({
    super.key,
    required this.isDefaultTheme,
    required this.userId,
    required this.name,
    required this.rutbe,
    required this.kuvvet,
    required this.askerlikYeri,
    required this.categories,
    required this.initialIsGeneral,
  });

  @override
  State<CreateTopicSheet> createState() => _CreateTopicSheetState();
}

class _CreateTopicSheetState extends State<CreateTopicSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // 0 -> Düzenle, 1 -> Önizleme
  int _activeTab = 0;

  late bool _isGeneral;
  late String _selectedCategory;
  bool _isPublishing = false;
  bool _showGuidelines = false;

  @override
  void initState() {
    super.initState();
    _isGeneral = widget.initialIsGeneral;
    _selectedCategory = widget.categories.isNotEmpty ? widget.categories[0]['name'] : 'Genel';
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _canPublish =>
      _titleController.text.trim().isNotEmpty &&
      _contentController.text.trim().isNotEmpty &&
      !_isPublishing;

  Color _getTextColor() {
    return widget.isDefaultTheme ? const Color(0xFF0F172A) : Colors.white;
  }

  Color _getSubtitleColor() {
    return widget.isDefaultTheme ? const Color(0xFF64748B) : Colors.white70;
  }

  Color _getLineColor() {
    return widget.isDefaultTheme ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.1);
  }

  Color _getSurfaceColor() {
    return widget.isDefaultTheme ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
  }

  Color _getCardColor() {
    return widget.isDefaultTheme ? Colors.white : const Color(0xFF151F32);
  }

  Color _getKuvvetColor(String kuvvet) {
    switch (kuvvet.trim().toLowerCase()) {
      case 'kara':
        return const Color(0xFF15803D);
      case 'deniz':
        return const Color(0xFF0284C7);
      case 'hava':
        return const Color(0xFF0EA5E9);
      case 'jandarma':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _onCancel() async {
    if (_titleController.text.trim().isNotEmpty || _contentController.text.trim().isNotEmpty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: widget.isDefaultTheme ? Colors.white : const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Text(
                'Taslağı Sil?',
                style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            'Yazdığınız konu taslağı kaydedilmeyecektir. Çıkmak istediğinizden emin misiniz?',
            style: TextStyle(color: _getSubtitleColor(), fontSize: 13.5, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Yazmaya Devam Et', style: TextStyle(color: Colors.blueAccent.shade700, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil ve Çık', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ) ?? false;

      if (!discard) return;
    }
    if (mounted) Navigator.pop(context);
  }

  void _insertFormatting(String prefix, [String suffix = '']) {
    HapticFeedback.lightImpact();
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (!selection.isValid) {
      final newText = text.isEmpty ? '$prefix$suffix' : '$text\n$prefix$suffix';
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }
    final newText = text.replaceRange(selection.start, selection.end, '$prefix${selection.textInside(text)}$suffix');
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + prefix.length + (selection.end - selection.start)),
    );
  }

  void _applyTemplate(String titlePrefix, String contentTemplate, String category) {
    HapticFeedback.mediumImpact();
    if (_titleController.text.trim().isEmpty) {
      _titleController.text = titlePrefix;
    }
    if (_contentController.text.trim().isEmpty) {
      _contentController.text = contentTemplate;
    }
    if (widget.categories.any((c) => c['name'] == category)) {
      _selectedCategory = category;
    }
    setState(() {});
  }

  void _publishTopic() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() => _isPublishing = true);

    try {
      await FirebaseFirestore.instance.collection('forum_topics').add({
        'title': title,
        'content': content,
        'category': _selectedCategory,
        'isGeneral': _isGeneral,
        'location': widget.askerlikYeri,
        'senderId': widget.userId,
        'senderName': widget.name,
        'senderRank': widget.rutbe,
        'senderKuvvet': widget.kuvvet,
        'isPremium': RevenueCatService.instance.isPremium,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'likeCount': 0,
        'replyCount': 0,
        'isPinned': false,
        'lastActivity': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Konunuz Karargah Forumunda yayınlandı!')),
              ],
            ),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error publishing topic: $e');
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konu yayınlanamadı: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color sheetBg = widget.isDefaultTheme ? Colors.white : const Color(0xFF0B132B);
    final Color badgeColor = _getKuvvetColor(widget.kuvvet);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Find current category metadata
    final currentCat = widget.categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => {
        'name': _selectedCategory,
        'color': const Color(0xFF2563EB),
        'icon': Icons.chat_bubble_outline_rounded,
      },
    );
    final Color catColor = currentCat['color'] as Color;
    final IconData catIcon = currentCat['icon'] as IconData;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Top Drag Handle Bar
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: widget.isDefaultTheme ? Colors.grey.shade300 : Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 1. Pro Command Bar (Cancel | Segmented Tabs | Publish)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                child: Row(
                  children: [
                    // Close / Discard Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _onCancel,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _getSurfaceColor(),
                            shape: BoxShape.circle,
                            border: Border.all(color: _getLineColor(), width: 0.8),
                          ),
                          child: Icon(Icons.close_rounded, size: 18, color: _getSubtitleColor()),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Center Dual Tab: [ ✍️ Düzenle ] [ 👁️ Önizle ]
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: _getSurfaceColor(),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getLineColor(), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _activeTab = 0);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 0
                                        ? (widget.isDefaultTheme ? Colors.white : const Color(0xFF2563EB))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _activeTab == 0
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        size: 15,
                                        color: _activeTab == 0
                                            ? (widget.isDefaultTheme ? const Color(0xFF2563EB) : Colors.white)
                                            : _getSubtitleColor(),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Yaz',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _activeTab == 0
                                              ? (widget.isDefaultTheme ? const Color(0xFF0F172A) : Colors.white)
                                              : _getSubtitleColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  FocusScope.of(context).unfocus();
                                  setState(() => _activeTab = 1);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 1
                                        ? (widget.isDefaultTheme ? Colors.white : const Color(0xFF2563EB))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _activeTab == 1
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.remove_red_eye_rounded,
                                        size: 14,
                                        color: _activeTab == 1
                                            ? (widget.isDefaultTheme ? const Color(0xFF2563EB) : Colors.white)
                                            : _getSubtitleColor(),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Önizle',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _activeTab == 1
                                              ? (widget.isDefaultTheme ? const Color(0xFF0F172A) : Colors.white)
                                              : _getSubtitleColor(),
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
                    ),

                    const SizedBox(width: 12),

                    // Modern Gradient Publish Action Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: _canPublish
                            ? const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: _canPublish ? null : (widget.isDefaultTheme ? Colors.grey.shade200 : Colors.white12),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _canPublish
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _canPublish ? _publishTopic : null,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: _isPublishing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.send_rounded,
                                        size: 13,
                                        color: _canPublish ? Colors.white : _getSubtitleColor().withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Paylaş',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: _canPublish ? Colors.white : _getSubtitleColor().withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: _getLineColor(), height: 1),

              // 2. Author Credential & Audience Scope Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: _getSurfaceColor().withValues(alpha: 0.45),
                child: Row(
                  children: [
                    // Author Military Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [badgeColor, badgeColor.withValues(alpha: 0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Author Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 0.8),
                                ),
                                child: Text(
                                  widget.rutbe.toUpperCase(),
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.name,
                                  style: TextStyle(
                                    color: _getTextColor(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isGeneral
                                ? 'Hedef Kitle: Türkiye Geneli Tüm Birlikler'
                                : 'Hedef Kitle: ${widget.askerlikYeri} Birliği',
                            style: TextStyle(
                              color: _getSubtitleColor(),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Scope Pill Switcher (Genel vs Bölge)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isGeneral = !_isGeneral);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isGeneral
                              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                              : const Color(0xFF059669).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isGeneral ? const Color(0xFF2563EB) : const Color(0xFF059669),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_isGeneral ? '🇹🇷' : '📍', style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 100),
                              child: Text(
                                _isGeneral
                                    ? 'Genel'
                                    : (widget.askerlikYeri.isNotEmpty ? widget.askerlikYeri : 'Bölgem'),
                                style: TextStyle(
                                  color: _isGeneral ? const Color(0xFF2563EB) : const Color(0xFF059669),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.sync_rounded,
                              size: 12,
                              color: _isGeneral ? const Color(0xFF2563EB) : const Color(0xFF059669),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: _getLineColor(), height: 1),

              // 3. Category Horizontal Selection Ribbon
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: widget.categories.length,
                  itemBuilder: (context, index) {
                    final cat = widget.categories[index];
                    final String name = cat['name'];
                    final Color color = cat['color'] as Color;
                    final IconData icon = cat['icon'] as IconData;
                    final bool isSelected = _selectedCategory == name;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = name);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [color, color.withValues(alpha: 0.85)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : _getSurfaceColor(),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? color : _getLineColor(),
                              width: isSelected ? 1.4 : 0.8,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 13, color: isSelected ? Colors.white : color),
                              const SizedBox(width: 5),
                              Text(
                                name,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : _getTextColor(),
                                  fontSize: 10.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Divider(color: _getLineColor(), height: 1),

              // 4. Main Body: Switch between [0: Düzenle (Editor)] and [1: Önizle (Preview)]
              Expanded(
                child: _activeTab == 0 ? _buildEditorView(catColor, catIcon) : _buildPreviewView(catColor, catIcon),
              ),

              // 5. Contextual Quick Bar (Formatting Toolbar in Edit mode, or Info bar in Preview mode)
              _buildBottomContextBar(catColor),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // EDITOR VIEW
  // -----------------------------------------------------------
  Widget _buildEditorView(Color catColor, IconData catIcon) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Templates Starter Strip (shown when inputs are empty or upon request)
          if (_titleController.text.isEmpty && _contentController.text.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: _getSurfaceColor(),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _getLineColor(), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(
                        'Hızlı Konu Başlatıcı',
                        style: TextStyle(
                          color: _getTextColor(),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildQuickPromptChip(
                        icon: Icons.help_outline_rounded,
                        label: 'Soru Sor',
                        color: const Color(0xFF7C3AED),
                        onTap: () => _applyTemplate(
                          '[Soru] ',
                          'Merak ettiğim konu:\n\nDetaylar:\n\nTecrübeli silah arkadaşlarımdan bilgi bekliyorum.',
                          'Soru - Cevap',
                        ),
                      ),
                      _buildQuickPromptChip(
                        icon: Icons.backpack_outlined,
                        label: 'Malzeme Listesi',
                        color: const Color(0xFF0D9488),
                        onTap: () => _applyTemplate(
                          '[Tavsiye] Asker çantasında mutlaka bulunması gerekenler',
                          'Deneyimlerime göre giderken yanınıza almanız gereken temel eşyalar:\n\n• \n• \n• \n\nBirlikte temin edilebilecekler:',
                          'Malzeme & Çanta',
                        ),
                      ),
                      _buildQuickPromptChip(
                        icon: Icons.shield_outlined,
                        label: 'Birlik Tavsiyesi',
                        color: const Color(0xFF059669),
                        onTap: () => _applyTemplate(
                          '[Deneyim] Birlik için önemli tavsiyeler',
                          'Burada görev yapacak silah arkadaşlarıma tavsiyelerim:\n\n1. Koğuş ve içtima düzeni:\n2. İklim ve hava şartları:\n3. Ulaşım ve çarşı izni:',
                          'Birlik & Acemi',
                        ),
                      ),
                      _buildQuickPromptChip(
                        icon: Icons.hourglass_top_rounded,
                        label: 'Şafak Muhabbeti',
                        color: const Color(0xFFDC2626),
                        onTap: () => _applyTemplate(
                          'Şafak sayanlar burada mı? Durumlar nasıl?',
                          'Şafağımız kaç kaldı tertipler? Günler nasıl geçiyor, terhis hazırlıkları başladı mı?',
                          'Şafak & Terhis',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Title Input Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KONU BAŞLIĞI',
                style: TextStyle(
                  color: _getSubtitleColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${_titleController.text.length}/100',
                style: TextStyle(
                  color: _titleController.text.length > 90 ? Colors.redAccent : _getSubtitleColor(),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Title Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: _getSurfaceColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _titleController.text.trim().isNotEmpty
                    ? const Color(0xFF2563EB).withValues(alpha: 0.4)
                    : _getLineColor(),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _titleController,
              maxLength: 100,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
              decoration: InputDecoration(
                hintText: 'Örn: Acemi birliğinde ilk gün neler yaşanır?',
                hintStyle: TextStyle(
                  color: _getSubtitleColor().withValues(alpha: 0.45),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Content Input Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KONU İÇERİĞİ VE DETAYLAR',
                style: TextStyle(
                  color: _getSubtitleColor(),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${_contentController.text.length}/2000',
                style: TextStyle(
                  color: _contentController.text.length > 1850 ? Colors.redAccent : _getSubtitleColor(),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Content Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _getSurfaceColor(),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _contentController.text.trim().isNotEmpty
                    ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                    : _getLineColor(),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 7,
              maxLength: 2000,
              style: TextStyle(
                color: _getTextColor().withValues(alpha: 0.95),
                fontSize: 12.5,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'Düşüncelerini, tavsiyelerini veya sormak istediğin soruyu detaylıca paylaş...\n\nSilah arkadaşlarına ışık tutacak tecrübeler her zaman kıymetlidir.',
                hintStyle: TextStyle(
                  color: _getSubtitleColor().withValues(alpha: 0.45),
                  fontSize: 12,
                  height: 1.45,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Collapsible Karargah Guidelines Card
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showGuidelines = !_showGuidelines);
            },
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: widget.isDefaultTheme ? Colors.blue.shade50.withValues(alpha: 0.6) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 15, color: Color(0xFF2563EB)),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Karargah Paylaşım İlkeleri',
                          style: TextStyle(
                            color: _getTextColor(),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        _showGuidelines ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 16,
                        color: _getSubtitleColor(),
                      ),
                    ],
                  ),
                  if (_showGuidelines) ...[
                    const SizedBox(height: 6),
                    Text(
                      '• Gizli askeri bilgi, operasyon, nöbet noktası veya komutan isimleri paylaşmayınız.\n• Birlik ve beraberlik ruhuna uygun, saygılı bir dil benimseyiniz.\n• Ticari ilan, link veya uygunsuz içerik barındıran paylaşımlar kaldırılır.',
                      style: TextStyle(
                        color: _getSubtitleColor(),
                        fontSize: 10,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  // Quick Prompt Chip for Starters
  Widget _buildQuickPromptChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------
  // LIVE PREVIEW VIEW (How it looks in forum feed)
  // -----------------------------------------------------------
  Widget _buildPreviewView(Color catColor, IconData catIcon) {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final Color badgeColor = _getKuvvetColor(widget.kuvvet);

    if (title.isEmpty && content.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _getSurfaceColor(),
                  shape: BoxShape.circle,
                  border: Border.all(color: _getLineColor()),
                ),
                child: Icon(Icons.edit_note_rounded, size: 40, color: _getSubtitleColor().withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 14),
              Text(
                'Önizleme İçin İçerik Giriniz',
                style: TextStyle(
                  color: _getTextColor(),
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Başlık veya içerik yazmaya başladığınızda konunuzun forum akışında nasıl görüneceği burada canlı gösterilir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _getSubtitleColor(),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => setState(() => _activeTab = 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.edit_rounded, size: 15),
                label: const Text('Yazmaya Başla', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.remove_red_eye_rounded, size: 15, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Canlı Önizleme: Konunuz yayınlandığında forum akışında tam olarak aşağıdaki şekilde görünecektir.',
                    style: TextStyle(
                      color: widget.isDefaultTheme ? const Color(0xFF78350F) : Colors.amber.shade200,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Render simulated Forum Thread (Exact magazine style)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _getCardColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getLineColor(), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta Row (Scope & Category)
                Row(
                  children: [
                    // Scope Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isGeneral
                            ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                            : const Color(0xFF059669).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isGeneral ? '🇹🇷 GENEL' : '📍 ${widget.askerlikYeri.toUpperCase()}',
                        style: TextStyle(
                          color: _isGeneral ? const Color(0xFF2563EB) : const Color(0xFF059669),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Category Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(catIcon, size: 10, color: catColor),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCategory,
                            style: TextStyle(
                              color: catColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Timestamp
                    Text(
                      'Şimdi',
                      style: TextStyle(
                        color: _getSubtitleColor(),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Title
                Text(
                  title.isNotEmpty ? title : 'Başlıksız Konu',
                  style: TextStyle(
                    color: _getTextColor(),
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 6),

                // Content
                Text(
                  content.isNotEmpty ? content : 'İçerik belirtilmedi.',
                  style: TextStyle(
                    color: _getTextColor().withValues(alpha: 0.8),
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 12),
                Divider(color: _getLineColor(), height: 1),
                const SizedBox(height: 8),

                // Footprint: Author & Interaction Count
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'A',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 5),

                    // Rank & Name
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        widget.rutbe,
                        style: TextStyle(color: badgeColor, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.name,
                        style: TextStyle(
                          color: _getTextColor(),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Spacer(),

                    // Interaction Pips
                    Row(
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 13, color: _getSubtitleColor()),
                        const SizedBox(width: 2),
                        Text('0', style: TextStyle(color: _getSubtitleColor(), fontSize: 9.5)),
                        const SizedBox(width: 8),
                        Icon(Icons.chat_bubble_outline_rounded, size: 12, color: _getSubtitleColor()),
                        const SizedBox(width: 2),
                        Text('0', style: TextStyle(color: _getSubtitleColor(), fontSize: 9.5)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // BOTTOM CONTEXT BAR (Toolbar / Live Counter)
  // -----------------------------------------------------------
  Widget _buildBottomContextBar(Color catColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _getSurfaceColor(),
        border: Border(top: BorderSide(color: _getLineColor(), width: 0.8)),
      ),
      child: Row(
        children: [
          if (_activeTab == 0) ...[
            // Quick Formatting Shortcuts
            _buildToolbarIcon(
              tooltip: 'Madde İşareti',
              label: '• Liste',
              onTap: () => _insertFormatting('• '),
            ),
            const SizedBox(width: 4),
            _buildToolbarIcon(
              tooltip: 'Numaralı Liste',
              label: '1. Sıra',
              onTap: () => _insertFormatting('1. '),
            ),
            const SizedBox(width: 4),
            _buildToolbarIcon(
              tooltip: 'Alıntı',
              label: '” Alıntı',
              onTap: () => _insertFormatting('> '),
            ),
            const SizedBox(width: 4),
            _buildToolbarIcon(
              tooltip: 'Soru Etiketi',
              label: '[Soru]',
              onTap: () => _insertFormatting('[Soru] '),
            ),
            const SizedBox(width: 6),

            // Tactical Emoji Pill
            GestureDetector(
              onTap: () => _insertFormatting('🇹🇷 '),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDefaultTheme ? Colors.white : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getLineColor(), width: 0.6),
                ),
                child: const Text('🇹🇷', style: TextStyle(fontSize: 11)),
              ),
            ),
          ] else ...[
            // In Preview Tab: Scope and Category indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tag_rounded, size: 11, color: Color(0xFF2563EB)),
                  const SizedBox(width: 3),
                  Text(
                    '$_selectedCategory (${_isGeneral ? "Genel" : "Bölgesel"})',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Character Counter Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: widget.isDefaultTheme ? Colors.white : Colors.white10,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _getLineColor(), width: 0.6),
            ),
            child: Text(
              '${_contentController.text.length}/2000',
              style: TextStyle(
                color: _contentController.text.length > 1850 ? Colors.redAccent : _getSubtitleColor(),
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarIcon({
    required String tooltip,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDefaultTheme ? Colors.white : Colors.white10,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _getLineColor(), width: 0.6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: _getTextColor(),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// TOPIC DETAIL SCREEN (Magazine Reader + Inline Discussion)
// -------------------------------------------------------------
class ForumDetailScreen extends StatefulWidget {
  final String topicId;
  final Map<String, dynamic> topicData;
  final bool isDefaultTheme;
  final String userId;
  final String userName;
  final String userRank;
  final String userKuvvet;
  final Function(String id, String name, String text) onReport;
  final Function(String senderId, String name) onBlock;
  final VoidCallback onDelete;

  const ForumDetailScreen({
    super.key,
    required this.topicId,
    required this.topicData,
    required this.isDefaultTheme,
    required this.userId,
    required this.userName,
    required this.userRank,
    required this.userKuvvet,
    required this.onReport,
    required this.onBlock,
    required this.onDelete,
  });

  /// Opens a forum topic directly by topicId (used when tapping notifications)
  static Future<void> openTopicById(BuildContext context, String topicId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('forum_topics').doc(topicId).get();
      if (!doc.exists || doc.data() == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bu forum konusu bulunamadı veya silinmiş.')),
          );
        }
        return;
      }
      final data = doc.data()!;
      final prefs = await SharedPreferences.getInstance();
      final themeImage = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
      final isDefaultTheme = themeImage == 'assets/images/img0.webp';
      final userId = prefs.getString('userId') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      final name = prefs.getString('name') ?? 'Asker';
      final surname = prefs.getString('surname') ?? '';
      final rutbe = prefs.getString('rutbe') ?? 'ER';
      final kuvvet = prefs.getString('kuvvet_komutanligi') ?? 'Kara';
      final fullName = surname.isNotEmpty ? '$name $surname' : name;

      if (!context.mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ForumDetailScreen(
            topicId: topicId,
            topicData: data,
            isDefaultTheme: isDefaultTheme,
            userId: userId,
            userName: fullName,
            userRank: rutbe,
            userKuvvet: kuvvet,
            onReport: (id, sName, text) {
              FirebaseFirestore.instance.collection('reports').add({
                'targetType': 'forum_topic',
                'contentId': id,
                'senderId': data['senderId'] ?? '',
                'senderName': sName,
                'contentText': text,
                'reportedBy': userId,
                'timestamp': FieldValue.serverTimestamp(),
              });
            },
            onBlock: (sId, sName) async {
              final blocked = prefs.getStringList('blockedUsers') ?? [];
              if (!blocked.contains(sId)) {
                blocked.add(sId);
                await prefs.setStringList('blockedUsers', blocked);
              }
            },
            onDelete: () async {
              await FirebaseFirestore.instance.collection('forum_topics').doc(topicId).delete();
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error opening topic by ID: $e');
    }
  }

  @override
  State<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends State<ForumDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  late Map<String, dynamic> _topicData;

  @override
  void initState() {
    super.initState();
    _topicData = Map<String, dynamic>.from(widget.topicData);
    RevenueCatService.instance.isPremiumNotifier.addListener(_onPremiumStatusChanged);
  }

  void _onPremiumStatusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    RevenueCatService.instance.isPremiumNotifier.removeListener(_onPremiumStatusChanged);
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Color _getTextColor() {
    return widget.isDefaultTheme ? const Color(0xFF0F172A) : Colors.white;
  }

  Color _getSubtitleColor() {
    return widget.isDefaultTheme ? const Color(0xFF475569) : Colors.white70;
  }

  Color _getLineColor() {
    return widget.isDefaultTheme ? Colors.grey.shade300 : Colors.white.withValues(alpha: 0.12);
  }

  Color _getKuvvetColor(String kuvvet) {
    switch (kuvvet.trim().toLowerCase()) {
      case 'kara':
        return const Color(0xFF15803D);
      case 'deniz':
        return const Color(0xFF0284C7);
      case 'hava':
        return const Color(0xFF0EA5E9);
      case 'jandarma':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSending) return;

    HapticFeedback.lightImpact();
    _replyController.clear();
    FocusScope.of(context).unfocus();

    setState(() => _isSending = true);

    final topicRef = FirebaseFirestore.instance.collection('forum_topics').doc(widget.topicId);
    final replyRef = topicRef.collection('replies').doc();

    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.set(replyRef, {
        'content': text,
        'senderId': widget.userId,
        'senderName': widget.userName,
        'senderRank': widget.userRank,
        'senderKuvvet': widget.userKuvvet,
        'isPremium': RevenueCatService.instance.isPremium,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'likeCount': 0,
      });

      batch.update(topicRef, {
        'replyCount': FieldValue.increment(1),
        'lastActivity': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Error sending reply: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _toggleTopicLike() async {
    HapticFeedback.lightImpact();
    final List<dynamic> likes = _topicData['likes'] ?? [];
    final bool isLiked = likes.contains(widget.userId);
    final docRef = FirebaseFirestore.instance.collection('forum_topics').doc(widget.topicId);

    setState(() {
      if (isLiked) {
        likes.remove(widget.userId);
        _topicData['likeCount'] = (_topicData['likeCount'] ?? 1) - 1;
      } else {
        likes.add(widget.userId);
        _topicData['likeCount'] = (_topicData['likeCount'] ?? 0) + 1;
      }
      _topicData['likes'] = likes;
    });

    try {
      if (isLiked) {
        await docRef.update({
          'likes': FieldValue.arrayRemove([widget.userId]),
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        await docRef.update({
          'likes': FieldValue.arrayUnion([widget.userId]),
          'likeCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _topicData['title'] ?? '';
    final String content = _topicData['content'] ?? '';
    final String category = _topicData['category'] ?? 'Genel';
    final String senderId = _topicData['senderId'] ?? '';
    final String senderName = _topicData['senderName'] ?? 'Asker';
    final String senderRank = _topicData['senderRank'] ?? 'ER';
    final String senderKuvvet = _topicData['senderKuvvet'] ?? 'Kara';
    final List<dynamic> likes = _topicData['likes'] ?? [];
    final int likeCount = _topicData['likeCount'] ?? likes.length;

    final bool isMe = senderId == widget.userId;
    final bool isLiked = likes.contains(widget.userId);
    final Color badgeColor = _getKuvvetColor(senderKuvvet);
    final Color bgColor = widget.isDefaultTheme ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _getTextColor(), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(category, style: TextStyle(color: _getTextColor(), fontSize: 13.5, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: _getTextColor()),
            onPressed: () {
              if (isMe) {
                widget.onDelete();
              } else {
                widget.onReport(widget.topicId, senderName, title);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Line
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                        child: Text(senderRank.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(senderName, style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold, fontSize: 11.5)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleTopicLike,
                        child: Row(
                          children: [
                            Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : _getSubtitleColor(), size: 16),
                            const SizedBox(width: 4),
                            Text('$likeCount', style: TextStyle(color: isLiked ? Colors.redAccent : _getTextColor(), fontWeight: FontWeight.bold, fontSize: 10.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  SelectableText(
                    title,
                    style: TextStyle(color: _getTextColor(), fontSize: 15, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 10),

                  // Body
                  SelectableText(
                    content,
                    style: TextStyle(color: _getTextColor().withValues(alpha: 0.9), fontSize: 12.5, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: _getLineColor()),
                  const SizedBox(height: 10),

                  // Replies Header
                  Text('Cevaplar & Yorumlar', style: TextStyle(color: _getTextColor(), fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // Replies Stream
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('forum_topics').doc(widget.topicId).collection('replies').snapshots(),
                    builder: (context, snapshot) {
                      final allReplies = snapshot.data?.docs ?? [];
                      final replies = List<QueryDocumentSnapshot>.from(allReplies);
                      replies.sort((a, b) {
                        final aTs = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        final bTs = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        if (aTs == null && bTs == null) return 0;
                        if (aTs == null) return 1;
                        if (bTs == null) return -1;
                        return aTs.compareTo(bTs);
                      });

                      if (replies.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('Henüz cevap yazılmamış. İlk yanıtı sen bırak!', style: TextStyle(color: _getSubtitleColor(), fontSize: 11)),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: replies.length,
                        separatorBuilder: (context, index) => Divider(color: _getLineColor(), height: 16),
                        itemBuilder: (context, index) {
                          final rDoc = replies[index];
                          final rData = rDoc.data() as Map<String, dynamic>;
                          final rName = rData['senderName'] ?? 'Asker';
                          final rRank = rData['senderRank'] ?? 'ER';
                          final rText = rData['content'] ?? '';
                          final rKuvvet = rData['senderKuvvet'] ?? 'Kara';
                          final rColor = _getKuvvetColor(rKuvvet);
                          final bool isReplyPremium = (rData['isPremium'] == true) ||
                              (rData['senderId'] == widget.userId && RevenueCatService.instance.isPremium);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isReplyPremium) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Text(
                                        'VIP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(color: rColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(3)),
                                    child: Text(rRank, style: TextStyle(color: rColor, fontSize: 8, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    rName,
                                    style: TextStyle(
                                      color: isReplyPremium ? const Color(0xFFFBBF24) : _getTextColor(),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              SelectableText(rText, style: TextStyle(color: _getTextColor(), fontSize: 11.5, height: 1.35)),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Bottom Reply Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: _getLineColor())),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.isDefaultTheme ? Colors.grey.shade100 : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _replyController,
                        maxLines: 3,
                        minLines: 1,
                        style: TextStyle(color: _getTextColor(), fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Cevabınızı yazın...',
                          hintStyle: TextStyle(color: _getSubtitleColor().withValues(alpha: 0.6), fontSize: 11),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF2563EB), size: 20),
                    onPressed: _sendReply,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
