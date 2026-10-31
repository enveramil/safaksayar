import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:safaksayar/Services/calendar_capsule_service.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';

/// Interactive modal bottom sheet for creating a Time Capsule (Note, Voice Message, Photo)
class CalendarCapsuleCreateSheet extends StatefulWidget {
  final DateTime targetDate;
  final String trackingCode;
  final String userRole; // 'asker' or 'yakin'
  final String userName;
  final String userId;
  final CalendarCapsule? existingCapsule;
  final VoidCallback onSaved;

  final String? senderRelationship;

  const CalendarCapsuleCreateSheet({
    super.key,
    required this.targetDate,
    required this.trackingCode,
    required this.userRole,
    required this.userName,
    required this.userId,
    this.senderRelationship,
    this.existingCapsule,
    required this.onSaved,
  });

  @override
  State<CalendarCapsuleCreateSheet> createState() => _CalendarCapsuleCreateSheetState();
}

class _CalendarCapsuleCreateSheetState extends State<CalendarCapsuleCreateSheet> {
  final TextEditingController _noteController = TextEditingController();
  AudioRecorder? _audioRecorder;
  AudioPlayer? _audioPlayer;

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _recordedAudioPath;
  String? _audioBase64;
  int? _audioDurationSec;

  bool _isPlayingPreview = false;
  Duration _previewPosition = Duration.zero;
  Duration _previewDuration = Duration.zero;
  StreamSubscription? _playerPosSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _playerDurSub;

  String? _imageBase64;
  bool _isSaving = false;

