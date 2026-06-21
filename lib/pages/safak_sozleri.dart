import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafakSozleri extends StatefulWidget {
  final String? backgroundImage;
  const SafakSozleri({super.key, this.backgroundImage});

  // Kartların verilerinin bulunduğu liste
  static const List<Map<String, dynamic>> cardData = [
    {
      'imageUrl': 'assets/images/soz1.webp',
      'title': 'Vedalar zor olsa da bazen gitmek gerekir.',
    },
    {
      'imageUrl': 'assets/images/soz2.webp',
      'title':
          'Eğer bir gün şafağım için doğacak güneş, dağdaki teröristin sırtını ısıtacaksa bırakın o güneş hiç doğmasın.',
    },
    {
      'imageUrl': 'assets/images/soz3.webp',
      'title': 'Ömründen gün gitmesini isteyen tek varlık askerdir paşam.',
    },
    {
      'imageUrl': 'assets/images/soz4.webp',
      'title':
          'İlk başlarda kaç gün kaldı yerine kaç gün geçti diye sayarsan senin için daha kolay olacaktır. Gel teskere gel, gönlümüz seninle.',
    },
    {
      'imageUrl': 'assets/images/soz5.webp',
      'title':
          'Ezanla geldik selayla gideriz. Bu vatan için kanımızı şerbet diye içeriz.',
    },
    {
      'imageUrl': 'assets/images/soz6.webp',
      'title':
          'Dağlara çizmişler resmimi, komando koymuşlar ismimi, belki bir gün geri dönemem diye göndermişler sana resmimi.',
    },
    {
      'imageUrl': 'assets/images/soz7.webp',
      'title':
          'Şafak ne kadar zengin olursa olsun, bir gün fakirleşmeye mahkûmdur.',
    },
    {
      'imageUrl': 'assets/images/soz8.webp',
      'title':
          'Yalnızlıklardan yoruldum usandım. Sensiz gecelerden sıkıldım bunaldım, sımsıkı saran ateşi gözlerim, o sımsıcak bakan gözleri özledim.',
    },
    {
      'imageUrl': 'assets/images/soz9.webp',
      'title':
          'Doğan her güneş gençliğimin kaybıysa, batan her güneş şafağımın kaybıdır.',
    },
    {
      'imageUrl': 'assets/images/soz10.webp',
      'title':
          'Bize Vatan delisi diyorlar, kafayı vatanla bozmuşsunuz diyorlar! Çok şükür kafamız bozuk, kanımız değil.',
    },
    {
      'imageUrl': 'assets/images/soz11.webp',
      'title': 'Bir insan günleri sayıyorsa ya mahkûmdur ya asker.',
    },
    {
      'imageUrl': 'assets/images/soz12.webp',
      'title':
          'Şafak sayar gelin evde, asker eşini hayal eder nöbetinde, biter bu hasret dayan askerim, bu vatan senin eserin.',
    },
    {
      'imageUrl': 'assets/images/soz13.webp',
      'title': 'Vatan bize, kozan size, kızlar Allah’ a emanet.',
    },
    {
      'imageUrl': 'assets/images/soz14.webp',
      'title':
          'Aradığınız kişiye şu anda ulaşılamıyor. Lütfen 460 gün sonra tekrar deneyiniz.',
    },
    {
      'imageUrl': 'assets/images/soz15.webp',
      'title': 'Hayat bir zulümse, vereyim ayarı gülümse be şafak.',
    },
    {
      'imageUrl': 'assets/images/soz16.webp',
      'title':
          'Biz denizci değiliz ki her limanda bir sevgilimiz olsun, biz komandoyuz dağlar sağ olsun!',
    },
    {
      'imageUrl': 'assets/images/soz17.webp',
      'title': 'Bizler Atatürk’ün askerleriyiz ayık olun. Vatan bize emanet…',
    },
    {
      'imageUrl': 'assets/images/soz18.webp',
      'title':
          'Koy ver derdin silinsin, yol ver öfken yorulsun sonra korkma göster gönlün görünsün, hoş gör ruhun sevinsin gel bu günün hakkını ver yarını yarın düşünsün.',
    },
    {
      'imageUrl': 'assets/images/soz19.webp',
      'title': 'Doğan güneş şafağım, batan güneş gençliğimdir.',
    },
    {
      'imageUrl': 'assets/images/soz20.webp',
      'title':
          'Aşkım yatağın, sevgim yorganın, yüreğim yastığın olsun. Asker ocağında rahat uyu bir tanem.',
    },
    {
      'imageUrl': 'assets/images/soz21.webp',
      'title':
          'Kapını çalar mazi, dalgınlıkla açarsın, arar gözlerin beni o günleri sorarsın. Pişmanlık sarar seni o günleri anlarsın oturup bu aşk için sende ağlarsın. Ama nafile.',
    },
    {
      'imageUrl': 'assets/images/soz22.webp',
      'title':
          'Bu ülke seninle gurur duyuyor! Vatani görevinde başarılar. Adam olmak adına son şansını da iyi değerIendirmeni dilerim.',
    },
    {
      'imageUrl': 'assets/images/soz23.webp',
      'title':
          'Yolun açık olsun Mehmedim! Ellerin tetikte, gözlerin kartal kadar keskin olsun. Yüreğin umutların solmasın.',
    },
    {
      'imageUrl': 'assets/images/soz24.webp',
      'title': 'Biz seve seve can veririz lakin bir karış toprak vermeyiz.',
    },
    {
      'imageUrl': 'assets/images/soz25.webp',
      'title':
          'Herkes bilsin ki; Çakalların hükmü KURT ayağa kalkana kadardır.',
    },
    {
      'imageUrl': 'assets/images/soz26.webp',
      'title':
          'Biz Türk Askerleri… Biz dost güven, düşmana korku salan yerlerin aslanı, göklerin kartalıyız.',
    },
    {
      'imageUrl': 'assets/images/soz27.webp',
      'title':
          'Kapımıza dayanıyorsa zulüm… Başka yol yok! Ya İstiklal Ya Ölüm!',
    },
    {
      'imageUrl': 'assets/images/soz28.webp',
      'title':
          'Çekildi mi kılıçlar Türk’ün gönlü hoşlanır. Kağanlığı kurmaya yeni baştan başlanır.',
    },
    {
      'imageUrl': 'assets/images/soz29.webp',
      'title':
          'Anam gibi yemek yapmasını da bilirim, babam gibi Vatanı korumayı da!',
    },
    {
      'imageUrl': 'assets/images/soz30.webp',
      'title':
          'Soran olursa Türkler geldi dersiniz… Hoş geldin diyene sahip çıkın, Neden geldiniz diyenin kafasına sıkın!',
    },
    {
      'imageUrl': 'assets/images/soz31.webp',
      'title':
          'Benim kazanmam önemli değil. Hepsinin kaybetmesi gerekir! Cengiz Han!',
    },
    {
      'imageUrl': 'assets/images/soz32.webp',
      'title': 'Siz belki çoksunuz ancak unutmayın ki biz TÜRK askeriyiz…',
    },
    {
      'imageUrl': 'assets/images/soz33.webp',
      'title':
          'Uğrunda ölmeyeceğin bayrağın gölgesine sığınma. Ya sahip ol, ya da defol!',
    },
    {
      'imageUrl': 'assets/images/soz34.webp',
      'title':
          'Şafak ne kadar zengin olursa olsun, bir gün fakirleşmeye mahkumdur.',
    },
    {
      'imageUrl': 'assets/images/soz35.webp',
      'title':
          'Ülkümüz göklerde dalgalanan sancak, Allah’ın huzurunda eğiliriz ancak.',
    },
    {
      'imageUrl': 'assets/images/soz36.webp',
      'title':
          'Bil ki kanım vatana toprak olur, bil ki ruhum cennete bekçi olur, Bil ki canım vatana feda olur.',
    },
    {
      'imageUrl': 'assets/images/soz37.webp',
      'title': 'Ağaç kırılır gövdesi kalır, Dedeniz Mehmet gider namı kalır.',
    },
    {
      'imageUrl': 'assets/images/soz38.webp',
      'title':
          'Öyle bir toplum var ki çığlık atsan duymayan öyle bir kalbim var ki kurşunlara doymayan.',
    },
    {
      'imageUrl': 'assets/images/soz39.webp',
      'title':
          'Doğan her güneş gençliğimin kaybıysa, batan her güneş şafağımın kaybıdır.',
    },
    {
      'imageUrl': 'assets/images/soz40.webp',
      'title':
          'Ezanla geldik salayla gideriz. Bu vatan için kanımızı şerbet diye içeriz.',
    },
    {
      'imageUrl': 'assets/images/soz41.webp',
      'title':
          'Dağların tepesine, eşkıyanın alnına, kızların kabine ölümsüz Mehmetçik yazacağım.',
    },
    {
      'imageUrl': 'assets/images/soz42.webp',
      'title':
          'Her erkek bir gün asker olacak fakat her asker bu vatanı koruyamayacak.',
    },
    {
      'imageUrl': 'assets/images/soz43.webp',
      'title':
          'Spora gidememekten yakınıyordun ya. Al işte spor senin ayağına geldi, iyi değerlendir.',
    },
    {
      'imageUrl': 'assets/images/soz44.webp',
      'title':
          'Her sabah mercimek yemeyi çatalla hoşaf içmeyi elbise yerine çuval giymeyi asker ol da gör arkadaş.',
    },
    {
      'imageUrl': 'assets/images/soz45.webp',
      'title': 'Hakkını helal et anam. Vatan için canımı vermeye gidiyorum.',
    },
    {
      'imageUrl': 'assets/images/soz46.webp',
      'title':
          'Onlar bayrakta al, yıldızlar da hilaller. Dönmeyeceklerini bilerek gidiyor. Arkaların da öksüz bırakarak.',
    },
    {
'imageUrl': 'assets/images/soz47.webp',
      'title': 'Vatan diye bir hastalığa tutulduk. Allah şifa mifa vermesin.',
    },
    {
      'imageUrl': 'assets/images/soz48.webp',
      'title': 'Bayram solmasın diyerek kanlarını döken koca yiğitler var.',
    },
    {
      'imageUrl': 'assets/images/soz49.webp',
      'title': 'Vatanımda gözün varsa eğer mezarın derin olur bunu unutma.',
    },
    {
      'imageUrl': 'assets/images/soz50.webp',
      'title':
          'Gece nöbetlerinde beni aklına getirmemeye çalış. Uyurken üstlerine yakalanmanı istemem.',
    },
  ];

  @override
  State<SafakSozleri> createState() => _SafakSozleriState();
}

