import 'package:flutter/material.dart';

class SafakSozleri extends StatelessWidget {
  const SafakSozleri({super.key});

  // Kartların verilerinin bulunduğu liste
  static const List<Map<String, dynamic>> cardData = [
    {
      'imageUrl': 'assets/images/soz1.png',
      'title': 'Vedalar zor olsa da bazen gitmek gerekir.',
    },
    {
      'imageUrl': 'assets/images/soz2.png',
      'title':
          'Eğer bir gün şafağım için doğacak güneş, dağdaki teröristin sırtını ısıtacaksa bırakın o güneş hiç doğmasın.',
    },
    {
      'imageUrl': 'assets/images/soz3.png',
      'title': 'Ömründen gün gitmesini isteyen tek varlık askerdir paşam.',
    },
    {
      'imageUrl': 'assets/images/soz4.png',
      'title':
          'İlk başlarda kaç gün kaldı yerine kaç gün geçti diye sayarsan senin için daha kolay olacaktır. Gel teskere gel, gönlümüz seninle.',
    },
    {
      'imageUrl': 'assets/images/soz5.png',
      'title':
          'Ezanla geldik selayla gideriz. Bu vatan için kanımızı şerbet diye içeriz.',
    },
    {
      'imageUrl': 'assets/images/soz6.png',
      'title':
      'Dağlara çizmişler resmimi, komando koymuşlar ismimi, belki bir gün geri dönemem diye göndermişler sana resmimi.',
    },
    {
      'imageUrl': 'assets/images/soz7.png',
      'title':
      'Şafak ne kadar zengin olursa olsun, bir gün fakirleşmeye mahkûmdur.',
    },
    {
      'imageUrl': 'assets/images/soz8.png',
      'title':
      'Yalnızlıklardan yoruldum usandım. Sensiz gecelerden sıkıldım bunaldım, sımsıkı saran ateşi gözlerim, o sımsıcak bakan gözleri özledim.',
    },
    {
      'imageUrl': 'assets/images/soz9.png',
      'title':
      'Doğan her güneş gençliğimin kaybıysa, batan her güneş şafağımın kaybıdır.',
    },
    {
      'imageUrl': 'assets/images/soz10.png',
      'title':
      'Bize Vatan delisi diyorlar, kafayı vatanla bozmuşsunuz diyorlar! Çok şükür kafamız bozuk, kanımız değil.',
    },
    {
      'imageUrl': 'assets/images/soz11.png',
      'title':
      'Bir insan günleri sayıyorsa ya mahkûmdur ya asker.',
    },
    {
      'imageUrl': 'assets/images/soz12.png',
      'title':
      'Şafak sayar gelin evde, asker eşini hayal eder nöbetinde, biter bu hasret dayan askerim, bu vatan senin eserin.',
    },
    {
      'imageUrl': 'assets/images/soz13.png',
      'title':
      'Vatan bize, kozan size, kızlar Allah’ a emanet.',
    },
    {
      'imageUrl': 'assets/images/soz14.png',
      'title':
      'Aradığınız kişiye şu anda ulaşılamıyor. Lütfen 460 gün sonra tekrar deneyiniz.',
    },
    {
      'imageUrl': 'assets/images/soz15.png',
      'title':
      'Hayat bir zulümse, vereyim ayarı gülümse be şafak.',
    },
    {
      'imageUrl': 'assets/images/soz16.png',
      'title':
      'Biz denizci değiliz ki her limanda bir sevgilimiz olsun, biz komandoyuz dağlar sağ olsun!',
    },
    {
      'imageUrl': 'assets/images/soz17.png',
      'title':
      'Bizler Atatürk’ün askerleriyiz ayık olun. Vatan bize emanet…',
    },
    {
      'imageUrl': 'assets/images/soz18.png',
      'title':
      'Koy ver derdin silinsin, yol ver öfken yorulsun sonra korkma göster gönlün görünsün, hoş gör ruhun sevinsin gel bu günün hakkını ver yarını yarın düşünsün.',
    },
    {
      'imageUrl': 'assets/images/soz19.png',
      'title':
      'Doğan güneş şafağım, batan güneş gençliğimdir.',
    },
    {
      'imageUrl': 'assets/images/soz20.png',
      'title':
      'Aşkım yatağın, sevgim yorganın, yüreğim yastığın olsun. Asker ocağında rahat uyu bir tanem.',
    },
    {
      'imageUrl': 'assets/images/soz21.png',
      'title':
      'Kapını çalar mazi, dalgınlıkla açarsın, arar gözlerin beni o günleri sorarsın. Pişmanlık sarar seni o günleri anlarsın oturup bu aşk için sende ağlarsın. Ama nafile.',
    },
    {
      'imageUrl': 'assets/images/soz22.png',
      'title':
      'Bu ülke seninle gurur duyuyor! Vatani görevinde başarılar. Adam olmak adına son şansını da iyi değerIendirmeni dilerim.',
    },
    {
      'imageUrl': 'assets/images/soz23.png',
      'title':
      'Yolun açık olsun Mehmedim! Ellerin tetikte, gözlerin kartal kadar keskin olsun. Yüreğin umutların solmasın.',
    },
    {
      'imageUrl': 'assets/images/soz24.png',
      'title':
      'Biz seve seve can veririz lakin bir karış toprak vermeyiz.',
    },
    {
      'imageUrl': 'assets/images/soz25.png',
      'title':
      'Herkes bilsin ki; Çakalların hükmü KURT ayağa kalkana kadardır.',
    },
    {
      'imageUrl': 'assets/images/soz26.png',
      'title':
      'Biz Türk Askerleri… Biz dost güven, düşmana korku salan yerlerin aslanı, göklerin kartalıyız.',
    },
    {
      'imageUrl': 'assets/images/soz27.png',
      'title':
      'Kapımıza dayanıyorsa zulüm… Başka yol yok! Ya İstiklal Ya Ölüm!',
    },
    {
      'imageUrl': 'assets/images/soz28.png',
      'title':
      'Çekildi mi kılıçlar Türk’ün gönlü hoşlanır. Kağanlığı kurmaya yeni baştan başlanır.',
    },
    {
      'imageUrl': 'assets/images/soz29.png',
      'title':
      'Anam gibi yemek yapmasını da bilirim, babam gibi Vatanı korumayı da!',
    },
    {
      'imageUrl': 'assets/images/soz30.png',
      'title':
      'Soran olursa Türkler geldi dersiniz… Hoş geldin diyene sahip çıkın, Neden geldiniz diyenin kafasına sıkın!',
    },
    {
      'imageUrl': 'assets/images/soz31.png',
      'title':
      'Benim kazanmam önemli değil. Hepsinin kaybetmesi gerekir! Cengiz Han!',
    },
    {
      'imageUrl': 'assets/images/soz32.png',
      'title':
      'Siz belki çoksunuz ancak unutmayın ki biz TÜRK askeriyiz…',
    },
    {
      'imageUrl': 'assets/images/soz33.png',
      'title':
      'Uğrunda ölmeyeceğin bayrağın gölgesine sığınma. Ya sahip ol, ya da defol!',
    },
    {
      'imageUrl': 'assets/images/soz34.png',
      'title':
      'Şafak ne kadar zengin olursa olsun, bir gün fakirleşmeye mahkumdur.',
    },
    {
      'imageUrl': 'assets/images/soz35.png',
      'title':
      'Ülkümüz göklerde dalgalanan sancak, Allah’ın huzurunda eğiliriz ancak.',
    },
    {
      'imageUrl': 'assets/images/soz36.png',
      'title':
      'Bil ki kanım vatana toprak olur, bil ki ruhum cennete bekçi olur, Bil ki canım vatana feda olur.',
    },
    {
      'imageUrl': 'assets/images/soz37.png',
      'title':
      'Ağaç kırılır gövdesi kalır, Dedeniz Mehmet gider namı kalır.',
    },
    {
      'imageUrl': 'assets/images/soz38.png',
      'title':
      'Öyle bir toplum var ki çığlık atsan duymayan öyle bir kalbim var ki kurşunlara doymayan.',
    },
    {
      'imageUrl': 'assets/images/soz39.png',
      'title':
      'Doğan her güneş gençliğimin kaybıysa, batan her güneş şafağımın kaybıdır.',
    },
    {
      'imageUrl': 'assets/images/soz40.png',
      'title':
      'Ezanla geldik salayla gideriz. Bu vatan için kanımızı şerbet diye içeriz.',
    },
    {
      'imageUrl': 'assets/images/soz41.png',
      'title':
      'Dağların tepesine, eşkıyanın alnına, kızların kabine ölümsüz Mehmetçik yazacağım.',
    },
    {
      'imageUrl': 'assets/images/soz42.png',
      'title':
      'Her erkek bir gün asker olacak fakat her asker bu vatanı koruyamayacak.',
    },
    {
      'imageUrl': 'assets/images/soz43.png',
      'title':
      'Spora gidememekten yakınıyordun ya. Al işte spor senin ayağına geldi, iyi değerlendir.',
    },
    {
      'imageUrl': 'assets/images/soz44.png',
      'title':
      'Her sabah mercimek yemeyi çatalla hoşaf içmeyi elbise yerine çuval giymeyi asker ol da gör arkadaş.',
    },
    {
      'imageUrl': 'assets/images/soz45.png',
      'title':
      'Hakkını helal et anam. Vatan için canımı vermeye gidiyorum.',
    },
    {
      'imageUrl': 'assets/images/soz46.png',
      'title':
      'Onlar bayrakta al, yıldızlar da hilaller. Dönmeyeceklerini bilerek gidiyor. Arkaların da öksüz bırakarak.',
    },
    {
      'imageUrl': 'assets/images/soz47.png',
      'title':
      'Vatan diye bir hastalığa tutulduk. Allah şifa mifa vermesin.',
    },
    {
      'imageUrl': 'assets/images/soz48.png',
      'title':
      'Bayram solmasın diyerek kanlarını döken koca yiğitler var.',
    },
    {
      'imageUrl': 'assets/images/soz49.png',
      'title':
      'Vatanımda gözün varsa eğer mezarın derin olur bunu unutma.',
    },
    {
      'imageUrl': 'assets/images/soz50.png',
      'title':
      'Gece nöbetlerinde beni aklına getirmemeye çalış. Uyurken üstlerine yakalanmanı istemem.',
    },




  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Şafak Sözleri'),
      ),
      body: ListView.builder(
        itemCount: cardData.length,
        itemBuilder: (context, index) {
          // Her bir kart için veri alma
          final item = cardData[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomCardWidget(
              imageUrl: item['imageUrl']!,
              title: item['title']!,
              index: index, // Her kartın sırasını veriyoruz
            ),
          );
        },
      ),
    );
  }
}

// Kıvrımlı köşeyi oluşturmak için CustomClipper sınıfı
class CurvedCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 20, 0);
    path.quadraticBezierTo(
        size.width, 0, size.width, 20); // Sağ üst köşe kıvrımı
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(0, size.height, 20, size.height); // Alt köşe kıvrımı
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CustomCardWidget extends StatelessWidget {
  final String imageUrl;
  final String title;
  final int index; // Liste sırası için yeni parametre

  const CustomCardWidget({
    required this.imageUrl,
    required this.title,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(
                  imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Kıvrımlı arka planı ve sayıyı sağ üst köşeye ekleme
        Positioned(
          top: 0,
          right: 0,
          child: ClipPath(
            clipper:
                CurvedCornerClipper(), // Kıvrımlı arka planı oluşturmak için
            child: Container(
              width: 80,
              height: 80,
              color: Colors.red,
              child: Center(
                child: Text(
                  (index + 1)
                      .toString(), // Liste sırasını 1'den başlatarak göster
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
