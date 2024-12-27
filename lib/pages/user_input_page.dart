import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safaksayar/pages/home.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInputPage extends StatefulWidget {
  const UserInputPage({super.key});

  @override
  State<UserInputPage> createState() => _UserInputPageState();
}

class _UserInputPageState extends State<UserInputPage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  DateTime? _selectedDate;
  int? selectedDuration;
  String? _selectedAskerlikYeri;
  String? _selectedMemleket;
  String? _selectedKuvvetKomutanligi; // Kuvvet komutanlığı için değişken
  String? rutbe;
  final _izinController = TextEditingController();
  final _cezaController = TextEditingController();

  // Türkiye'nin 81 ili
  final List<String> iller = [
    "Adana",
    "Adıyaman",
    "Afyon",
    "Ağrı",
    "Aksaray",
    "Amasya",
    "Ankara",
    "Antalya",
    "Ardahan",
    "Artvin",
    "Aydın",
    "Balıkesir",
    "Bartın",
    "Batman",
    "Bayburt",
    "Bilecik",
    "Bingöl",
    "Bitlis",
    "Bolu",
    "Burdur",
    "Bursa",
    "Çanakkale",
    "Çankırı",
    "Çorum",
    "Denizli",
    "Diyarbakır",
    "Düzce",
    "Edirne",
    "Elazığ",
    "Erzincan",
    "Erzurum",
    "Eskişehir",
    "Gaziantep",
    "Giresun",
    "Gümüşhane",
    "Hakkari",
    "Hatay",
    "Iğdır",
    "Isparta",
    "İstanbul",
    "İzmir",
    "Kahramanmaraş",
    "Karabük",
    "Karaman",
    "Kars",
    "Kastamonu",
    "Kayseri",
    "Kırıkkale",
    "Kırklareli",
    "Kırşehir",
    "Kilis",
    "Kocaeli",
    "Konya",
    "Kütahya",
    "Malatya",
    "Manisa",
    "Mardin",
    "Mersin",
    "Muğla",
    "Muş",
    "Nevşehir",
    "Niğde",
    "Ordu",
    "Osmaniye",
    "Rize",
    "Sakarya",
    "Samsun",
    "Siirt",
    "Sinop",
    "Sivas",
    "Şanlıurfa",
    "Şırnak",
    "Tekirdağ",
    "Tokat",
    "Trabzon",
    "Tunceli",
    "Uşak",
    "Van",
    "Yalova",
    "Yozgat",
    "Zonguldak"
  ];

  @override
  void initState() {
    super.initState();
    _loadData(); // Sayfa yüklendiğinde kayıtlı verileri çek
  }

  // Tarih seçici
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime
              .now(), // Eğer daha önce tarih seçilmişse initialDate olarak gösterilir
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _surnameController.text = prefs.getString('surname') ?? '';
      _selectedAskerlikYeri = prefs.getString('askerlik_yeri');
      _selectedMemleket = prefs.getString('memleket');
      _selectedKuvvetKomutanligi =
          prefs.getString('kuvvet_komutanligi'); // Yeni eklenen alan
      String? storedDate = prefs.getString('sulus_tarihi');
      rutbe = prefs.getString('rutbe');
      _izinController.text =
          prefs.getInt('izin')?.toString() ?? '0'; // Load izin
      _cezaController.text =
          prefs.getInt('ceza')?.toString() ?? '0'; // Load ceza
      // Ensure this line retrieves the correct key
      selectedDuration = prefs.getInt('duration'); // Correct key name
      if (storedDate != null) {
        _selectedDate = DateTime.parse(storedDate);
      }
    });
  }

