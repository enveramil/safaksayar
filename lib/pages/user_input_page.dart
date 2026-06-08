import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safaksayar/pages/home.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? yolIzni;
  int? yolIzniDisplay;
  int _currentStep = 0; // Çok adımlı form için adımlar

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

  Future<void> _showCupertinoDatePicker(BuildContext context) async {
    DateTime tempSelectedDate = _selectedDate ?? DateTime.now(); // Geçici tarih

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext builder) {
        return Container(
          height: 300,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // İptal
                      },
                      child: Text(
                        'İptal',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate =
                              tempSelectedDate; // Seçili olan tarihi ayarla
                        });
                        Navigator.of(context).pop(); // Onay
                      },
                      child: Text(
                        'Tamam',
                        style: TextStyle(color: Colors.blue, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempSelectedDate,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime(2100),
                  onDateTimeChanged: (DateTime date) {
                    tempSelectedDate = date; // Geçici tarihi güncelle
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
      yolIzni = prefs.getString('yolIzni');
      // Ensure this line retrieves the correct key
      selectedDuration = prefs.getInt('duration'); // Correct key name
      if (storedDate != null) {
        _selectedDate = DateTime.parse(storedDate);
      }
    });
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

// Verileri SharedPreferences'a kaydet
  Future<void> _saveData() async {
    DateTime endDate = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Calculate the end date by adding the selected duration (in months) to the selected sülüs date
    if (_selectedDate != null && selectedDuration != null) {
      if (yolIzni == '1 (Terhis)') {
        yolIzniDisplay = 0;
      } else if (yolIzni == '1+1 (İzin)') {
        yolIzniDisplay = 1;
      } else if (yolIzni == '2 (Terhis)') {
        yolIzniDisplay = -1;
      } else if (yolIzni == '2+2 (İzin)') {
        yolIzniDisplay = 1;
      } else if (yolIzni == '3 (Terhis)') {
        yolIzniDisplay = -2;
      } else if (yolIzni == '3+3 (İzin)') {
        yolIzniDisplay = 1;
      }
      // Toplam süreyi hesapla (izin ve ceza günleri eklenmiş)
      int izinGunu = int.tryParse(_izinController.text ?? '0') ??
          0; // Kullanılan izin günleri
      int cezaGunu =
          int.tryParse(_cezaController.text ?? '0') ?? 0; // Alınan ceza günleri

      if (selectedDuration == 1) {
        // Süreyi, izin ve ceza günlerini hesaba katarak bitiş tarihini hesapla
        endDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month + selectedDuration!,
          _selectedDate!.day +
              izinGunu +
              cezaGunu -
              yolIzniDisplay!, // İzin ve ceza günleri eklendi
        );
      } else if (selectedDuration == 6) {
        endDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month + selectedDuration!,
          _selectedDate!.day +
              izinGunu +
              cezaGunu -
              yolIzniDisplay! -
              5, // İzin ve ceza günleri eklendi
        );
      } else if (selectedDuration == 12) {
        endDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month + selectedDuration!,
          _selectedDate!.day +
              izinGunu +
              cezaGunu -
              yolIzniDisplay! -
              11, // İzin ve ceza günleri eklendi
        );
      }

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
      await prefs.setString('yolIzni', yolIzni ?? '');

      try {
        await FirebaseFirestore.instance.collection('users').doc('1').set({
          'name': _nameController.text,
          'surname': _surnameController.text,
          'askerlik_yeri': _selectedAskerlikYeri ?? '',
          'memleket': _selectedMemleket ?? '',
          'kuvvet_komutanligi': _selectedKuvvetKomutanligi ?? '',
          'sulus_tarihi': _selectedDate?.toIso8601String() ?? '',
          'duration': selectedDuration!,
          'end_date': endDate.toIso8601String(),
          'rutbe': rutbe ?? '',
          'izin': izinGunu ?? 0,
          'ceza': cezaGunu ?? 0,
          'yolIzni': yolIzni ?? '',
          'updated_at': FieldValue.serverTimestamp(),
        });
        print('User successfully saved to Firestore.');
      } catch (e) {
        print('Error saving user to Firestore: $e');
      }
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
      await Navigator.of(context).pushAndRemoveUntil(
        _customPageRoute(ManagePages()),
        (Route<dynamic> route) => false,
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
    _nameController.dispose();
    _surnameController.dispose();
    _izinController.dispose();
    _cezaController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen adınızı girin.')),
        );
        return;
      }
      if (_surnameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen soyadınızı girin.')),
        );
        return;
      }
      if (_selectedMemleket == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen memleketinizi seçin.')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedKuvvetKomutanligi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen Kuvvet Komutanlığını seçin.')),
        );
        return;
      }
      if (rutbe == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen rütbenizi seçin.')),
        );
        return;
      }
      if (_selectedAskerlikYeri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen görev yerinizi seçin.')),
        );
        return;
      }
      if (selectedDuration == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen askerlik sürenizi seçin.')),
        );
        return;
      }
    }
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _currentStep--;
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Navigator.canPop(context)
              ? GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                  ),
                )
              : const SizedBox(width: 38),
          const Text(
            'Kurulum Sihirbazı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: AssetImage('assets/images/app_logo.png'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Adım ${_currentStep + 1} / 3',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (index) {
              final bool isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == 2 ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Kişisel Profil';
      case 1:
        return 'Askerlik Bilgileri';
      case 2:
        return 'Tarih & İzinler';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0() {
    return Column(
      children: [
        const SizedBox(height: 12),
        buildTextField(
          controller: _nameController,
          label: 'Adınız',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _surnameController,
          label: 'Soyadınız',
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),
        buildDropdown(
          label: 'Memleket (İl)',
          value: _selectedMemleket,
          hint: 'Memleketinizi seçin',
          icon: Icons.home_outlined,
          items: iller,
          onChanged: (value) {
            setState(() {
              _selectedMemleket = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        const SizedBox(height: 12),
        buildDropdown(
          label: 'Kuvvet Komutanlığı',
          value: _selectedKuvvetKomutanligi,
          hint: 'Kuvvetinizi seçin',
          icon: Icons.military_tech_outlined,
          items: ['Hava', 'Deniz', 'Kara', 'Jandarma'],
          onChanged: (value) {
            setState(() {
              _selectedKuvvetKomutanligi = value;
            });
          },
        ),
        const SizedBox(height: 16),
        buildDropdown(
          label: 'Rütbe',
          value: rutbe,
          hint: 'Rütbenizi seçin',
          icon: Icons.shield_outlined,
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
        const SizedBox(height: 16),
        buildDropdown(
          label: 'Görev Yeri (İl)',
          value: _selectedAskerlikYeri,
          hint: 'Görev yerinizi seçin',
          icon: Icons.location_on_outlined,
          items: iller,
          onChanged: (value) {
            setState(() {
              _selectedAskerlikYeri = value;
            });
          },
        ),
        const SizedBox(height: 16),
        buildDropdown(
          label: 'Askerlik Süresi',
          value: selectedDuration == 1
              ? '$selectedDuration Ay(Bedelli)'
              : selectedDuration != null
                  ? '$selectedDuration Ay'
                  : null,
          hint: 'Askerlik sürenizi seçin',
          icon: Icons.schedule_outlined,
          items: [1, 6, 12]
              .map((e) => e == 1 ? '$e Ay(Bedelli)' : '$e Ay')
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedDuration = int.tryParse(value?.split(' ')[0] ?? '');
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildDatePicker(context),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: buildTextField(
                controller: _izinController,
                label: 'Kullanılan İzin',
                icon: Icons.flight_takeoff_outlined,
                inputType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildTextField(
                controller: _cezaController,
                label: 'Alınan Ceza',
                icon: Icons.gavel_outlined,
                inputType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        buildDropdown(
          label: 'Yol İzni (Gün)',
          value: yolIzni,
          hint: 'Yol izninizi seçin',
          icon: Icons.commute_outlined,
          items: [
            '1 (Terhis)',
            '1+1 (İzin)',
            '2 (Terhis)',
            '2+2 (İzin)',
            '3 (Terhis)',
            '3+3 (İzin)',
          ],
          onChanged: (value) {
            setState(() {
              yolIzni = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Geri',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentStep < 2 ? _nextStep : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shadowColor: Colors.blueAccent.withValues(alpha: 0.3),
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep < 2 ? 'Devam Et' : 'Kaydet ve Başlat',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _currentStep < 2
                      ? const Icon(Icons.arrow_forward, size: 18)
                      : Image.asset(
                          'assets/images/fast-forward.gif',
                          height: 20,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStepIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: _buildStepContent(),
                ),
              ),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCupertinoDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Colors.blueAccent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sülüs Tarihi',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedDate == null
                        ? 'Sülüs Tarihini Seçin'
                        : DateFormat('dd.MM.yyyy').format(_selectedDate!),
                    style: TextStyle(
                      fontSize: 15,
                      color: _selectedDate == null ? Colors.white.withValues(alpha: 0.3) : Colors.white,
                      fontWeight: _selectedDate == null ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 22),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
      ),
      style: const TextStyle(fontSize: 15, color: Colors.white),
    );
  }

  Widget buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String label,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(
        hint,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w500),
      ),
      icon: Icon(Icons.arrow_drop_down, color: Colors.white.withValues(alpha: 0.6)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 22),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.black, fontSize: 15),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      dropdownColor: Colors.white,
    );
  }
}
