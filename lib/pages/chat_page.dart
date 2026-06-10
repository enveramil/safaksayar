import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
  String _backgroundImage = 'assets/images/img0.webp';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getString('userId') ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
        _name = prefs.getString('name') ?? 'Asker';
        _surname = prefs.getString('surname') ?? '';
        _rutbe = prefs.getString('rutbe') ?? 'ER';
        _kuvvetKomutanligi = prefs.getString('kuvvet_komutanligi') ?? 'Kara';
        _askerlikYeri = prefs.getString('askerlik_yeri') ?? 'Bilinmiyor';
        _backgroundImage = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user info for chat: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _isDefaultTheme => _backgroundImage == 'assets/images/img0.webp';

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

                final docs = snapshot.data?.docs ?? [];
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