// Verileri SharedPreferences'a kaydet
  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Calculate the end date by adding the selected duration (in months) to the selected sülüs date
    if (_selectedDate != null && selectedDuration != null) {
      // Toplam süreyi hesapla (izin ve ceza günleri eklenmiş)
      int izinGunu = int.tryParse(_izinController.text ?? '0') ??
          0; // Kullanılan izin günleri
      int cezaGunu =
          int.tryParse(_cezaController.text ?? '0') ?? 0; // Alınan ceza günleri

      // Süreyi, izin ve ceza günlerini hesaba katarak bitiş tarihini hesapla
      DateTime endDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month + selectedDuration!,
        _selectedDate!.day +
            izinGunu +
            cezaGunu, // İzin ve ceza günleri eklendi
      );

      // Verileri kaydet
      await prefs.setString('name', _nameController.text);
      await prefs.setString('surname', _surnameController.text);
      await prefs.setString('askerlik_yeri', _selectedAskerlikYeri ?? '');
      await prefs.setString('memleket', _selectedMemleket ?? '');
      await prefs.setString(
          'kuvvet_komutanligi', _selectedKuvvetKomutanligi ?? '');
      await prefs.setString(
          'sulus_tarihi', _selectedDate?.toIso8601String() ?? '');
      await prefs.setInt('duration', selectedDuration!);

      // Güncellenmiş terhis tarihini kaydet
      await prefs.setString('end_date', endDate.toIso8601String());
      await prefs.setString('rutbe', rutbe ?? '');
      await prefs.setInt(
          'izin', izinGunu ?? 0); // Kullanılan izin günlerini kaydet
      await prefs.setInt('ceza', cezaGunu ?? 0); // Alınan ceza günlerini kaydet
    }
  }

  // Formu göndermek ve başka bir sayfaya yönlendirmek
  void _submitForm() async {
    if (_nameController.text.isNotEmpty &&
        _surnameController.text.isNotEmpty &&
        _selectedDate != null &&
        selectedDuration != null &&
        _selectedAskerlikYeri != null &&
        _selectedMemleket != null &&
        _selectedKuvvetKomutanligi != null &&
        rutbe != null) {
      await _saveData(); // Verileri kaydet

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ManagePages()),
      );
    } else {
      // Eksik alanlar varsa uyarı gösterebilirsin
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm alanları doldurunuz')),
      );
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text('Kullanıcı Veri Girişi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ad and Soyad
            buildTextField(controller: _nameController, label: 'Ad'),
            SizedBox(height: 12),
            buildTextField(controller: _surnameController, label: 'Soyad'),
            SizedBox(height: 12),
            // Tarih seçici
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                    color: Colors.blueAccent),
                child: Text(
                  _selectedDate == null
                      ? 'Sülüs Tarihini Seçin'
                      : 'Seçilen Tarih: ${DateFormat('dd.MM.yyyy').format(_selectedDate!)}',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 12),
            // Kullanılan İzin ve Alınan Ceza in one row
            Row(
              children: [
                Expanded(
                  child: buildTextField(
                    controller: _izinController,
                    label: 'Kullanılan İzin (gün)',
                    inputType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12), // Space between the fields
                Expanded(
                  child: buildTextField(
                    controller: _cezaController,
                    label: 'Alınan Ceza (gün)',
                    inputType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            buildDropdown(
              label: 'Askerlik Yeri',
              value: _selectedAskerlikYeri,
              hint: 'Askerlik Yeri Seçin',
              items: iller,
              onChanged: (value) {
                setState(() {
                  _selectedAskerlikYeri = value;
                });
              },
            ),
            SizedBox(height: 12),
            buildDropdown(
              label: 'Memleket',
              value: _selectedMemleket,
              hint: 'Memleket Seçin',
              items: iller,
              onChanged: (value) {
                setState(() {
                  _selectedMemleket = value;
                });
              },
            ),
            SizedBox(height: 12),
            buildDropdown(
              label: 'Kuvvet Komutanlığı',
              value: _selectedKuvvetKomutanligi,
              hint: 'Kuvvet Komutanlığı Seçin',
              items: ['Hava', 'Deniz', 'Kara', 'Jandarma'],
              onChanged: (value) {
                setState(() {
                  _selectedKuvvetKomutanligi = value;
                });
              },
            ),
            SizedBox(height: 12),
            buildDropdown(
              label: 'Rütbe',
              value: rutbe,
              hint: 'Rütbe Seçin',
              items: [
                'ER',
                'ONBAŞI',
                'ÇAVUŞ',
                'ASTÇAVUŞ',
                'ASTSUBAY',
                'ASTEĞMEN',
                'TEĞMEN'
              ],
              onChanged: (value) {
                setState(() {
                  rutbe = value;
                });
              },
            ),
            SizedBox(height: 12),
            buildDropdown(
              label: 'Askerlik Süresi',
              value: selectedDuration != null ? '$selectedDuration Ay' : null,
              hint: 'Süre Seç',
              items: [1, 6, 12].map((e) => '$e Ay').toList(),
              onChanged: (value) {
                setState(() {
                  selectedDuration = int.tryParse(value?.split(' ')[0] ?? '');
                });
              },
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blueAccent),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                elevation: MaterialStateProperty.all(8),
                shadowColor:
                    MaterialStateProperty.all(Colors.black.withOpacity(0.5)),
                padding: MaterialStateProperty.all(
                    EdgeInsets.symmetric(horizontal: 30, vertical: 10)),
                minimumSize: MaterialStateProperty.all(Size(150, 50)),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Keeps the button compact
                children: [
                  Text(
                    'Gönder',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8), // Space between text and GIF
                  Image.asset(
                    'assets/images/fast-forward.gif', // Replace with your GIF path
                    height: 42, // Adjust height to fit button
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[800], // Softer grey for label
          fontWeight: FontWeight.bold,
        ),
        hintText: 'Enter $label',
        hintStyle: TextStyle(color: Colors.grey[500]), // Subtle grey hint color
        prefixIcon:
            Icon(Icons.edit, color: Colors.grey[600]), // Neutral icon color
        filled: true,
        fillColor: Colors.grey[100], // Broken white background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No outline on unfocused
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 2.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
    );
  }

  Widget buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label, // Label parametresi
  }) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            height:
                56, // İki container'ın yüksekliğini eşitlemek için sabit bir yükseklik
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100], // Dropdown arka plan rengi
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.grey[300]!, width: 1.5), // Soft border color
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1), // Light shadow for depth
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Align(
              // Label'ı sola yaslamak için Align widget'ı
              alignment: Alignment.centerLeft, // Sola yaslamak için
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[800], // Label rengi
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8), // İki container arasında biraz boşluk
        Expanded(
          flex: 2,
          child: Container(
            height: 56, // Yüksekliği eşitlemek için
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100], // Dropdown arka plan rengi
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.grey[300]!, width: 1.5), // Soft border color
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1), // Light shadow for depth
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                hint: Text(
                  hint,
                  style: TextStyle(
                      color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                icon: Icon(Icons.arrow_drop_down,
                    color: Colors.grey[600]), // Neutral icon color
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                dropdownColor: Colors.grey[100], // Dropdown arka plan rengi
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
