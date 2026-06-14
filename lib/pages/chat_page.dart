import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String backgroundImage;
  const ChatScreen({super.key, required this.backgroundImage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isGeneralSelected = true;
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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
      }
    } catch (e) {
      print('Error loading user info for chat: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool get _isDefaultTheme => widget.backgroundImage == 'assets/images/img0.webp';

  Color _getTextColor() {
    return _isDefaultTheme ? Colors.black : Colors.white;
  }

  Color _getCardColor() {
    return _isDefaultTheme
        ? Colors.white.withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.45);
  }

  Color _getBorderColor() {
    return _isDefaultTheme
        ? Colors.grey.shade300
        : Colors.white.withValues(alpha: 0.15);
  }

  Color _getSubtitleColor() {
    return _isDefaultTheme ? Colors.black54 : Colors.white70;
  }

  Color _getKuvvetColor(String kuvvet) {
    switch (kuvvet.trim().toLowerCase()) {
      case 'kara':
        return Colors.green.shade800;
      case 'deniz':
        return Colors.blue.shade900;
      case 'hava':
        return Colors.lightBlue.shade700;
      case 'jandarma':
        return Colors.teal.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDisplayName(String first, String last) {
    if (last.isEmpty) return first;
    return '$first ${last[0]}.';
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final messageData = {
      'senderId': _userId,
      'senderName': _formatDisplayName(_name, _surname),
      'senderRank': _rutbe,
      'senderKuvvet': _kuvvetKomutanligi,
      'message': text,
      'timestamp': FieldValue.serverTimestamp(),
      'location': _askerlikYeri,
    };

    try {
      if (_isGeneralSelected) {
        await FirebaseFirestore.instance
            .collection('general_chat')
            .add(messageData);
      } else {
        await FirebaseFirestore.instance
            .collection('local_chats')
            .doc(_askerlikYeri)
            .collection('messages')
            .add(messageData);
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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

    if (!_eulaAccepted) {
      return _buildEulaOverlay();
    }

    final queryStream = _isGeneralSelected
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Column(
        children: [
          // Custom Tab Slider
          _buildTabSelector(),
          
          // Chat room banner
          _buildRoomBanner(),

          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: queryStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Bağlantı hatası oluştu: ${snapshot.error}',
                        style: TextStyle(color: _getTextColor()),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                // Filter out messages from blocked users
                final docs = allDocs.where((doc) {
                  final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  final String senderId = data['senderId'] ?? '';
                  return !_blockedUserIds.contains(senderId);
                }).toList();

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                    final DateTime messageDate = timestamp != null ? timestamp.toDate() : DateTime.now();

                    bool showDateHeader = false;
                    if (index == docs.length - 1) {
                      showDateHeader = true;
                    } else {
                      final prevDoc = docs[index + 1].data() as Map<String, dynamic>;
                      final prevTimestamp = prevDoc['timestamp'] as Timestamp?;
                      if (prevTimestamp != null) {
                        DateTime prevDate = prevTimestamp.toDate();
                        if (messageDate.year != prevDate.year ||
                            messageDate.month != prevDate.month ||
                            messageDate.day != prevDate.day) {
                          showDateHeader = true;
                        }
                      } else {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showDateHeader)
                          _buildDateHeader(messageDate),
                        _buildMessageBubble(doc),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Text Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _getCardColor(),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: _getBorderColor(), width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isGeneralSelected = true;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isGeneralSelected
                        ? Colors.blueAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Genel Sohbet',
                    style: TextStyle(
                      color: _isGeneralSelected
                          ? Colors.white
                          : _getTextColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isGeneralSelected = false;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: !_isGeneralSelected
                        ? Colors.blueAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'Bölge Sohbeti',
                    style: TextStyle(
                      color: !_isGeneralSelected
                          ? Colors.white
                          : _getTextColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: _getCardColor().withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor().withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _isGeneralSelected ? Icons.public : Icons.location_on,
            color: Colors.blueAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isGeneralSelected
                  ? 'Türkiye genelindeki tüm askerler ile sohbet edin.'
                  : 'Şu anki görev yeriniz: $_askerlikYeri. Buradaki askerlerle konuşun.',
              style: TextStyle(
                color: _getSubtitleColor(),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isGeneralSelected ? Icons.forum_outlined : Icons.location_off_outlined,
              size: 64,
              color: _getSubtitleColor().withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz Mesaj Yok',
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                _isGeneralSelected
                    ? 'Genel sohbet odası şu an boş. İlk mesajı siz göndererek sohbeti başlatın!'
                    : '$_askerlikYeri bölgesinde henüz kimse konuşmadı. İlk siz yazın!',
                style: TextStyle(
                  color: _getSubtitleColor(),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final String senderId = data['senderId'] ?? '';
    final String senderName = data['senderName'] ?? 'Anonim Asker';
    final String senderRank = data['senderRank'] ?? 'ER';
    final String senderKuvvet = data['senderKuvvet'] ?? 'Kara';
    final String messageText = data['message'] ?? '';
    final Timestamp? timestamp = data['timestamp'] as Timestamp?;

    final bool isMe = senderId == _userId;

    String timeStr = '';
    if (timestamp != null) {
      final DateTime dateTime = timestamp.toDate();
      timeStr = DateFormat('HH:mm').format(dateTime);
    } else {
      timeStr = DateFormat('HH:mm').format(DateTime.now());
    }

    final Color badgeColor = _getKuvvetColor(senderKuvvet);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          _showOptionsBottomSheet(
            messageId: doc.id,
            senderId: senderId,
            senderName: senderName,
            messageText: messageText,
            isMe: isMe,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.blueAccent.withValues(alpha: 0.9)
                : _getCardColor(),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
            border: Border.all(
              color: isMe ? Colors.blueAccent.shade400 : _getBorderColor(),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sender identity and time row (always show at the top of the bubble)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Rank badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : _getTextColor().withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isMe
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : _getTextColor().withValues(alpha: 0.15),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              senderRank.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : _getTextColor(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Force Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatKuvvet(senderKuvvet),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Name
                          Flexible(
                            child: Text(
                              isMe ? 'Sen' : senderName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.white : _getTextColor(),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe 
                            ? Colors.white.withValues(alpha: 0.75) 
                            : _getSubtitleColor().withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Message text
                Text(
                  messageText,
                  style: TextStyle(
                    color: isMe ? Colors.white : _getTextColor(),
                    fontSize: 14.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 20.0, bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: _getCardColor().withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor().withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Text(
          _formatDateHeader(date),
          style: TextStyle(
            color: _getSubtitleColor(),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Bugün';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Dün';
    } else {
      return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
    }
  }

  String _formatKuvvet(String kuvvet) {
    switch (kuvvet.trim().toLowerCase()) {
      case 'kara':
        return 'KARA KUV.';
      case 'deniz':
        return 'DENİZ KUV.';
      case 'hava':
        return 'HAVA KUV.';
      case 'jandarma':
        return 'JANDARMA';
      default:
        return kuvvet.toUpperCase();
    }
  }


  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 8.0,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12.0 : 20.0,
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _getCardColor(),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _getBorderColor(), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    controller: _messageController,
                    maxLines: null,
                    maxLength: 500,
                    style: TextStyle(color: _getTextColor(), fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      hintStyle: TextStyle(
                        color: _getSubtitleColor().withValues(alpha: 0.6),
                        fontSize: 14.5,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                height: 48,
                width: 48,
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEulaOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: _isDefaultTheme
          ? Colors.white
          : const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.gavel_rounded,
                      size: 64,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sohbet Odası Sözleşmesi (EULA)',
                      style: TextStyle(
                        color: _getTextColor(),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Son Güncelleme: Haziran 2026',
                      style: TextStyle(
                        color: _getSubtitleColor().withValues(alpha: 0.7),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Divider(color: _getBorderColor()),
                    const SizedBox(height: 24),
                    Text(
                      'Şafak Sayar Sohbet Odalarına hoş geldiniz. Topluluğumuzun güvenliğini ve saygı çerçevesini korumak amacıyla, sohbet özelliğini kullanmadan önce aşağıdaki Kullanıcı Sözleşmesi (EULA) şartlarını kabul etmeniz zorunludur:\n\n'
                      '1. SIFIR TOLERANS POLİTİKASI\n'
                      'Uygulamamız içerisinde hiçbir şekilde küfür, hakaret, taciz, nefret söylemi, ayrımcılık, pornografik içerik veya yasa dışı paylaşımlara İZİN VERİLMEZ. Bu tür paylaşımlara karşı sıfır tolerans gösterilmektedir.\n\n'
                      '2. İÇERİK ŞİKAYET ETME (FLAG)\n'
                      'Sözleşmeye aykırı veya sakıncalı bir mesajla karşılaştığınızda, ilgili mesajın üzerine uzun süre basılı tutarak "Mesajı Şikayet Et" seçeneğini kullanabilirsiniz. Şikayet edilen içerikler geliştiricilerimiz tarafından en geç 24 saat içinde incelenerek silinecektir.\n\n'
                      '3. KULLANICI ENGELLEME (BLOCK)\n'
                      'Sizi rahatsız eden veya tacizci davranışlar sergileyen herhangi bir kullanıcıyı, mesajına uzun basarak "Kullanıcıyı Engelle" seçeneği ile engelleyebilirsiniz. Engellediğiniz kullanıcının tüm mesajları anında sohbet akışınızdan kalıcı olarak kaldırılacaktır.\n\n'
                      '4. HESAP UZAKLAŞTIRMA VE YAPTIRIMLAR\n'
                      'Sözleşme kurallarını ihlal eden veya diğer kullanıcıları rahatsız eden hesaplar, şikayetlerin değerlendirilmesi sonucunda 24 saat içerisinde sistemden kalıcı olarak uzaklaştırılır ve tüm mesajları silinir.\n\n'
                      '5. KİŞİSEL VERİLER VE BEYAN\n'
                      'Sohbet odasında paylaştığınız tüm mesajların sorumluluğu tarafınıza aittir. Diğer kullanıcılarla kişisel bilgilerinizi paylaşmamanız önerilir.',
                      style: TextStyle(
                        color: _getTextColor().withValues(alpha: 0.95),
                        fontSize: 14.5,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Fixed bottom accept button container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: _isDefaultTheme
                  ? Colors.grey.shade50
                  : const Color(0xFF1E293B),
                border: Border(
                  top: BorderSide(color: _getBorderColor(), width: 1),
                ),
              ),
              child: ElevatedButton(
                onPressed: _acceptEula,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Okudum, Kabul Ediyorum',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _acceptEula() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('eulaAccepted', true);
      setState(() {
        _eulaAccepted = true;
      });
    } catch (e) {
      print('Error saving EULA acceptance: $e');
    }
  }

  void _showOptionsBottomSheet({
    required String messageId,
    required String senderId,
    required String senderName,
    required String messageText,
    required bool isMe,
  }) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        final bool isDark = !_isDefaultTheme;
        final Color modalBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

        return Container(
          decoration: BoxDecoration(
            color: modalBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    isMe ? 'Kendi Mesajınız' : '$senderName kullanıcısının mesajı',
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: _getBorderColor()),
                if (!isMe) ...[
                  ListTile(
                    leading: const Icon(Icons.flag_outlined, color: Colors.amber),
                    title: Text(
                      'Mesajı Şikayet Et',
                      style: TextStyle(color: _getTextColor()),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _reportMessage(messageId, senderId, senderName, messageText);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.block_outlined, color: Colors.redAccent),
                    title: Text(
                      'Kullanıcıyı Engelle',
                      style: TextStyle(color: _getTextColor()),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _blockUser(senderId, senderName, messageId, messageText);
                    },
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Bu sizin kendi mesajınızdır. Şikayet etme veya engelleme seçeneği bulunmamaktadır.',
                      style: TextStyle(color: _getSubtitleColor(), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _reportMessage(String messageId, String senderId, String senderName, String messageText) async {
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'flag_message',
        'reportedMessageId': messageId,
        'reportedSenderId': senderId,
        'reportedSenderName': senderName,
        'reportedMessageText': messageText,
        'reporterUserId': _userId,
        'reporterUserName': _formatDisplayName(_name, _surname),
        'timestamp': FieldValue.serverTimestamp(),
        'actionTaken': false,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şikayetiniz iletildi. 24 saat içerisinde incelenecektir.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error reporting message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şikayet iletilemedi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _blockUser(String senderId, String senderName, String messageId, String messageText) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Kullanıcıyı Engelle?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '$senderName adlı kullanıcıyı engellemek istediğinizden emin misiniz? Bu kullanıcının tüm mesajları anında gizlenecektir.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Engelle'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentBlocks = prefs.getStringList('blockedUsers') ?? [];
      if (!currentBlocks.contains(senderId)) {
        currentBlocks.add(senderId);
        await prefs.setStringList('blockedUsers', currentBlocks);
      }

      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'block_user',
        'blockedUserId': senderId,
        'blockedUserName': senderName,
        'relatedMessageId': messageId,
        'relatedMessageText': messageText,
        'blockedByUserId': _userId,
        'blockedByUserName': _formatDisplayName(_name, _surname),
        'timestamp': FieldValue.serverTimestamp(),
        'actionTaken': false,
      });

      setState(() {
        _blockedUserIds = currentBlocks;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$senderName engellendi ve mesajları gizlendi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error blocking user: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
