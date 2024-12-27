import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safaksayar/pages/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  TimeOfDay? selectedTime;
  String? savedDate;
  NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    loadSavedDate();
    tz.initializeTimeZones();
    notificationService.initNotification();
  }

  Future<void> loadSavedDate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedDate = prefs.getString('selected_date') ?? "Henüz tarih seçilmedi";
      if (savedDate != "Henüz tarih seçilmedi") {
        // Saat bilgisini ayır ve göster
        selectedTime = TimeOfDay(
          hour: int.parse(savedDate!.split(' ')[2].split(':')[0]),
          minute: int.parse(savedDate!.split(' ')[2].split(':')[1]),
        );
      }
    });
  }

  Future<void> cancelAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_date'); // Kaydedilen tarihi temizle
    setState(() {
      savedDate = "Henüz tarih seçilmedi";
      selectedTime = null; // Seçilen saati sıfırla
    });
    await notificationService.notificationsPlugin.cancelAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tüm bildirimler iptal edildi ve ayarlar sıfırlandı")),
    );
  }


  Future<void> saveSelectedDate(DateTime selectedDate) async {
    final prefs = await SharedPreferences.getInstance();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(selectedDate);
    await prefs.setString('selected_date', formattedDate);
    loadSavedDate();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
      final now = DateTime.now();
      final selectedDateTime = DateTime(
          now.year, now.month, now.day, picked.hour, picked.minute);
      saveSelectedDate(selectedDateTime);
    }
  }

  void _scheduleNotification() async {
    if (selectedTime != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(now.year, now.month, now.day,
          selectedTime!.hour, selectedTime!.minute);

      if (selectedDateTime.isAfter(now)) {
        final tzDateTime = tz.TZDateTime.from(selectedDateTime, tz.local);
        notificationService.scheduleNotification(
          id: 1,
          title: "Şafak Sayar - 2025",
          body: "Kalan Şafak: ${remainingDuration.inDays} gün kaldı...",
          scheduledNotificationDateTime: selectedDateTime,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bildirim ayarlandı")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Seçilen saat geçmişte olamaz!")),
        );
        print(remainingDuration.inDays);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirim Ayarla"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.indigo],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bildirim Ayarları",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Card(
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      savedDate != null ? "Kaydedilen Tarih: $savedDate" : "Yükleniyor...",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedTime != null
                          ? "Seçilen Saat: ${selectedTime!.format(context)}"
                          : "Henüz bir saat seçilmedi",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () => _selectTime(context),
              child: const Text(
                "Saat Seç",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.lightBlueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _scheduleNotification,
              child: const Text(
                "Bildirim Planla",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: cancelAllNotifications,
              child: const Text(
                "Bildirimleri İptal Et",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