  bool get _isFutureDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(widget.targetDate.year, widget.targetDate.month, widget.targetDate.day);
    return target.isAfter(today);
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingCapsule != null) {
      _noteController.text = widget.existingCapsule!.note ?? '';
      _audioBase64 = widget.existingCapsule!.audioBase64;
      _audioDurationSec = widget.existingCapsule!.audioDurationSec;
      _imageBase64 = widget.existingCapsule!.imageBase64;
    }
  }

  AudioPlayer? _ensurePlayer() {
    if (_audioPlayer != null) return _audioPlayer;
    try {
      final p = AudioPlayer();
      _playerStateSub = p.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlayingPreview = state == PlayerState.playing;
          });
        }
      }, onError: (e) {
        debugPrint('[CapsuleAudio] onPlayerStateChanged error: $e');
      });

      _playerPosSub = p.onPositionChanged.listen((pos) {
        if (mounted) {
          setState(() {
            _previewPosition = pos;
          });
        }
      }, onError: (e) {
        debugPrint('[CapsuleAudio] onPositionChanged error: $e');
      });

      _playerDurSub = p.onDurationChanged.listen((dur) {
        if (mounted) {
          setState(() {
            _previewDuration = dur;
          });
        }
      }, onError: (e) {
        debugPrint('[CapsuleAudio] onDurationChanged error: $e');
      });

      _audioPlayer = p;
      return p;
    } catch (e) {
      debugPrint('[CapsuleAudio] AudioPlayer init error: $e');
      return null;
    }
  }

  AudioRecorder _ensureRecorder() {
    _audioRecorder ??= AudioRecorder();
    return _audioRecorder!;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _recordTimer?.cancel();
    _playerPosSub?.cancel();
    _playerStateSub?.cancel();
    _playerDurSub?.cancel();
    try {
      _audioRecorder?.dispose();
    } catch (_) {}
    try {
      _audioPlayer?.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final recorder = _ensureRecorder();
      if (await recorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        HapticFeedback.mediumImpact();
        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
          _recordedAudioPath = filePath;
        });

        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() {
            _recordSeconds++;
          });
          // Max recording length: 60 seconds
          if (_recordSeconds >= 60) {
            _stopRecording();
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ses kaydı için mikrofon izni gereklidir.')),
          );
        }
      }
    } catch (e) {
      debugPrint('[Capsule] Start recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _recordTimer?.cancel();
      final recorder = _ensureRecorder();
      final path = await recorder.stop();
      HapticFeedback.lightImpact();

      if (path != null && File(path).existsSync()) {
        final bytes = await File(path).readAsBytes();
        final b64 = base64Encode(bytes);

        setState(() {
          _isRecording = false;
          _recordedAudioPath = path;
          _audioBase64 = b64;
          _audioDurationSec = _recordSeconds > 0 ? _recordSeconds : 1;
        });
      } else {
        setState(() {
          _isRecording = false;
        });
      }
    } catch (e) {
      debugPrint('[Capsule] Stop recording error: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _togglePlayPreview() async {
    final player = _ensurePlayer();
    if (player == null) return;
    try {
      if (_isPlayingPreview) {
        await player.pause();
      } else {
        if (_recordedAudioPath != null && File(_recordedAudioPath!).existsSync()) {
          await player.play(DeviceFileSource(_recordedAudioPath!));
        } else if (_audioBase64 != null) {
          final file = await CalendarCapsuleService.instance.createAudioFileFromBase64(_audioBase64!);
          if (file != null) {
            _recordedAudioPath = file.path;
            await player.play(DeviceFileSource(file.path));
          }
        }
      }
    } catch (e) {
      debugPrint('[CapsuleAudio] Playback preview error: $e');
    }
  }

  Future<void> _deleteAudio() async {
    try {
      await _audioPlayer?.stop();
    } catch (_) {}
    setState(() {
      _audioBase64 = null;
      _recordedAudioPath = null;
      _audioDurationSec = null;
      _previewPosition = Duration.zero;
      _previewDuration = Duration.zero;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.selectionClick();
    final b64 = await CalendarCapsuleService.instance.pickAndCompressImage(source);
    if (b64 != null && mounted) {
      setState(() {
        _imageBase64 = b64;
      });
    }
  }

  Future<void> _saveCapsule() async {
    final note = _noteController.text.trim();
    if (note.isEmpty && _audioBase64 == null && _imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir not, sesli mesaj veya fotoğraf ekleyin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final dateKey = CalendarCapsuleService.formatDateKey(widget.targetDate);

    await CalendarCapsuleService.instance.saveCapsule(
      trackingCode: widget.trackingCode,
      dateKey: dateKey,
      senderRole: widget.userRole,
      senderName: widget.userName,
      senderUserId: widget.userId,
      senderRelationship: widget.senderRelationship,
      note: note.isNotEmpty ? note : null,
      audioBase64: _audioBase64,
      audioDurationSec: _audioDurationSec,
      imageBase64: _imageBase64,
    );

    SoldierMatchService.instance.syncSoldierFCMToken();

    HapticFeedback.mediumImpact();

    if (mounted) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isFutureDate
                      ? 'Zaman Kapsülü kilitlendi! O gün geldiğinde açılacaktır 🔒'
                      : 'Anı takvime kaydedildi! 💌',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF15803D),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTimer(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(widget.targetDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 25,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag bar
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isFutureDate
                            ? [Colors.amber.shade600, Colors.deepOrange.shade600]
                            : [Colors.blueAccent, Colors.indigoAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFutureDate ? Icons.lock_clock_rounded : Icons.mark_email_read_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isFutureDate ? "Sürpriz Zaman Kapsülü Bırak" : "Bu Güne Özel Anı Bırak",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.amberAccent.shade100 : Colors.indigo.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Lock Rule Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isFutureDate
                      ? (isDark ? Colors.amber.withValues(alpha: 0.12) : Colors.amber.shade50)
                      : (isDark ? Colors.blue.withValues(alpha: 0.12) : Colors.blue.shade50),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isFutureDate
                        ? Colors.amber.withValues(alpha: 0.35)
                        : Colors.blue.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isFutureDate ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                      size: 18,
                      color: _isFutureDate ? Colors.amber.shade800 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isFutureDate
                            ? "🔒 Kural: Bırakacağınız mesaj kilitlenecektir. Alıcı bu mesajı sadece o gün ($formattedDate) geldiğinde açabilecektir!"
                            : "🔓 Bu tarih bugüne veya geçmişe ait olduğu için hemen görüntülenebilir.",
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _isFutureDate
                              ? (isDark ? Colors.amber.shade200 : Colors.amber.shade900)
                              : (isDark ? Colors.blue.shade200 : Colors.blue.shade900),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 1. TEXT NOTE INPUT
              Text(
                "Mektup / Not Yaz ✍️",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 4,
                style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: "O güne özel içinden geçenleri, sevgi dolu sözlerini veya duygularını yaz...",
                  hintStyle: TextStyle(fontSize: 12.5, color: isDark ? Colors.white38 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. VOICE MESSAGE RECORDING SECTION
              Text(
                "Sesli Mesaj Bırak 🎙️",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),

              // Recording Container or Player
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isRecording
                        ? Colors.redAccent
                        : (_audioBase64 != null ? Colors.green : (isDark ? Colors.white12 : Colors.grey.shade300)),
                    width: _isRecording ? 1.5 : 1.0,
                  ),
                ),
                child: _audioBase64 != null
                    // Audio Preview Player
                    ? Row(
                        children: [
                          GestureDetector(
                            onTap: _togglePlayPreview,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF10B981),
                              ),
                              child: Icon(
                                _isPlayingPreview ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Kaydedilen Sesli Not",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _formatTimer(_audioDurationSec ?? 0),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: _previewDuration.inMilliseconds > 0
                                      ? (_previewPosition.inMilliseconds / _previewDuration.inMilliseconds).clamp(0.0, 1.0)
                                      : 0.0,
                                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: _deleteAudio,
                            tooltip: "Ses kaydını sil",
                          ),
                        ],
                      )
                    // Record / Stop Record Button
                    : Row(
                        children: [
                          GestureDetector(
                            onTap: _isRecording ? _stopRecording : _startRecording,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording ? Colors.redAccent : Colors.indigoAccent,
                                boxShadow: [
                                  if (_isRecording)
                                    BoxShadow(
                                      color: Colors.redAccent.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                ],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isRecording
                                      ? "Kayıt Yapılıyor... (${_formatTimer(_recordSeconds)})"
                                      : "Mikrofona dokun ve sesini kaydet",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: _isRecording ? Colors.redAccent : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isRecording
                                      ? "Durdurmak için kırmızı butona dokun"
                                      : "Maksimum 60 saniyelik sesli mesaj bırakabilirsin",
                                  style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white38 : Colors.black45),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // 3. PHOTO ATTACHMENT SECTION
              Text(
                "Fotoğraf Ekle 📸",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),

              if (_imageBase64 != null) ...[
                // Photo Preview
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        base64Decode(_imageBase64!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _imageBase64 = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Photo Picker Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text("Galeriden Seç", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text("Fotoğraf Çek", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 22),

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCapsule,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _isFutureDate ? Icons.lock_clock_rounded : Icons.check_circle_rounded,
                          size: 20,
                        ),
                  label: Text(
                    _isSaving
                        ? "Kapsül Kilitleniyor..."
                        : (_isFutureDate ? "ZAMAN KAPSÜLÜNÜ KİLİTLE & GÖNDER 🔒" : "ANIYI KAYDET 💌"),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFutureDate ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive modal for viewing an existing Calendar Capsule (Locked countdown OR Unlocked contents)
class CalendarCapsuleViewDialog extends StatefulWidget {
  final CalendarCapsule capsule;
  final String currentUserRole;
  final String currentUserId;
  final VoidCallback onDeleted;

  const CalendarCapsuleViewDialog({
    super.key,
    required this.capsule,
    required this.currentUserRole,
    required this.currentUserId,
    required this.onDeleted,
  });

  @override
  State<CalendarCapsuleViewDialog> createState() => _CalendarCapsuleViewDialogState();
}

class _CalendarCapsuleViewDialogState extends State<CalendarCapsuleViewDialog> {
  AudioPlayer? _audioPlayer;
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _durSub;
  String? _localAudioPath;

  bool get _isSender => widget.capsule.senderUserId == widget.currentUserId ||
      widget.capsule.senderRole == widget.currentUserRole;

  bool get _isUnlocked => widget.capsule.isUnlockedForToday();

  AudioPlayer? _ensurePlayer() {
    if (_audioPlayer != null) return _audioPlayer;
    try {
      final p = AudioPlayer();
      _stateSub = p.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      }, onError: (e) {
        debugPrint('[CapsuleViewAudio] onPlayerStateChanged error: $e');
      });

      _posSub = p.onPositionChanged.listen((pos) {
        if (mounted) {
          setState(() {
            _position = pos;
          });
        }
      }, onError: (e) {
        debugPrint('[CapsuleViewAudio] onPositionChanged error: $e');
      });

      _durSub = p.onDurationChanged.listen((dur) {
        if (mounted) {
          setState(() {
            _duration = dur;
          });
        }
      }, onError: (e) {
        debugPrint('[CapsuleViewAudio] onDurationChanged error: $e');
      });

      _audioPlayer = p;
      return p;
    } catch (e) {
      debugPrint('[CapsuleViewAudio] AudioPlayer init error: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    if (_isUnlocked) {
      _confettiController.play();
      if (!widget.capsule.isOpened && !_isSender) {
        CalendarCapsuleService.instance.markAsOpened(
          trackingCode: widget.capsule.trackingCode,
          capsuleId: widget.capsule.id,
        );
      }
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _durSub?.cancel();
    try {
      _audioPlayer?.dispose();
    } catch (_) {}
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _toggleAudioPlay() async {
    final player = _ensurePlayer();
    if (player == null) return;
    try {
      if (_isPlaying) {
        await player.pause();
      } else {
        if (_localAudioPath == null && widget.capsule.audioBase64 != null) {
          final f = await CalendarCapsuleService.instance.createAudioFileFromBase64(widget.capsule.audioBase64!);
          if (f != null) {
            _localAudioPath = f.path;
          }
        }
        if (_localAudioPath != null) {
          await player.play(DeviceFileSource(_localAudioPath!));
        }
      }
    } catch (e) {
      debugPrint('[CapsuleViewAudio] Audio play error: $e');
    }
  }

  String _formatTimer(int totalSec) {
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parts = widget.capsule.dateKey.split('-');
    DateTime? parsedDate;
    if (parts.length == 3) {
      parsedDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }
    final formattedDate = parsedDate != null
        ? DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(parsedDate)
        : widget.capsule.dateKey;

    final daysRemaining = widget.capsule.daysRemaining();

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==========================================
                  // CASE A: LOCKED TIME CAPSULE (Future & Recipient)
                  // ==========================================
                  if (!_isUnlocked && !_isSender) ...[
                    // Locked Icon Animation
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "Kilitli Zaman Kapsülü 🔒",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${widget.capsule.senderName} (${widget.capsule.senderRole == 'asker' ? 'Askerin' : 'Yakının'}) senin için bu güne özel bir sürpriz bıraktı!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Countdown Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.amber.shade600, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                "KİLİDİN AÇILMASINA KALAN SÜRE",
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: isDark ? Colors.amberAccent : Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$daysRemaining GÜN",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Açılış Tarihi: $formattedDate",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white60 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "Kural gereği bu mektup, sesli mesaj ve fotoğraf sadece belirtilen tarih geldiğinde açılabilir. O güne kadar sabırla bekle! 💖",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white54 : Colors.black54,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        "SABIRSIZLIKLA BEKLİYORUM 💖",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6),
                      ),
                    ),
                  ]

                  // ==========================================
                  // CASE B & C: SENDER PREVIEW OR UNLOCKED CAPSULE
                  // ==========================================
                  else ...[
                    // Unlocked / Preview Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isUnlocked ? const Color(0xFF10B981) : Colors.amber.shade700,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isUnlocked ? Icons.lock_open_rounded : Icons.visibility_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isUnlocked
                                    ? "Sürpriz Zaman Kapsülü Açıldı! 💌"
                                    : "Gönderdiğin Zaman Kapsülü (Önizleme) 👁️",
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (_isSender)
                          IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Kapsülü Sil'),
                                  content: const Text('Bu tarihe bıraktığın mesajı silmek istediğine emin misin?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await CalendarCapsuleService.instance.deleteCapsule(
                                  trackingCode: widget.capsule.trackingCode,
                                  capsuleId: widget.capsule.id,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  widget.onDeleted();
                                }
                              }
                            },
                          ),
                      ],
                    ),

                    if (!_isUnlocked && _isSender) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.amber.withValues(alpha: 0.1) : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Text(
                          "🔒 Bu mesajı sen bıraktın. Alıcı bu mesajı $formattedDate tarihinde ($daysRemaining gün sonra) açabilecektir.",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 1. TEXT NOTE (Letter Stationery Styling)
                    if (widget.capsule.note != null && widget.capsule.note!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.edit_note_rounded, size: 16, color: Colors.amber),
                                const SizedBox(width: 6),
                                Text(
                                  "${widget.capsule.senderName}'den Mektup 💌",
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              widget.capsule.note!,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 2. VOICE MESSAGE PLAYER
                    if (widget.capsule.audioBase64 != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _toggleAudioPlay,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF10B981),
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${widget.capsule.senderName}'in Sesi 🎙️",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _formatTimer(widget.capsule.audioDurationSec ?? 0),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: _duration.inMilliseconds > 0
                                        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                                        : 0.0,
                                    backgroundColor: Colors.grey.withValues(alpha: 0.25),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 3. PHOTO ATTACHMENT
                    if (widget.capsule.imageBase64 != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          base64Decode(widget.capsule.imageBase64!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 220,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const SizedBox(height: 10),

                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("KAPAT", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Confetti when unlocked
        if (_isUnlocked)
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
      ],
    );
  }
}
