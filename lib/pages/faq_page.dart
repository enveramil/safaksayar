import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  final List<Map<String, String>> faqList = [
    {'question': 'Askerlik de yemin töreni nedir?', 'answer': "Askerde yemin töreni, bir askerin, askeri görevini yerine getirirken, Türk Silahlı Kuvvetleri'ne (TSK) bağlılık ve sadakatini ifade ettiği bir törendir. Yemin töreni, askerlik görevine yeni başlayanlar için önemli bir ritüeldir ve genellikle askere alma eğitimlerinin sonunda yapılır.  Bu törende askerler, Türk milletine, Cumhuriyet'e ve Türk Silahlı Kuvvetleri'ne sadakatle hizmet etme sözü verirler. Yemin, Türk milletine ve devletine hizmet etmeyi, ulusal değerleri korumayı ve gerektiğinde canlarını feda etmeyi taahhüt eder. Yemin töreni, askerlik hayatının başlangıcını simgeler ve askerler için bir onur kaynağıdır."},
    {'question': 'Askerlik süresi ne kadar?', 'answer': 'Türkiye’de askerlik süresi: Er ve erbaşlar için 6 ay. Yedek subaylar için 12 ay.'},
    {'question': 'Bedelli askerlik şartları neler?', 'answer': 'Bedelli askerlik için 20 yaşını doldurmuş olmak, bedelli ücreti ödemek ve sağlık raporu almak gerekmektedir.'},
    {'question': 'Askerlik için sağlık raporu nasıl alınır?', 'answer': 'Sağlık raporu aile hekiminden alınabilir, daha sonra askere uygunluk durumuna göre rapor düzenlenir.'},
    {'question': 'Askerlik şubesi işlemleri nasıl yapılır?', 'answer': 'Askerlik şubesi işlemleri için E-Devlet üzerinden başvuru yapılabilir ya da şubeye giderek işlemler tamamlanabilir.'},
    {'question': 'Askerde izin hakkı var mı?', 'answer': 'Askerde izin hakkı, askerlik süresine ve birliğin politikasına bağlı olarak değişir. Genellikle yılda 30 güne kadar izin verilir.'},
    // Diğer sorular ve cevaplar buraya eklenebilir...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Askerlik FAQ'),
      ),
      body: ListView.builder(
        itemCount: faqList.length,
        itemBuilder: (context, index) {
          return ExpansionTile(
            title: Text(faqList[index]['question']!),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(faqList[index]['answer']!),
              ),
            ],
          );
        },
      ),
    );
  }
}
