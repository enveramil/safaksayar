import 'package:flutter/material.dart';
import 'package:safaksayar/pages/info.dart';
import 'package:safaksayar/pages/theme_page.dart';
import 'package:safaksayar/pages/user_input_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _backgroundImage = 'assets/images/default.png';

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    final newThemeImage =
        prefs.getString('themeImage') ?? 'assets/images/default.png';
    setState(() {
      _backgroundImage = newThemeImage;
    });
  }

  Color _getTextColor() {
    return _backgroundImage == 'assets/images/default.png'
        ? Colors.black
        : Colors.white;
  }

  Future<void> _navigateToThemePage() async {
    final selectedImage = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ThemePage()),
    );

    if (selectedImage != null && selectedImage != _backgroundImage) {
      setState(() {
        _backgroundImage = selectedImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(75),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.7),
                  spreadRadius: 6,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 15),
          Text(
            'ŞAFAK SAYAR - 2025',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
            ),
          ),

          const SizedBox(height: 30),

          // Kullanıcı aksiyonları
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ListView(
                children: [
                  _buildListTile(
                    icon: Icons.edit,
                    title: 'Bilgileri Güncelle',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UserInputPage()),
                      );
                    },
                  ),
                  _buildListTile(
                    icon: Icons.share,
                    title: 'Uygulamayı Paylaş',
                    onTap: () {
                      Share.share(
                          'Bu harika uygulamayı dene: https://safaksayar.com');
                    },
                  ),
                  _buildListTile(
                    icon: Icons.palette,
                    title: 'Arka Plan Değiştir',
                    onTap: () {
                      _navigateToThemePage();
                    },
                  ),
                  _buildListTile(
                    icon: Icons.privacy_tip,
                    title: 'Gizlilik Politikası',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, // Tam ekran için gerekli
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (BuildContext context) {
                          return FractionallySizedBox(
                            heightFactor:
                                0.8, // İstenirse yükseklik oranı ayarlanabilir
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

Başvuru, Şirket tarafından sağlanan yazılım programı olan Şafak Sayar 2025'e atıfta bulunmaktadır.

Şirket (bu Sözleşmede "Şirket", "Biz", "Bize" veya "Bizim" olarak anılacaktır) Şafak Sayar 2025'i ifade eder.

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
                    icon: Icons.rule,
                    title: 'Kullanım Şartları',
                    onTap: () {
                      showModalBottomSheet(
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
ŞAFAK SAYAR 2025 KULLANIM ŞARTLARI
                            
1. Giriş
                            
Şafak Sayar 2025 Mobil Uygulaması ("Uygulama") ve Şafak Sayar ("Web Sitesi") Şafak Sayar 2025 ("Şirket", "Biz") tarafından sağlanır ve işletilir. Uygulamamızı ve/veya Web Sitemizi kullanarak bu Kullanım Şartlarını kabul etmiş olursunuz.
                            
2. Uygulamanın/Web Sitesinin Erişim ve Kullanımı
                            
Uygulamaya/Web Sitesine erişim sağlamak için gerekli tüm düzenlemeleri yapma sorumluluğu size aittir. Uygulamayı/Web Sitesini ve Uygulamada/Web Sitesinde sunduğumuz herhangi bir hizmeti veya materyali tek taraflı olarak bildirimde bulunmaksızın çekme veya değiştirme hakkımızı saklı tutarız. Uygulamanın/Web Sitesinin herhangi bir sebep nedeniyle tamamen veya kısmen belirli bir süre veya sürekli olarak erişilemez olması durumunda hiçbir sorumluluğumuz bulunmamaktadır.
                            
3. Fikri Mülkiyet Hakları
                            
Uygulama ve Web Sitesindeki tüm fikri mülkiyet hakları ve bunlarda yayınlanan materyaller Şafak Sayar 2025 tarafından sahiplenilmektedir. Bu eserler dünya çapındaki telif hakkı yasaları ve antlaşmaları tarafından korunmaktadır. Tüm bu haklar saklıdır.
                            
4. Satın Almalar
                            
Uygulama/Web Sitesi üzerinden sunulan herhangi bir ürün veya hizmeti satın almak isterseniz, Satın Alma işlemine ilişkin belirli bilgileri sağlamanız istenebilir. Satın alma işlemleri Google Play veya App Store'un ödeme altyapısı aracılığıyla gerçekleştirilir.
                            
5. Kullanım Şartlarında Değişiklikler
                            
Bu Kullanım Şartlarını zaman zaman tek taraflı olarak gözden geçirebilir ve güncelleyebiliriz. Kullanım Şartlarının revize edilmiş hali yayınlandıktan sonra Uygulamayı/Web Sitesini kullanmaya devam etmeniz, değişiklikleri kabul ettiğiniz ve bunlara uyduğunuz anlamına gelir. Herhangi bir değişiklikten haberdar olmanız için bu sayfayı düzenli olarak kontrol etmeniz beklenir, çünkü bu değişiklikler size bağlayıcıdır.
                            
6. Bize Ulaşın
                            
Bu Şartlar hakkında herhangi bir sorunuz varsa, lütfen bize bayesatechnology@gmail.com adresinden ulaşın.
                            
Son güncelleme: 20 Aralık 2025
                            
Bu Kullanım Şartları, Şafak Sayar 2025 tarafından sağlanmıştır.
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(
          title,
          style: TextStyle(color: _getTextColor(), fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
        tileColor: Colors.blueAccent.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 16, color: _getTextColor()),
      ),
    );
  }
}
