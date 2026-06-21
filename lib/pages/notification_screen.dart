import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/notification_service.dart';

/// Bu sayfa artık profile.dart üzerinden erişilmiyor.
/// Geriye dönük uyumluluk için korunmuştur.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _hour = 21;
  int _minute = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _hour = prefs.getInt('notif_hour') ?? 21;
        _minute = prefs.getInt('notif_minute') ?? 0;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    await NotificationService().saveNotificationTime(_hour, _minute);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Bildirimler her gün ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')} için ayarlandı.',
          ),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _cancel() async {
    await NotificationService().cancelAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm bildirimler iptal edildi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Bildirim Saati',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Her gün kalan askerlik gününü bu saatte hatırlatacağız.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _timeSpinner(
                  label: 'Saat',
                  value: _hour,
                  onUp: () => setState(() => _hour = (_hour + 1) % 24),
                  onDown: () => setState(() => _hour = (_hour - 1 + 24) % 24),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(':',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                ),
                _timeSpinner(
                  label: 'Dakika',
                  value: _minute,
                  onUp: () => setState(() => _minute = (_minute + 1) % 60),
                  onDown: () => setState(() => _minute = (_minute - 1 + 60) % 60),
                ),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Kaydet & Planla',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Tüm Bildirimleri İptal Et',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeSpinner({
    required String label,
    required int value,
    required VoidCallback onUp,
    required VoidCallback onDown,
  }) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        IconButton(
            onPressed: onUp,
            icon: const Icon(Icons.keyboard_arrow_up_rounded,
                color: Colors.deepOrange, size: 30)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            value.toString().padLeft(2, '0'),
            key: ValueKey(value),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
            onPressed: onDown,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.deepOrange, size: 30)),
      ],
    );
  }
}
