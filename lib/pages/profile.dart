import 'package:flutter/material.dart';
import 'package:safaksayar/ads/ad_manager.dart';
import 'package:safaksayar/pages/theme_page.dart';
import 'package:safaksayar/pages/user_input_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _backgroundImage = 'assets/images/img0.png';
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
      _backgroundImage = prefs.getString('themeImage') ?? 'assets/images/img0.png';
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

  bool get _isDefaultTheme => _backgroundImage == 'assets/images/img0.png';

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
        return 'assets/images/Kara.png';
      case 'deniz':
        return 'assets/images/Deniz.png';
      case 'hava':
        return 'assets/images/Hava.png';
      case 'jandarma':
        return 'assets/images/Jandarma.png';
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

            _buildSectionHeader('Bulut Yedekleme (Firestore)'),
            _buildListTile(
              icon: Icons.cloud_upload_outlined,
              title: 'Profilimi Buluta Kaydet',
              iconColor: Colors.blue,
              onTap: () async {
                await _saveProfileToFirestore();
              },
            ),
            _buildListTile(
              icon: Icons.filter_1_rounded,
              title: 'Detayları Aç (Kullanıcı ID: 1)',
              iconColor: Colors.redAccent,
              onTap: () async {
                await _showFirestoreUserDetails("1");
              },
            ),

            _buildSectionHeader('Uygulama & Destek'),
            _buildListTile(
              icon: Icons.share_outlined,
              title: 'Uygulamayı Paylaş',
              iconColor: Colors.green,
              onTap: () {
                Share.share(
                    'https://play.google.com/store/apps/details?id=com.bayesa.safaksayar');
              },
            ),
            _buildListTile(
              icon: Icons.star_outline_rounded,
              title: 'Bizi Değerlendirin',
              iconColor: Colors.amber,
              onTap: () async {
                String appPackageName =
                    "com.bayesa.safaksayar"; // Uygulama paket adınız
                String reviewUrl =
                    "https://play.google.com/store/apps/details?id=$appPackageName";
                if (await canLaunch(reviewUrl)) {
                  await launch(reviewUrl);
                } else {
                  throw 'İnceleme sayfası açılamadı';
                }
              },
            ),

            _buildSectionHeader('Kurumsal & Bilgi'),
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Gizlilik Politikası',
              iconColor: Colors.teal,
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: true, // Tam ekran için gerekli
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext context) {
                    return FractionallySizedBox(
                      heightFactor:
                          0.5, // İstenirse yükseklik oranı ayarlanabilir
                      child: Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Gizlilik Politikası",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Text(
                                  """
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
              
              Kişisel Verilerinizi Toplama ve Kullanma
              
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
              
              Bu tür bilgileri almamayı tercih etmediğiniz sürece, daha önce satın aldığınız veya sorguladığınıza benzer sunduğumuz diğer mallar, hizmetler ve etkinlikler hakkında Size haberler, özel teklifler ve genel bilgiler sağlamak.
              
              İsteklerinizi yönetmek için: Bize olan isteklerinize katılmak ve yönetmek için.
              
              İş transferleri için: Bilgilerinizi, Hizmet kullanıcılarımız hakkında tarafımızca tutulan Kişisel Verilerin devredilen varlıklar arasında olduğu, devam eden bir işletme olarak veya iflas, tasfiye veya benzer bir işlemin bir parçası olarak birleşme, elden çıkarma, yeniden yapılandırma, yeniden yapılanma, fesih veya varlıklarımızın bir kısmının veya tamamının başka bir satışını veya devrini değerlendirmek veya yürütmek için kullanabiliriz.
              
              Diğer amaçlar için: Bilgilerinizi veri analizi, kullanım eğilimlerini belirleme, promosyon kampanyalarımızın etkinliğini belirleme ve Hizmetimizi, ürünlerimizi, hizmetlerimizi, pazarlamamızı ve deneyiminizi değerlendirmek ve geliştirmek gibi başka amaçlar için kullanabiliriz.
              
              Kişisel bilgilerinizi aşağıdaki durumlarda paylaşabiliriz:
              
              Hizmet Sağlayıcılarla: Hizmetimizin kullanımını izlemek ve analiz etmek, Sizinle iletişim kurmak için kişisel bilgilerinizi Hizmet Sağlayıcılarla paylaşabiliriz.
              İş transferleri için: Kişisel bilgilerinizi, herhangi bir birleşme, Şirket varlıklarının satışı, finansman veya işimizin tamamının veya bir kısmının başka bir şirkete satın alınmasıyla bağlantılı olarak veya müzakereler sırasında paylaşabilir veya aktarabiliriz.
              İştiraklerle: Bilgilerinizi iştiraklerimizle paylaşabiliriz, bu durumda bu bağlı kuruluşların bu Gizlilik Politikasına uymalarını isteyeceğiz. İştirakler, ana şirketimizi ve kontrol ettiğimiz veya Bizimle ortak kontrol altında olan diğer iştirakleri, ortak girişim ortaklarını veya diğer şirketleri içerir.
              İş ortaklarımızla: Size belirli ürünler, hizmetler veya promosyonlar sunmak için bilgilerinizi iş ortaklarımızla paylaşabiliriz.
              Diğer kullanıcılarla: Kişisel bilgileri paylaştığınızda veya kamuya açık alanlarda diğer kullanıcılarla başka bir şekilde etkileşimde bulunduğunuzda, bu tür bilgiler tüm kullanıcılar tarafından görüntülenebilir ve dışarıda herkese açık olarak dağıtılabilir.
              İzninizle: Kişisel bilgilerinizi sizin izninizle başka herhangi bir amaç için ifşa edebiliriz.
              Kişisel Verilerinizin Saklanması
              
              Şirket, Kişisel Verilerinizi yalnızca bu Gizlilik Politikasında belirtilen amaçlar için gerekli olduğu sürece saklayacaktır. Kişisel Verilerinizi yasal yükümlülüklerimize uymak için gerekli ölçüde saklayacak ve kullanacağız (örneğin, yürürlükteki yasalara uymak için verilerinizi saklamamız gerekiyorsa), anlaşmazlıkları çözeceğiz ve yasal anlaşmalarımızı ve politikalarımızı uygulayacağız.
              
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
              
              Şirket, Kişisel Verilerinizi, bu tür bir eylemin aşağıdakiler için gerekli olduğuna iyi niyetle inanarak ifşa edebilir:
              
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
              
              Değişiklik yürürlüğe girmeden önce e-posta ve/veya Hizmetimiz hakkında belirgin bir bildirim yoluyla size bildireceğiz ve bu Gizlilik Politikasının en üstündeki "Son güncelleme" tarihini güncelleyeceğiz.
              
              Herhangi bir değişiklik için bu Gizlilik Politikasını düzenli olarak gözden geçirmeniz önerilir. Bu Gizlilik Politikasındaki değişiklikler, bu sayfada yayınlandıklarında yürürlüğe girer.
              
              Bize Ulaşın
              
              Bu Gizlilik Politikası hakkında herhangi bir sorunuz varsa, bizimle iletişime geçebilirsiniz:
              
              E-posta ile: bayesatechnology@gmail.com
                                  """,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(
                                    context); // Bottom Sheet'i kapatır
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                minimumSize: Size(double.infinity,
                                    50), // Butonun genişliği ve yüksekliği
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      20), // Köşe kıvrımları
                                ),
                              ),
                              child: Text(
                                "Kapat",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            _buildListTile(
              icon: Icons.description_outlined,
              title: 'Kullanım Şartları',
              iconColor: Colors.orange,
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: true, // Tam ekran için gerekli
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext context) {
                    return Scrollbar(
                      child: FractionallySizedBox(
                        heightFactor:
                            0.5, // İstenirse yükseklik oranı ayarlanabilir
                        child: Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kullanım Şartları",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    """
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
                                    """,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                      context); // Bottom Sheet'i kapatır
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  minimumSize: Size(double.infinity,
                                      50), // Butonun genişliği ve yüksekliği
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        20), // Köşe kıvrımları
                                  ),
                                ),
                                child: Text(
                                  "Kapat",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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

  Future<void> _saveProfileToFirestore() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name') ?? '';
      final surname = prefs.getString('surname') ?? '';
      final askerlikYeri = prefs.getString('askerlik_yeri') ?? '';
      final memleket = prefs.getString('memleket') ?? '';
      final kuvvetKomutanligi = prefs.getString('kuvvet_komutanligi') ?? '';
      final sulusTarihi = prefs.getString('sulus_tarihi') ?? '';
      final duration = prefs.getInt('duration') ?? 6;
      final endDateStr = prefs.getString('end_date') ?? '';
      final rutbe = prefs.getString('rutbe') ?? '';
      final izin = prefs.getInt('izin') ?? 0;
      final ceza = prefs.getInt('ceza') ?? 0;
      final yolIzni = prefs.getString('yolIzni') ?? '';

      await FirebaseFirestore.instance.collection('users').doc('1').set({
        'name': name,
        'surname': surname,
        'askerlik_yeri': askerlikYeri,
        'memleket': memleket,
        'kuvvet_komutanligi': kuvvetKomutanligi,
        'sulus_tarihi': sulusTarihi,
        'duration': duration,
        'end_date': endDateStr,
        'rutbe': rutbe,
        'izin': izin,
        'ceza': ceza,
        'yolIzni': yolIzni,
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla buluta yedeklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedekleme başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showFirestoreUserDetails(String id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      if (mounted) {
        Navigator.pop(context); // Close loading
      }

      if (!doc.exists) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Kayıt Bulunamadı'),
              content: Text('Firestore üzerinde ID: $id olan bir kullanıcı bulunamadı. Lütfen önce profilinizi buluta kaydedin.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
        }
        return;
      }

      final data = doc.data()!;
      final name = data['name'] ?? '';
      final surname = data['surname'] ?? '';
      final askerlikYeri = data['askerlik_yeri'] ?? '';
      final memleket = data['memleket'] ?? '';
      final kuvvetKomutanligi = data['kuvvet_komutanligi'] ?? '';
      final sulusTarihi = data['sulus_tarihi'] ?? '';
      final terhisTarihi = data['end_date'] ?? '';
      final rutbe = data['rutbe'] ?? '';

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_done, color: Colors.green, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Kullanıcı Detayları (ID: $id)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),
                  _buildModalDetailRow('Ad Soyad', '${name.toUpperCase()} ${surname.toUpperCase()}'),
                  _buildModalDetailRow('Rütbe', rutbe.isNotEmpty ? rutbe.toUpperCase() : '-'),
                  _buildModalDetailRow('Kuvvet', kuvvetKomutanligi.isNotEmpty ? kuvvetKomutanligi.toUpperCase() : '-'),
                  _buildModalDetailRow('Görev Yeri', askerlikYeri.isNotEmpty ? askerlikYeri : '-'),
                  _buildModalDetailRow('Memleket', memleket.isNotEmpty ? memleket : '-'),
                  _buildModalDetailRow('Sülüs Tarihi', _formatDate(sulusTarihi)),
                  _buildModalDetailRow('Terhis Tarihi', _formatDate(terhisTarihi)),
                  const SizedBox(height: 15),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kapat'),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
