import 'package:flutter/material.dart';

class FaqItem {
  final String question;
  final String answer;
  final String category;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Hepsi';

  final List<String> _categories = [
    'Hepsi',
    'Genel',
    'Bedelli',
    'İzin & Yol',
    'Sağlık',
    'Malzemeler',
  ];

  final List<FaqItem> _faqList = const [
    FaqItem(
      category: 'Genel',
      question: 'Askerlik süresi ne kadardır?',
      answer:
          "Türkiye'de zorunlu (muvazzaf) askerlik süresi er ve erbaşlar için 6 aydır. Üniversitelerin 4 yıllık bölümlerinden mezun olanlar için yedek subay (12 ay), 2 yıllık yüksekokul mezunları için ise yedek astsubay (12 ay) alternatifleri mevcuttur. Tercih durumunuza ve TSK ihtiyaçlarına göre bu statülerde görev yapabilirsiniz.",
    ),
    FaqItem(
      category: 'Bedelli',
      question: 'Bedelli askerlik şartları nelerdir?',
      answer:
          "Bedelli askerlikten yararlanabilmek için 20 yaşını doldurmuş olmak (fiili askere alma yılına girmiş olmak), yoklama kaçağı veya bakaya durumuna düşmeden başvuru yapmak ve belirlenen bedel tutarını peşin olarak yatırmak gereklidir. Başvuru e-Devlet üzerinden veya Askerlik Şubelerinden yapılabilmektedir.",
    ),
    FaqItem(
      category: 'Bedelli',
      question: 'Bedelli askerlik süresi kaç gündür?',
      answer:
          "Bedelli askerlik hizmeti yasal olarak 1 ay sürer. Ancak sevk belgesinde yer alan yol izinleri (ikametgah ile birlik arasındaki mesafeye göre 1 veya 2 gün) bu süreden düşüldüğü için fiili askeri eğitim süresi genellikle 21 ile 28 gün arasında değişmektedir.",
    ),
    FaqItem(
      category: 'İzin & Yol',
      question: 'Askerlik yol parası (harcırah) nasıl hesaplanır ve nereden alınır?',
      answer:
          "Yol parası (harcırah), ikametgah adresiniz ile teslim olacağınız askeri birlik arasındaki Karayolları Genel Müdürlüğü mesafe verilerine göre hesaplanır. Yol harcırahı sevk tarihinizden 1-2 gün önce adınıza PTT'ye yatırılır. Herhangi bir PTT şubesinden T.C. kimlik kartınızla çekebileceğiniz gibi, e-Devlet'teki 'PTT Üzerinden Yapılan Kurum Ödemeleri' sekmesinden kendi adınıza kayıtlı bir banka hesabına da aktarabilirsiniz.",
    ),
    FaqItem(
      category: 'İzin & Yol',
      question: 'Askerde izin hakları kaç gündür?',
      answer:
          "6 aylık er ve erbaşlık süresince her ay için 1 gün olmak üzere toplam 6 gün kanuni (senelik) izin hakkınız bulunur. Eğer bu izni kullanmazsanız terhis tarihiniz 6 gün erkene çekilir (erken terhis). Ayrıca birinci derece yakınların vefatı, doğal afet veya evlilik gibi durumlarda komutanlığın onayı ile mazeret izinleri de verilebilir.",
    ),
    FaqItem(
      category: 'Genel',
      question: 'Askerlik tecil (erteleme) işlemleri nasıl yapılır?',
      answer:
          "Tecil işlemleri mezuniyet veya öğrencilik durumunuza göre e-Devlet 'Askerliğim' hizmetinden veya en yakın askerlik şubesinden yapılır. Lise mezunları mezuniyetten itibaren 3 yıl, ön lisans ve lisans mezunları ise 2 yıl süreyle askerliklerini erteleyebilirler. Yüksek lisans ve doktora öğrencileri için de okul kayıtlarıyla birlikte belirli yaş sınırlarına kadar erteleme hakları mevcuttur.",
    ),
    FaqItem(
      category: 'Genel',
      question: 'Celp dönemi ve sevk belgesi (Sülüs) nedir, nereden alınır?',
      answer:
          "Celp dönemi, askere alınacağınız yılı ve ayı ifade eder. Sevk belgesi (halk arasında sülüs), askeri birliğinize teslim olmanız gereken kesin tarihi, yol izin sürenizi ve yol paranızı gösteren resmi belgedir. Sevk tarihinden önceki birkaç gün içinde e-Devlet kapısı üzerinden kolayca indirilebilir. Sülüs belgesi alınmadan birliğe gidilmemelidir.",
    ),
    FaqItem(
      category: 'Sağlık',
      question: 'Askerlik için sağlık raporu nasıl alınır?',
      answer:
          "Askerlik yoklama işlemlerini başlatmak için e-Devlet üzerinden sağlık bilgi formunu doldurmanız gerekir. Form doldurulduktan sonra bağlı bulunduğunuz Aile Hekimine giderek muayene olmalısınız. Aile hekimi gerekli gördüğü durumlarda sizi devlet hastanelerine veya uzman hekimlere sevk edebilir. Rapor işlemleri onaylandığında sistemde güncellenir.",
    ),
    FaqItem(
      category: 'Sağlık',
      question: 'Askerde hangi aşılar yapılır ve zorunlu mudur?',
      answer:
          "Acemi birliğine katılış işlemlerinde toplu yaşam alanlarında oluşabilecek salgın hastalıkları engellemek amacıyla tüm askerlere Tetanoz aşısı ile KKK (Kızamık, Kızamıkçık, Kabakulak) aşıları uygulanır. Bu aşılar, askerlerin ve kışlanın genel sağlığını korumak adına TSK Sağlık Yeteneği Yönetmeliği kapsamında zorunludur.",
    ),
    FaqItem(
      category: 'Malzemeler',
      question: 'Askere giderken yanımıza neler almalıyız? TSK neleri veriyor?',
      answer:
          "Birlikte teslim olunduğunda TSK size kamuflaj, bot, şapka, iç çamaşırı, çorap, havlu takımı, spor ayakkabısı ve temel temizlik seti (diş fırçası, macun, sabun) sağlar. Ancak yanınızda ekstra olarak mevsimine göre haki/yeşil çorap, dikişsiz pamuklu iç çamaşırı, banyo terliği, nemlendirici kremler, iğne-iplik, törpüsüz tırnak makası, cüzdan (boyuna asılan) ve askeri kantinlerde alışveriş yapabilmek için temassız özelliği aktif bir banka kartı bulundurmanız oldukça faydalı olacaktır.",
    ),
    FaqItem(
      category: 'Genel',
      question: 'Askerde akıllı telefon kullanmak yasak mı? Askercell nedir?',
      answer:
          "Kışla sınırları içerisinde kameralı, internet bağlantılı ve akıllı telefonların kullanımı kesinlikle yasaktır. Sadece kamerasız, radyosuz ve internet bağlantısı olmayan tuşlu telefonlara izin verilir. Bu telefonlarda ise yalnızca TSK tarafından onaylanmış ve belirli saatlerde (mesai dışı saatler) aramaya açık olan 'Askercell' gibi askere özel mobil hatların kullanılması serbesttir.",
    ),
    FaqItem(
      category: 'Sağlık',
      question: 'Askerlikten muafiyet (Çürük Raporu) şartları nelerdir?',
      answer:
          "TSK Sağlık Yeteneği Yönetmeliği'ne göre askerlik görevini yapmaya engel teşkil eden bedensel (ciddi görme kusurları, ortopedik engeller, aşırı kilo-boy uyumsuzluğu vb.) veya psikolojik rahatsızlığı bulunan bireyler askerlikten muaf tutulurlar. Bu durum, askeri hastaneler veya tam teşekküllü devlet hastanelerindeki sağlık kurulları tarafından verilen resmi sağlık raporu ile kesinleşir.",
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqItem> get _filteredFaqList {
    return _faqList.where((item) {
      final matchesSearch = item.question
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Hepsi' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _clearSearchAndFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'Hepsi';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredFaqList;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Askerlik Bilgi Rehberi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade200,
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Arama Kutusu (Search Bar)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Soru veya cevap ara...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F3F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                ),
              ),
            ),
          ),

          // Kategori Çipleri (Category Chips)
          Container(
            height: 54,
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: Colors.blueAccent,
                    backgroundColor: const Color(0xFFF1F3F5),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),

          // Liste Görünümü (List View)
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return FaqCard(
                        key: ValueKey(item.question),
                        question: item.question,
                        answer: item.answer,
                        category: item.category,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.find_in_page_outlined,
              size: 72,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sonuç Bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Arama kriterlerinizle eşleşen bir soru bulunamadı. Lütfen kelimeleri kontrol edin veya filtreleri sıfırlayın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _clearSearchAndFilters,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Filtreleri Temizle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class FaqCard extends StatefulWidget {
  final String question;
  final String answer;
  final String category;

  const FaqCard({
    super.key,
    required this.question,
    required this.answer,
    required this.category,
  });

  @override
  State<FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<FaqCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onExpansionChanged(bool expanded) {
    setState(() {
      _isExpanded = expanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isExpanded ? Colors.blueAccent.withValues(alpha: 0.3) : const Color(0xFFE9ECEF),
          width: _isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.blueAccent.withValues(alpha: 0.02),
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          onExpansionChanged: _onExpansionChanged,
          title: Text(
            widget.question,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: _isExpanded ? Colors.blueAccent : Colors.black87,
            ),
          ),
          trailing: RotationTransition(
            turns: _iconRotation,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _isExpanded
                    ? Colors.blueAccent.withValues(alpha: 0.1)
                    : const Color(0xFFF1F3F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: _isExpanded ? Colors.blueAccent : Colors.grey.shade600,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: const Color(0xFFF1F3F5),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                  Text(
                    widget.answer,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.category,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
