import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

/// Data model representing a time capsule / surprise message left on a specific calendar date.
class CalendarCapsule {
  final String id;
  final String trackingCode;
  final String dateKey; // yyyy-MM-dd
  final String senderRole; // 'asker' or 'yakin'
  final String senderName;
  final String senderUserId;
  final String? senderRelationship;
  final String? note;
  final String? audioBase64;
  final int? audioDurationSec;
  final String? imageBase64;
  final DateTime createdAt;
  final bool isOpened;
  final DateTime? openedAt;

  CalendarCapsule({
    required this.id,
    required this.trackingCode,
    required this.dateKey,
    required this.senderRole,
    required this.senderName,
    required this.senderUserId,
    this.senderRelationship,
    this.note,
    this.audioBase64,
    this.audioDurationSec,
    this.imageBase64,
    required this.createdAt,
    this.isOpened = false,
    this.openedAt,
  });

  /// Check if the capsule is unlocked for the current date.
  /// Rule: Can ONLY be opened when the target date has arrived (today >= targetDate).
  bool isUnlockedForToday() {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return false;
      final targetDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      final todayNormalized = DateTime(now.year, now.month, now.day);
      return !todayNormalized.isBefore(targetDate);
    } catch (_) {
      return false;
    }
  }

  /// Days remaining until this capsule unlocks
  int daysRemaining() {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return 0;
      final targetDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      final todayNormalized = DateTime(now.year, now.month, now.day);
      final diff = targetDate.difference(todayNormalized).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trackingCode': trackingCode,
      'dateKey': dateKey,
      'senderRole': senderRole,
      'senderName': senderName,
      'senderUserId': senderUserId,
      if (senderRelationship != null && senderRelationship!.isNotEmpty)
        'senderRelationship': senderRelationship,
      'note': note,
      'audioBase64': audioBase64,
      'audioDurationSec': audioDurationSec,
      'imageBase64': imageBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOpened': isOpened,
      'openedAt': openedAt != null ? Timestamp.fromDate(openedAt!) : null,
    };
  }

  factory CalendarCapsule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }
    DateTime? opened;
    if (data['openedAt'] is Timestamp) {
      opened = (data['openedAt'] as Timestamp).toDate();
    }

    return CalendarCapsule(
      id: doc.id,
      trackingCode: data['trackingCode'] ?? '',
      dateKey: data['dateKey'] ?? '',
      senderRole: data['senderRole'] ?? 'asker',
      senderName: data['senderName'] ?? 'Biri',
      senderUserId: data['senderUserId'] ?? '',
      senderRelationship: data['senderRelationship'],
      note: data['note'],
      audioBase64: data['audioBase64'],
      audioDurationSec: (data['audioDurationSec'] as num?)?.toInt(),
      imageBase64: data['imageBase64'],
      createdAt: created,
      isOpened: data['isOpened'] ?? false,
      openedAt: opened,
    );
  }
}

/// Service managing military calendar time capsules, voice recordings, photo attachments, and real-time synchronization.
class CalendarCapsuleService {
  static final CalendarCapsuleService instance = CalendarCapsuleService._internal();
  CalendarCapsuleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Formats DateTime into standard 'yyyy-MM-dd' string key
  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Normalizes date to midnight DateTime
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Real-time stream of all capsules for a specific tracking code
  Stream<List<CalendarCapsule>> streamCapsules(String trackingCode) {
    if (trackingCode.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection('tracking_codes')
        .doc(trackingCode)
        .collection('calendar_capsules')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CalendarCapsule.fromFirestore(doc)).toList();
    });
  }

  /// Saves or updates a capsule for a specific date and sender role
  Future<void> saveCapsule({
    required String trackingCode,
    required String dateKey,
    required String senderRole,
    required String senderName,
    required String senderUserId,
    String? senderRelationship,
    String? note,
    String? audioBase64,
    int? audioDurationSec,
    String? imageBase64,
  }) async {
    final capsuleId = '${dateKey}_$senderRole';
    final docRef = _firestore
        .collection('tracking_codes')
        .doc(trackingCode)
        .collection('calendar_capsules')
        .doc(capsuleId);

    final payload = {
      'id': capsuleId,
      'trackingCode': trackingCode,
      'dateKey': dateKey,
      'senderRole': senderRole,
      'senderName': senderName,
      'senderUserId': senderUserId,
      if (senderRelationship != null && senderRelationship.isNotEmpty)
        'senderRelationship': senderRelationship,
      'note': note,
      'audioBase64': audioBase64,
      'audioDurationSec': audioDurationSec,
      'imageBase64': imageBase64,
      'hasAudio': audioBase64 != null && audioBase64.isNotEmpty,
      'hasImage': imageBase64 != null && imageBase64.isNotEmpty,
      'hasNote': note != null && note.trim().isNotEmpty,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isOpened': false,
    };

    await docRef.set(payload, SetOptions(merge: true));

    // Touch parent tracking_codes document to alert listeners and trigger real-time sync
    try {
      await _firestore.collection('tracking_codes').doc(trackingCode).set({
        'lastCapsuleAt': FieldValue.serverTimestamp(),
        'lastCapsuleSender': senderName,
        'lastCapsuleRole': senderRole,
        'lastCapsuleDateKey': dateKey,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CalendarCapsule] Error touching tracking_codes doc: $e');
    }
  }

  /// Marks a capsule as opened
  Future<void> markAsOpened({
    required String trackingCode,
    required String capsuleId,
  }) async {
    try {
      await _firestore
          .collection('tracking_codes')
          .doc(trackingCode)
          .collection('calendar_capsules')
          .doc(capsuleId)
          .update({
        'isOpened': true,
        'openedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[CalendarCapsule] Error marking as opened: $e');
    }
  }

  /// Deletes a capsule (only allowed by the sender)
  Future<void> deleteCapsule({
    required String trackingCode,
    required String capsuleId,
  }) async {
    try {
      await _firestore
          .collection('tracking_codes')
          .doc(trackingCode)
          .collection('calendar_capsules')
          .doc(capsuleId)
          .delete();
    } catch (e) {
      debugPrint('[CalendarCapsule] Error deleting capsule: $e');
    }
  }

  /// Picks and compresses an image from gallery or camera to Base64
  Future<String?> pickAndCompressImage(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 70,
      );
      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      debugPrint('[CalendarCapsule] Image pick error: $e');
      return null;
    }
  }

  /// Helper to convert base64 audio to temporary File for playback
  Future<File?> createAudioFileFromBase64(String base64Audio) async {
    try {
      final bytes = base64Decode(base64Audio);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/capsule_audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('[CalendarCapsule] Audio file write error: $e');
      return null;
    }
  }
}
