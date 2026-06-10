import 'dart:io';
import 'package:flutter/material.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'package:safaksayar/pages/theme_page.dart';
import 'package:safaksayar/pages/user_input_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_review/in_app_review.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _backgroundImage = 'assets/images/img0.webp';
  String _name = '';
  String _surname = '';
  String _rutbe = '';
  String _kuvvetKomutanligi = '';
  String _askerlikYeri = '';
  String _memleket = '';
  String _sulusTarihi = '';
  String _terhisTarihi = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backgroundImage = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
      _name = prefs.getString('name') ?? '';
      _surname = prefs.getString('surname') ?? '';
      _rutbe = prefs.getString('rutbe') ?? '';
      _kuvvetKomutanligi = prefs.getString('kuvvet_komutanligi') ?? '';
      _askerlikYeri = prefs.getString('askerlik_yeri') ?? '';
      _memleket = prefs.getString('memleket') ?? '';
      _sulusTarihi = prefs.getString('sulus_tarihi') ?? '';
      _terhisTarihi = prefs.getString('end_date') ?? '';
    });
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(dateStr);
      return '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _getCommandLogo() {
    switch (_kuvvetKomutanligi.trim().toLowerCase()) {
      case 'kara':
        return 'assets/images/Kara.webp';
      case 'deniz':
        return 'assets/images/Deniz.webp';
      case 'hava':
        return 'assets/images/Hava.webp';
      case 'jandarma':
        return 'assets/images/Jandarma.webp';
      default:
        return 'assets/images/app_logo.png';
    }
  }

  Widget _buildIDCard() {
    final bool isDark = !_isDefaultTheme;
    final String commandLogo = _getCommandLogo();
    final String fullName = _name.isNotEmpty || _surname.isNotEmpty
        ? '${_name.toUpperCase()} ${_surname.toUpperCase()}'
        : 'MİSAFİR KULLANICI';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: _isDefaultTheme
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: isDark ? 0.08 : 0.04,
                child: Image.asset(
                  commandLogo,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [Colors.white24, Colors.white12]
                                : [Colors.blueAccent, Colors.blueAccent.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(commandLogo),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getTextColor(),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.blueAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : Colors.blueAccent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                _rutbe.isNotEmpty ? _rutbe.toUpperCase() : 'ASKER',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.blueAccent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    height: 1,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.location_on_outlined,
                          'GÖREV YERİ',
                          _askerlikYeri.isNotEmpty ? _askerlikYeri : 'Belirtilmedi',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.home_outlined,
                          'MEMLEKET',
                          _memleket.isNotEmpty ? _memleket : 'Belirtilmedi',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          Icons.calendar_month_outlined,
                          'SÜLÜS TARİHİ',
                          _formatDate(_sulusTarihi),
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          Icons.verified_user_outlined,
                          'TERHİS TARİHİ',
                          _formatDate(_terhisTarihi),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    final bool isDark = !_isDefaultTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _getTextColor(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _getSubtitleColor().withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildIDCard(),
            const SizedBox(height: 8),

            _buildSectionHeader('Hesap & Ayarlar'),
            _buildListTile(
              icon: Icons.edit_note,
              title: 'Bilgileri Güncelle',
              iconColor: Colors.blue,
              onTap: () async {
                await Navigator.of(context).push(_customPageRoute(UserInputPage()));
                _loadProfileData();
              },
            ),
            _buildListTile(
              icon: Icons.palette_outlined,
              title: 'Arka Plan Değiştir',
              iconColor: Colors.purple,
              onTap: () async {
                await Navigator.of(context).push(_customPageRoute(ThemePage()));
                _loadProfileData();
                AdManager().loadInterstitialAd();
              },
            ),


            _buildSectionHeader('Uygulama & Destek'),
            _buildListTile(
              icon: Icons.share_outlined,
              title: 'Uygulamayı Paylaş',
              iconColor: Colors.green,
              onTap: () {
                final String shareLink = Platform.isIOS
                    ? 'https://apps.apple.com/app/id6777999683'
                    : 'https://play.google.com/store/apps/details?id=com.bayesa.safaksayar';
                final box = context.findRenderObject() as RenderBox?;
                final Rect? sharePositionOrigin = box != null
                    ? box.localToGlobal(Offset.zero) & box.size
                    : null;
                Share.share(shareLink, sharePositionOrigin: sharePositionOrigin);
              },
            ),
            _buildListTile(
              icon: Icons.star_outline_rounded,
              title: 'Bizi Değerlendirin',
              iconColor: Colors.amber,
              onTap: () async {
                final InAppReview inAppReview = InAppReview.instance;
                try {
                  if (await inAppReview.isAvailable()) {
                    await inAppReview.requestReview();
                  } else {
                    await inAppReview.openStoreListing(
                      appStoreId: '6777999683',
                    );
                  }
                } catch (e) {
                  final String reviewUrl = Platform.isIOS
                      ? 'https://apps.apple.com/app/id6777999683?action=write-review'
                      : 'https://play.google.com/store/apps/details?id=com.bayesa.safaksayar';
                  final Uri reviewUri = Uri.parse(reviewUrl);
                  if (await canLaunchUrl(reviewUri)) {
                    await launchUrl(reviewUri, mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),

            _buildSectionHeader('Kurumsal & Bilgi'),
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Gizlilik Politikası',
              iconColor: Colors.teal,
              onTap: () {
                _showPolicyBottomSheet(
                  title: 'Gizlilik Politikası',
                  content: _privacyPolicyContent,
                  icon: Icons.privacy_tip_outlined,
                  accentColor: Colors.teal,
                );
              },
            ),
            _buildListTile(
              icon: Icons.description_outlined,
              title: 'Kullanım Şartları',
              iconColor: Colors.orange,
              onTap: () {
                _showPolicyBottomSheet(
                  title: 'Kullanım Şartları',
                  content: _termsOfUseContent,
                  icon: Icons.description_outlined,
                  accentColor: Colors.orange,
                );
              },
            ),
            _buildSectionHeader('Hesap Yönetimi'),
            _buildListTile(
              icon: Icons.delete_forever_outlined,
              title: 'Hesabımı Sil',
              iconColor: Colors.red,
              onTap: () async {
                await _deleteAccount();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hesabınızı Silmek İstiyor Musunuz?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Bu işlem geri alınamaz. Tüm yerel verileriniz temizlenecek ve hesabınız silinecektir.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
              child: const Text('Hesabı Sil'),
            ),
          ],
        );
      },
    ) ?? false;

    if (!confirm) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Geri tuşu ile kapatılmasını engelle
          child: Dialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                    strokeWidth: 3.5,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hesabınız Siliniyor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verileriniz temizleniyor, lütfen bekleyin...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user details before clearing them
      final String userId = prefs.getString('userId') ?? 'Bilinmiyor';
      final String name = prefs.getString('name') ?? '';
      final String surname = prefs.getString('surname') ?? '';
      final String askerlikYeri = prefs.getString('askerlik_yeri') ?? '';
      final String memleket = prefs.getString('memleket') ?? '';

      // Save delete log to Firestore under 'deleted_user'
      await FirebaseFirestore.instance.collection('deleted_user').doc(userId).set({
        'userId': userId,
        'name': name,
        'surname': surname,
        'askerlik_yeri': askerlikYeri,
        'memleket': memleket,
        'deleted_at': FieldValue.serverTimestamp(),
      });

      // Clear local SharedPreferences
      await prefs.clear();

      if (mounted) {
        // Pop loading dialog
        Navigator.of(context).pop();

        // Redirect to UserInputPage (information entry screen)
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const UserInputPage()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error deleting account: $e');
      if (mounted) {
        // Pop loading dialog
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hesap silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Özel sayfa geçişi için fonksiyon
  PageRouteBuilder _customPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Sağdan sola başlasın
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final bool isDark = !_isDefaultTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: _getCardColor(),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getBorderColor(), width: 1),
              boxShadow: _isDefaultTheme
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : (iconColor ?? Colors.blueAccent).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isDark ? Colors.white : (iconColor ?? Colors.blueAccent),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPolicyBottomSheet({
    required String title,
    required String content,
    required IconData icon,
    required Color accentColor,
  }) {
    final bool isDark = !_isDefaultTheme;
    final Color modalBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subtitleColor = isDark ? Colors.white70 : Colors.black54;
    final Color buttonColor = accentColor;

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Container(
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
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: buttonColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          icon,
                          color: buttonColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  height: 1,
                  thickness: 1,
                ),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        content.trim(),
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.6,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 24.0,
                    right: 24.0,
                    top: 16.0,
                    bottom: MediaQuery.of(context).padding.bottom + 16.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Okudum, Anladım',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const String _privacyPolicyContent = """
Bu Gizlilik Politikası, Hizmeti kullandığınızda bilgilerinizin toplanması, kullanılması ve ifşası ile ilgili politikalarımızı ve prosedürlerimizi açıklar ve Size gizlilik haklarınız ve yasaların Sizi nasıl koruduğunu anlatır.

Kişisel verilerinizi Hizmeti sağlamak ve geliştirmek için kullanıyoruz. Hizmeti kullanarak, bu Gizlilik Politikasına uygun olarak bilgilerin toplanmasını ve kullanılmasını kabul etmiş olursunuz. Bu Gizlilik Politikası, Ücretsiz Gizlilik Politikası Oluşturucunun yardımıyla oluşturulmuştur.

Yorumlama ve Tanımlar

Yorumlama

İlk harfi büyük harfle yazılmış olan kelimeler, aşağıdaki koşullar altında tanımlanmış anlamlara sahiptir. Aşağıdaki tanımlar, tekil veya çoğul olarak görünseler de aynı anlama sahip olacaktır.

Tanımlar

Bu Gizlilik Politikasının amaçları doğrultusunda:

Hesap, Hizmetimize veya Hizmetimizin bölümlerine erişmeniz için oluşturulan benzersiz bir hesap anlamına gelir.

Bağlı kuruluş, bir tarafı kontrol eden, bir taraf tarafından kontrol edilen veya bir tarafla ortak kontrol altında olan bir varlık anlamına gelir, burada "kontrol", hisselerin, özkaynak hisselerinin veya yöneticilerin veya diğer yönetim otoritelerinin seçimi için oy kullanma hakkına sahip diğer menkul kıymetlerin %50'sinin veya daha fazlasının mülkiyeti anlamına gelir.

Başvuru, Şirket tarafından sağlanan yazılım programı olan Şafak Sayar 2026'e atıfta bulunmaktadır.

Şirket (bu Sözleşmede "Şirket", "Biz", "Bize" veya "Bizim" olarak anılacaktır) Şafak Sayar 2026'i ifade eder.

Ülkeye atıfta bulunuyor: Türkiye

Cihaz, bilgisayar, cep telefonu veya dijital tablet gibi Hizmete erişebilen herhangi bir cihaz anlamına gelir.

Kişisel Veriler, tanımlanmış veya tanımlanabilir bir kişiyle ilgili herhangi bir bilgidir.

Hizmet, Uygulamayı ifade eder.

Hizmet Sağlayıcı, verileri Şirket adına işleyen herhangi bir gerçek veya tüzel kişi anlamına gelir. Hizmeti kolaylaştırmak, Şirket adına Hizmeti sağlamak, Hizmetle ilgili hizmetleri gerçekleştirmek veya Hizmetin nasıl kullanıldığını analiz etmede Şirkete yardımcı olmak için Şirket tarafından istihdam edilen üçüncü taraf şirketleri veya bireyleri ifade eder.

Kullanım Verileri, Hizmetin kullanımıyla veya Hizmet altyapısının kendisinden (örneğin, bir sayfa ziyaretinin süresi) oluşturulan otomatik olarak toplanan verileri ifade eder.

Hizmete erişen veya Hizmeti kullanan kişiyi veya bu kişinin adına Hizmete eriştiği veya Hizmeti kullandığı şirket veya diğer tüzel kişiyi kastediyorsunuz.

Kişisel Verilerinizin Toplama ve Kullanma

Toplanan Veri Türleri

Kişisel Veriler

Hizmetimizi kullanırken, Sizinle iletişim kurmak veya Sizi tanımlamak için kullanılabilecek belirli kişisel olarak tanımlanabilir bilgileri Bize sağlamanızı isteyebiliriz. Kişisel olarak tanımlanabilir bilgiler aşağıdakileri içerebilir, ancak bunlarla sınırlı değildir:

Ad ve soyadı

Kullanım Verileri

Kullanım Verileri

Kullanım Verileri, Hizmeti kullanırken otomatik olarak toplanır.

Kullanım Verileri, Cihazınızın İnternet Protokolü adresi gibi bilgileri içerebilir (örn. IP adresi), tarayıcı türü, tarayıcı sürümü, Hizmetimizin ziyaret ettiğiniz sayfaları, ziyaretinizin saati ve tarihi, bu sayfalarda geçirilen süre, benzersiz cihaz tanımlayıcıları ve diğer teşhis verileri.

Hizmete bir mobil cihaz aracılığıyla veya aracılığıyla eriştiğinizde, kullandığınız mobil cihazın türü, mobil cihazınızın benzersiz kimliği, mobil cihazınızın IP adresi, mobil işletim sisteminiz, kullandığınız mobil İnternet tarayıcısının türü, benzersiz cihaz tanımlayıcıları ve diğer tanılama verileri dahil ancak bunlarla sınırlı olmamak üzere belirli bilgileri otomatik olarak toplayabiliriz.

Hizmetimizi her ziyaret ettiğinizde veya Hizmete bir mobil cihaz üzerinden veya bir mobil cihaz aracılığıyla eriştiğinizde tarayıcınızın gönderdiği bilgileri de toplayabiliriz.

Kişisel Verilerinizin Kullanımı

Şirket, Kişisel Verileri aşağıdaki amaçlar için kullanabilir:

Hizmetimizin kullanımını izlemek de dahil olmak üzere Hizmetimizi sağlamak ve sürdürmek.

Hesabınızı yönetmek için: Hizmet kullanıcısı olarak kaydınızı yönetmek için. Sağladığınız Kişisel Veriler, kayıtlı bir kullanıcı olarak Size sunulan Hizmetin farklı işlevlerine erişmenizi sağlayabilir.

Bir sözleşmenin ifası için: Satın aldığınız ürünler, ürünler veya hizmetler için satın alma sözleşmesinin veya Hizmet aracılığıyla Bizimle yapılan başka herhangi bir sözleşmenin geliştirilmesi, uyumu ve üstlenilmesi.

Sizinle iletişim kurmak için: Bir mobil uygulamanın güncellemelerle ilgili anlık bildirimleri veya güvenlik güncellemeleri de dahil olmak üzere işlevler, ürünler veya sözleşmeli hizmetlerle ilgili bilgilendirici iletişimler gibi e-posta, telefon görüşmeleri, SMS veya diğer eşdeğer elektronik iletişim biçimleriyle sizinle iletişim kurmak için, bunların uygulanması için gerekli veya makul olduğunda.

Bu tür bilgileri almamayı tercih etmediğiniz sürece, daha önce satın aldığınız veya sorguladığınıza benzer sunduğumuz diğer maller, hizmetler ve etkinlikler hakkında Size haberler, özel teklifler ve genel bilgiler sağlamak.

İsteklerinizi yönetmek için: Bize olan isteklerinize katılmak ve yönetmek için.

İş transferleri için: Bilgilerinizi, Hizmet kullanıcılarımız hakkında tarafımızca tutulan Kişisel Verilerin devredilen varlıklar arasında olduğu, devam eden bir işletme olarak veya iflas, tasfiye veya benzer bir işlemin bir parçası olarak birleşme, elden çıkarma, yeniden yapılandırma, yeniden yapılanma, fesih veya varlıklarımızın bir kısmının veya tamamının başka bir satışını veya devrini değerlendirmek veya yürütmek için kullanabiliriz.

Diğer amaçlar için: Bilgilerinizi veri analizi, kullanım eğilimlerini belirleme, promosyon kampanyalarımızın etkinliğini belirleme ve Hizmetimizi, ürünlerimizi, hizmetlerimizi, pazarlamamızı ve deneyiminizi değerlendirmek ve geliştirmek gibi başka amaçlar için kullanabiliriz.

Kişisel bilgilerinizi aşağıdaki durumlarda paylaşabiliriz:

Hizmet Sağlayıcılarla: Hizmetimizin kullanımını izlemek ve analiz etmek, Sizinle iletişim kurmak için kiisel bilgilerinizi Hizmet Sağlayıcılarla paylaşabiliriz.
İş transferleri için: Kişisel bilgilerinizi, herhangi bir birleşme, Şirket varlıklarının satışı, finansman veya işimizin tamamının veya bir kısmının başka bir şirkete satın alınmasıyla bağlantılı olarak veya müzakereler sırasında paylaşabilir veya aktarabiliriz.
İştiraklerle: Bilgilerinizi iştiraklerimizle paylaşabiliriz, bu durumda bu bağlı kuruluşların bu Gizlilik Politikasına uymalarını isteyeceğiz. İştirakler, ana şirketimizi ve kontrol ettiğimiz veya Bizimle ortak kontrol altında olan diğer iştirakleri, ortak girişim ortaklarını veya diğer şirketleri içerir.
İş ortaklarımızla: Size belirli ürünler, hizmetler veya promosyonlar sunmak için bilgilerinizi iş ortaklarımızla paylaşabiliriz.
Diğer kullanıcılarla: Kişisel bilgileri paylaştığınızda veya kamuya açık alanlarda diğer kullanıcılarla başka bir şekilde etkileşimde bulunduğunuzda, bu tür bilgiler tüm kullanıcılar tarafından görüntülenebilir ve dışarıda herkese açık olarak dağıtılabilir.
İzninizle: Kişisel bilgilerinizi sizin izninizle başka herhangi bir amaç için ifşa edebiliriz.
Kişisel Verilerinizin Saklanması

Şirket, Kişisel Verileri yalnızca bu Gizlilik Politikasında belirtilen amaçlar için gerekli olduğu sürece saklayacaktır. Kişisel Verilerinizi yasal yükümlülüklerimize uymak için gerekli ölçüde saklayacak ve kullanacağız (örneğin, yürürlükteki yasalara uymak için verilerinizi saklamamız gerekiyorsa), anlaşmazlıkları çözeceğiz ve yasal anlaşmalarımızı ve politikalarımızı uygulayacağız.

Şirket ayrıca Kullanım Verilerini dahili analiz amacıyla saklayacaktır. Kullanım Verileri, bu verilerin Güvenliğini güçlendirmek veya Hizmetimizin işlevselliğini geliştirmek için kullanılması dışında genellikle daha kısa bir süre için saklanır veya bu verileri daha uzun süreler boyunca saklamakla yasal olarak yükümlüdür.

Kişisel Verilerinizin Aktarımı

Kişisel Veriler de dahil olmak üzere bilgileriniz, Şirketin işletme ofislerinde ve işlemeye dahil olan tarafların bulunduğu diğer yerlerde işlenir. Bu, bu bilgilerin, veri koruma yasalarının Sizin yargı bölgenizden farklı olabileceği eyaletinizin, ilinizin, ülkenizin veya diğer hükümet yargı yetkisinin dışında bulunan bilgisayarlara aktarılabileceği ve bu bilgisayarlarda tutulabileceği anlamına gelir.

Bu Gizlilik Politikasına onay vermeniz ve ardından bu tür bilgileri göndermeniz, bu aktarımı kabul ettiğinizi temsil eder.

Şirket, verilerinizin güvenli bir şekilde ve bu Gizlilik Politikasına uygun olarak işlenmesini sağlamak için makul olarak gerekli tüm adımları atacaktır ve verilerinizin ve diğer kişisel bilgilerinizin güvenliği de dahil olmak üzere yeterli kontroller olmadıkça Kişisel Verilerinizin bir kuruluşa veya ülkeye aktarılması gerçekleşmeyecektir.

Kişisel Verilerinizi Silin

Hakkınızda topladığımız Kişisel Verileri silme veya silinmesine yardımcı olmamızı talep etme hakkına sahipsiniz.

Hizmetimiz Size Hizmet içinden Sizinle ilgili belirli bilgileri silme olanağı verebilir.

Hesabınız varsa hesabınıza giriş yaparak ve kişisel bilgilerinizi yönetmenize olanak tanıyan hesap ayarları bölümünü ziyaret ederek bilgilerinizi istediğiniz zaman güncelleyebilir, değiştirebilir veya silebilirsiniz. Bize sağladığınız herhangi bir kişisel bilgiye erişim talebinde bulunmak, düzeltmek veya silmek için de Bizimle iletişime geçebilirsiniz.

Bununla birlikte, bunu yapmak için yasal bir yükümlülüğümüz veya yasal dayanağımız olduğunda belirli bilgileri saklamamız gerekebileceğini lütfen unutmayın.

Kişisel Verilerinizin Açıklanması

Ticari İşlemler

Şirket bir birleşme, satın alma veya varlık satışına dahil olursa, Kişisel Verileriniz aktarılabilir. Kişisel Verileriniz aktarılmadan ve farklı bir Gizlilik Politikasına tabi olmadan önce bildirimde bulunacağız.

Kolluk kuvvetleri

Belirli koşullar altında, yasalar gereği veya kamu makamlarının (örneğin bir mahkeme veya bir devlet kurumu) geçerli taleplerine yanıt olarak Şirket'in Kişisel Verilerinizi ifşa etmesi gerekebilir.

Diğer yasal gereklilikler

Şirket, Kişisel Verileri, bu tür bir eylemin aşağıdakiler için gerekli olduğuna iyi niyetle inanarak ifşa edebilir:

Yasal bir yükümlülüğe uymak
Şirketin haklarını veya mülkiyetini koruyun ve savunun
Hizmetle bağlantılı olarak olası yanlışları önlemek veya araştırmak
Hizmet Kullanıcılarının veya halkın kişisel güvenliğini koruyun
Yasal sorumluluğa karşı koruyun
Kişisel Verilerinizin Güvenliği

Kişisel Verilerinizin güvenliği Bizim için önemlidir, ancak İnternet üzerinden hiçbir iletim yönteminin veya elektronik depolama yönteminin %100 güvenli olmadığını unutmayın. Kişisel Verilerinizi korumak için ticari olarak kabul edilebilir araçlar kullanmaya çalışsak da, mutlak güvenliğini garanti edemeyiz.

Çocukların Gizliliği

Hizmetimiz 13 yaşın altındaki hiç kimseye hitap etmez. 13 yaşın altındaki hiç kimseden bilerek kişisel olarak tanımlanabilir bilgiler toplamıyoruz. Bir ebeveyn veya vasiyseniz ve çocuğunuzun Bize Kişisel Veriler sağladığının farkındaysanız, lütfen Bizimle iletişime geçin. Ebeveyn izninin doğrulanması olmadan 13 yaşın altındaki herhangi birinden Kişisel Veri topladığımızı fark edersek, bu bilgileri sunucularımızdan kaldırmak için adımlar atarız.

Bilgilerinizi işlemek için yasal bir dayanak olarak rızaya güvenmemiz gerekiyorsa ve ülkeniz bir ebeveynin iznini gerektiriyorsa, bu bilgileri toplamadan ve kullanmadan önce ebeveyninizin onayını isteyebiliriz.

Diğer Web Sitelerine Bağlantılar

Hizmetimiz, Bizim tarafımızdan işletilmeyen diğer web sitelerine bağlantılar içerebilir. Üçüncü taraf bağlantısına tıklarsanız, o üçüncü tarafın sitesine yönlendirileceksiniz. Ziyaret ettiğiniz her sitenin Gizlilik Politikasını gözden geçirmenizi şiddetle tavsiye ederiz.

Herhangi bir üçüncü taraf sitenin veya hizmetinin içeriği, gizlilik politikaları veya uygulamaları üzerinde hiçbir kontrolümüz yoktur ve bunlar için hiçbir sorumluluk kabul etmeziz.

Bu Gizlilik Politikasındaki Değişiklikler

Gizlilik Politikamızı zaman zaman güncelleyebiliriz. Yeni Gizlilik Politikasını bu sayfada yayınlayarak herhangi bir değişikliği Size bildireceğiz.

Değişiklik yürürlüğe girmeden önce e-posta ve/veya Hizmetimiz hakkında belirgin bir bildirim yoluyla size bildireceğiz ve bu Gizlilik Politikası'nın en üstündeki "Son güncelleme" tarihini güncelleyeceğiz.

Herhangi bir değişiklik için bu Gizlilik Politikasını düzenli olarak gözden geçirmeniz önerilir. Bu Gizlilik Politikalarındaki değişiklikler, bu sayfada yayınlandıklarında yürürlüğe girer.

Bize Ulaşın

Bu Gizlilik Politikası hakkında herhangi bir sorunuz varsa, bizimle iletişime geçebilirsiniz:

E-posta ile: bayesatechnology@gmail.com
""";

  static const String _termsOfUseContent = """
ŞAFAK SAYAR 2026 KULLANIM ŞARTLARI

1. Giriş

Şafak Sayar 2026 Mobil Uygulaması ("Uygulama") ve Şafak Sayar ("Web Sitesi") Şafak Sayar 2026 ("Şirket", "Biz") tarafından sağlanır ve işletilir. Uygulamamızı ve/veya Web Sitemizi kullanarak bu Kullanım Şartlarını kabul etmiş olursunuz.

2. Uygulamanın/Web Sitesinin Erişim ve Kullanımı

Uygulamaya/Web Sitesine erişim sağlamak için gerekli tüm düzenlemeleri yapma sorumluluğu size aittir. Uygulamayı/Web Sitesini ve Uygulamada/Web Sitesinde sunduğumuz herhangi bir hizmeti veya materyali tek taraflı olarak bildirimde bulunmaksızın çekme veya değiştirme hakkımızı saklı tutarız. Uygulamanın/Web Sitesinin herhangi bir sebep nedeniyle tamamen veya kısmen belirli bir süre veya sürekli olarak erişilemez olması durumunda hiçbir sorumluluğumuz bulunmamaktadır.

3. Fikri Mülkiyet Hakları

Uygulama ve Web Sitesindeki tüm fikri mülkiyet hakları ve bunlarda yayınlanan materyaller Şafak Sayar 2026 tarafından sahiplenilmektedir. Bu eserler dünya çapındaki telif hakkı yasaları ve antlaşmaları tarafından korunmaktadır. Tüm bu haklar saklıdır.

4. Satın Almalar

Uygulama/Web Sitesi üzerinden sunulan herhangi bir ürün veya hizmeti satın almak isterseniz, Satın Alma işlemine ilişkin belirli bilgileri sağlamanız istenebilir. Satın alma işlemleri Google Play veya App Store'un ödeme altyapısı aracılığıyla gerçekleştirilir.

5. Kullanım Şartlarında Değişiklikler

Bu Kullanım Şartlarını zaman zaman tek taraflı olarak gözden geçirebilir ve güncelleyebiliriz. Kullanım Şartlarının revize edilmiş hali yayınlandıktan sonra Uygulamayı/Web Sitesini kullanmaya devam etmeniz, değişiklikleri kabul ettiğiniz ve bunlara uyduğunuz anlamına gelir. Herhangi bir değişiklikten haberdar olmanız için bu sayfayı düzenli olarak kontrol etmeniz beklenir, çünkü bu değişiklikler size bağlayıcıdır.

6. Bize Ulaşın

Bu Şartlar hakkında herhangi bir sorunuz varsa, lütfen bize bayesatechnology@gmail.com adresinden ulaşın.

Son güncelleme: 20 Aralık 2025

Bu Kullanım Şartları, Şafak Sayar 2026 tarafından sağlanmıştır.
""";
}