class _SafakSozleriState extends State<SafakSozleri> {
  late String _backgroundImage;

  @override
  void initState() {
    super.initState();
    _backgroundImage = widget.backgroundImage ?? 'assets/images/img0.webp';
    if (widget.backgroundImage == null) {
      _loadTheme();
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('themeImage') ?? 'assets/images/img0.webp';
    if (mounted) {
      setState(() {
        _backgroundImage = imagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDefaultBg = _backgroundImage == 'assets/images/img0.webp';
    final Color textColor = isDefaultBg ? Colors.black87 : Colors.white;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: isDefaultBg
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Şafak Sözleri',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: SafakSozleri.cardData.length,
          itemBuilder: (context, index) {
            final item = SafakSozleri.cardData[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: CustomCardWidget(
                imageUrl: item['imageUrl']!,
                title: item['title']!,
                index: index,
                totalCount: SafakSozleri.cardData.length,
                isDefaultBg: isDefaultBg,
              ),
            );
          },
        ),
      ),
    );
  }
}

class CustomCardWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final int index;
  final int totalCount;
  final bool isDefaultBg;

  const CustomCardWidget({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.index,
    required this.totalCount,
    required this.isDefaultBg,
  });

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDefaultBg
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.45);
    final Color borderColor = isDefaultBg
        ? Colors.grey.shade300.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.15);
    final Color textColor = isDefaultBg ? Colors.black87 : Colors.white;
    final Color subtitleColor = isDefaultBg ? Colors.black54 : Colors.white70;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDefaultBg ? 0.03 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soft framed image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imageUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: isDefaultBg
                            ? Colors.grey.shade200
                            : Colors.white.withValues(alpha: 0.05),
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: subtitleColor,
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Quote text with quotation icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.45,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDefaultBg
                      ? Colors.black.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.08),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 12),
                // Actions and Index
                Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.copy_rounded,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: title));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                const Text('Söz panoya kopyalandı!'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      backgroundColor: isDefaultBg
                          ? Colors.black.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.06),
                      iconColor: subtitleColor,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.share_rounded,
                      onTap: () {
                        final box = context.findRenderObject() as RenderBox?;
                        Rect? sharePositionOrigin;
                        if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
                          sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
                        } else {
                          final double screenWidth = MediaQuery.sizeOf(context).width;
                          final double screenHeight = MediaQuery.sizeOf(context).height;
                          sharePositionOrigin = Rect.fromLTWH(
                            screenWidth / 2 - 10,
                            screenHeight / 2 - 10,
                            20,
                            20,
                          );
                        }
                        Share.share(title, sharePositionOrigin: sharePositionOrigin);
                      },
                      backgroundColor: isDefaultBg
                          ? Colors.black.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.06),
                      iconColor: subtitleColor,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent,
                            Colors.red.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${index + 1} / $totalCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
