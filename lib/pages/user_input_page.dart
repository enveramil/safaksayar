import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safaksayar/state_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:safaksayar/Services/soldier_match_service.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/Services/log_service.dart';
import 'package:safaksayar/Services/app_config_service.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:safaksayar/widgets/setup_ui.dart';

/// Sülüs bilgilerinden terhis tarihini hesaplar; eksik bilgi varsa null döner.
DateTime? calculateTerhisDate({
  required DateTime? sulusDate,
  required int? durationMonths,
  required String? yolIzni,
  required int izinGunu,
  required int cezaGunu,
}) {
  const yolIzniGunleri = {
    '1 (Terhis)': 0,
    '1+1 (İzin)': 1,
    '2 (Terhis)': -1,
    '2+2 (İzin)': 1,
    '3 (Terhis)': -2,
    '3+3 (İzin)': 1,
  };
  const sureDuzeltmeleri = {1: 0, 6: 5, 12: 11};

  final int? yolIzniGunu = yolIzniGunleri[yolIzni];
  final int? sureDuzeltmesi = sureDuzeltmeleri[durationMonths];
  if (sulusDate == null || yolIzniGunu == null || sureDuzeltmesi == null) return null;

  return DateTime(
    sulusDate.year,
    sulusDate.month + durationMonths!,
    sulusDate.day + izinGunu + cezaGunu - yolIzniGunu - sureDuzeltmesi,
  );
}

class UserInputPage extends StatefulWidget {
  final String? initialRole; // 'asker' or 'yakin'
  final String? initialRelationship; // 'es', 'aile', 'arkadas', 'diger'
  const UserInputPage({super.key, this.initialRole, this.initialRelationship});

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
  static const int _stepCount = 3;
  int _currentStep = 0; // Çok adımlı form için adımlar
  bool _isMovingForward = true;
  bool _showValidation = false;
  String _userRole = 'asker';
  String? _relationship;

  bool get _isRelative => _userRole == 'yakin';

  DateTime? get _calculatedEndDate => calculateTerhisDate(
        sulusDate: _selectedDate,
        durationMonths: selectedDuration,
        yolIzni: yolIzni,
        izinGunu: int.tryParse(_izinController.text) ?? 0,
        cezaGunu: int.tryParse(_cezaController.text) ?? 0,
      );

  String? _storedChoice(SharedPreferences prefs, String key) {
    final String? value = prefs.getString(key);
    return value == null || value.isEmpty ? null : value;
  }

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

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = widget.initialRole ?? prefs.getString('user_role') ?? 'asker';
      _relationship = widget.initialRelationship ?? prefs.getString('relationship');
      _nameController.text = prefs.getString('name') ?? '';
      _surnameController.text = prefs.getString('surname') ?? '';
      _selectedAskerlikYeri = _storedChoice(prefs, 'askerlik_yeri');
      _selectedMemleket = _storedChoice(prefs, 'memleket');
      _selectedKuvvetKomutanligi =
          _storedChoice(prefs, 'kuvvet_komutanligi'); // Yeni eklenen alan
      String? storedDate = prefs.getString('sulus_tarihi');
      rutbe = _storedChoice(prefs, 'rutbe');
      _izinController.text =
          prefs.getInt('izin')?.toString() ?? '0'; // Load izin
      _cezaController.text =
          prefs.getInt('ceza')?.toString() ?? '0'; // Load ceza
      yolIzni = _storedChoice(prefs, 'yolIzni');
      // Ensure this line retrieves the correct key
      selectedDuration = prefs.getInt('duration'); // Correct key name
      if (storedDate != null) {
        _selectedDate = DateTime.tryParse(storedDate);
      }
    });
  }

  /// Özel sayfa geçişi için fonksiyon
  PageRouteBuilder _customPageRoute(Widget page, String pageName) {
    return PageRouteBuilder(
      settings: RouteSettings(name: pageName),
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final DateTime? calculatedEndDate = _calculatedEndDate;

    if (calculatedEndDate != null) {
      final DateTime endDate = calculatedEndDate;
      int izinGunu = int.tryParse(_izinController.text) ?? 0; // Kullanılan izin günleri
      int cezaGunu = int.tryParse(_cezaController.text) ?? 0; // Alınan ceza günleri

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
      await prefs.setInt('izin', izinGunu); // Kullanılan izin günlerini kaydet
      await prefs.setInt('ceza', cezaGunu); // Alınan ceza günlerini kaydet
      await prefs.setString('yolIzni', yolIzni ?? '');

      // Rol ve yakınlık bilgisini kaydet
      await prefs.setString('user_role', _userRole);
      if (_relationship != null) {
        await prefs.setString('relationship', _relationship!);
      }

      // Get or create unique sequential userId
      String? userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) {
        try {
          final counterRef = FirebaseFirestore.instance.collection('counters').doc('users');
          userId = await FirebaseFirestore.instance.runTransaction((transaction) async {
            final counterDoc = await transaction.get(counterRef);
            int currentId = 0;
            if (counterDoc.exists) {
              currentId = counterDoc.data()?['currentId'] ?? 0;
            }
            int nextId = currentId + 1;
            transaction.set(counterRef, {'currentId': nextId});
            return nextId.toString();
          });
          await prefs.setString('userId', userId!);
        } catch (e) {
          print('Error generating user ID transaction: $e');
          // Fallback to timestamp if transaction fails
          userId = DateTime.now().millisecondsSinceEpoch.toString();
          await prefs.setString('userId', userId);
        }
      }

      if (userId.isNotEmpty) {
        LogService.instance.setUserId(userId);
        LogService.instance.setUserInfo(
          name: _nameController.text,
          surname: _surnameController.text,
          role: _userRole,
          rutbe: rutbe,
        );
      }

      // Generate or retrieve tracking code
      String trackingCode = prefs.getString('tracking_code') ?? '';
      if (trackingCode.isEmpty) {
        trackingCode = await SoldierMatchService.instance.generateOrGetTrackingCode();
        await prefs.setString('tracking_code', trackingCode);
      }

      final soldierDataMap = {
        'userId': userId,
        'tracking_code': trackingCode,
        'user_role': _userRole,
        'name': _nameController.text,
        'surname': _surnameController.text,
        'askerlik_yeri': _selectedAskerlikYeri ?? '',
        'memleket': _selectedMemleket ?? '',
        'kuvvet_komutanligi': _selectedKuvvetKomutanligi ?? '',
        'sulus_tarihi': _selectedDate?.toIso8601String() ?? '',
        'duration': selectedDuration!,
        'end_date': endDate.toIso8601String(),
        'rutbe': rutbe ?? '',
        'izin': izinGunu,
        'ceza': cezaGunu,
        'yolIzni': yolIzni ?? '',
        'updated_at': FieldValue.serverTimestamp(),
      };

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set(soldierDataMap, SetOptions(merge: true));
        print('User successfully saved to Firestore with ID: $userId');
      } catch (e) {
        print('Error saving user to Firestore: $e');
      }

      // Mevcut veya aktif aboneliği (users/{userId}.isPremium + RevenueCat) doğrula
      await RevenueCatService.instance.bindUser(userId);

      // Always publish to tracking_codes so relatives can find and follow
      await SoldierMatchService.instance.publishSoldierData(
        trackingCode: trackingCode,
        userId: userId,
        data: soldierDataMap,
      );
    }
  }

  // Formu göndermek ve başka bir sayfaya yönlendirmek
  void _submitForm() async {
    FocusScope.of(context).unfocus();
    if (_nameController.text.isNotEmpty &&
        _surnameController.text.isNotEmpty &&
        _selectedDate != null &&
        selectedDuration != null &&
        yolIzni != null &&
        _selectedAskerlikYeri != null &&
        _selectedMemleket != null &&
        _selectedKuvvetKomutanligi != null &&
        rutbe != null) {
      
      // Yükleniyor diyaloğunu göster
      _showLoadingDialog();

      try {
        await _saveData(); // Verileri kaydet
      } catch (e) {
        print('Error saving data: $e');
      }

      if (mounted) {
        // Yükleniyor diyaloğunu kapat
        Navigator.of(context).pop();

        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        final themeImage = prefs.getString('themeImage') ?? 'assets/images/img0.webp';

        // Kullanıcı henüz premium değilse ve asker yakını değilse, PRO tanıtım / kapı sayfasını göster
        final bool isNecessary = AppConfigService.instance.isNecessaryProScreen;
        if (!RevenueCatService.instance.isPremium && _userRole != 'yakin') {
          await Navigator.of(context).push(
            MaterialPageRoute(
              settings: const RouteSettings(name: 'PremiumPaywallPage'),
              builder: (_) => PremiumPaywallPage(
                source: 'post_info_save',
                isGate: isNecessary,
              ),
            ),
          );
        }

        if (mounted) {
          // Paywall zorunluyken kapatılamaz; buraya dönüldüyse kullanıcı çarpıyla geçmiştir veya PRO/yakındır
          await Navigator.of(context).pushAndRemoveUntil(
            _customPageRoute(ManagePages(backgroundImage: themeImage), 'ManagePages'),
            (Route<dynamic> route) => false,
          );
        }
      }
    } else {
      // Önceki adımlarda eksik kalan alan varsa o adıma dön ve alanı işaretle
      for (int step = 0; step < _stepCount; step++) {
        if (!_validateStep(step)) {
          setState(() {
            _isMovingForward = false;
            _currentStep = step;
          });
          return;
        }
      }
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

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false, // Geri tuşu ile kapatılmasını engelle
          child: Dialog(
            backgroundColor: SetupColors.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 28.0, horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(SetupColors.gold),
                    strokeWidth: 3.5,
                  ),
                  SizedBox(height: 22),
                  Text(
                    'Şafağın Hesaplanıyor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Bilgilerin kaydediliyor, profilin hazırlanıyor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SetupColors.textMuted,
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
  }

  /// Geçerli adımın eksik alanlarını işaretler; adım tamamsa true döner.
  bool _validateStep(int step) {
    final bool isValid = switch (step) {
      0 => _nameController.text.trim().isNotEmpty &&
          _surnameController.text.trim().isNotEmpty &&
          _selectedMemleket != null,
      1 => _selectedKuvvetKomutanligi != null &&
          rutbe != null &&
          _selectedAskerlikYeri != null &&
          selectedDuration != null,
      _ => _selectedDate != null && yolIzni != null,
    };

    setState(() {
      _showValidation = !isValid;
    });
    if (!isValid) HapticFeedback.mediumImpact();
    return isValid;
  }

  String? _errorIf(bool isMissing, String message) {
    return _showValidation && isMissing ? message : null;
  }

  void _refreshValidation(String _) {
    if (_showValidation) setState(() {});
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (!_validateStep(_currentStep)) return;
    setState(() {
      _isMovingForward = true;
      _currentStep++;
    });
  }

  void _prevStep() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isMovingForward = false;
      _showValidation = false;
      _currentStep--;
    });
  }

  void _handleBack() {
    if (_currentStep > 0) {
      _prevStep();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildHeader() {
    final bool canGoBack = _currentStep > 0 || Navigator.canPop(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: canGoBack ? SetupBackButton(onPressed: _handleBack) : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: List.generate(_stepCount, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Stack(
                        children: [
                          Container(
                            height: 5,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            widthFactor: index <= _currentStep ? 1 : 0,
                            child: Container(height: 5, color: SetupColors.gold),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_currentStep + 1}/$_stepCount',
            style: const TextStyle(
              color: SetupColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return _isRelative ? 'Askerini tanıyalım' : 'Seni tanıyalım';
      case 1:
        return _isRelative ? 'Askerinin görevi' : 'Askerlik bilgilerin';
      default:
        return 'Şafağını hesaplayalım';
    }
  }

  String get _stepSubtitle {
    switch (_currentStep) {
      case 0:
        return _isRelative
            ? 'Şafak kartında askerinin bilgileri görünecek.'
            : 'Şafak kartında ve künyende bu bilgiler görünecek.';
      case 1:
        return 'Kuvvet, rütbe ve görev yerine göre arayüz şekillenecek.';
      default:
        return 'Terhis tarihi girdiğin bilgilere göre anında hesaplanır.';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      default:
        return _buildStep2();
    }
  }

  Widget _buildStep0() {
    return Column(
      children: [
        SetupTextField(
          controller: _nameController,
          label: _isRelative ? 'Askerinin adı' : 'Adın',
          hint: 'Örn: Mehmet',
          icon: Icons.person_outline_rounded,
          errorText: _errorIf(_nameController.text.trim().isEmpty, 'Lütfen adı girin.'),
          onChanged: _refreshValidation,
        ),
        const SizedBox(height: 16),
        SetupTextField(
          controller: _surnameController,
          label: _isRelative ? 'Askerinin soyadı' : 'Soyadın',
          hint: 'Örn: Yılmaz',
          icon: Icons.badge_outlined,
          textInputAction: TextInputAction.done,
          errorText: _errorIf(_surnameController.text.trim().isEmpty, 'Lütfen soyadı girin.'),
          onChanged: _refreshValidation,
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
        ),
        const SizedBox(height: 16),
        SetupSelectField(
          label: _isRelative ? 'Askerinin memleketi' : 'Memleketin',
          hint: 'Şehir seç',
          value: _selectedMemleket,
          icon: Icons.home_outlined,
          errorText: _errorIf(_selectedMemleket == null, 'Lütfen memleketi seçin.'),
          onTap: () async {
            final value = await showSetupOptionSheet(
              context: context,
              title: 'Memleket',
              items: iller,
              selectedValue: _selectedMemleket,
            );
            if (value != null) setState(() => _selectedMemleket = value);
          },
        ),
      ],
    );
  }

  Widget _buildStep1() {
    const kuvvetler = ['Kara', 'Jandarma', 'Hava', 'Deniz'];
    const rutbeler = ['ER', 'ONBAŞI', 'ÇAVUŞ', 'ASTÇAVUŞ', 'ASTSUBAY', 'ASTEĞMEN', 'TEĞMEN'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SetupFieldLabel('Kuvvet komutanlığı'),
        SetupChoiceGrid(
          columns: 2,
          children: kuvvetler.map(_buildKuvvetTile).toList(),
        ),
        SetupFieldError(
          _errorIf(_selectedKuvvetKomutanligi == null, 'Lütfen kuvveti seçin.'),
        ),
        const SizedBox(height: 18),
        const SetupFieldLabel('Rütbe'),
        SetupChoiceGrid(
          columns: 3,
          children: rutbeler.map((item) {
            return SetupChoiceChip(
              label: item,
              isSelected: rutbe == item,
              onTap: () => setState(() => rutbe = item),
            );
          }).toList(),
        ),
        SetupFieldError(_errorIf(rutbe == null, 'Lütfen rütbeyi seçin.')),
        const SizedBox(height: 18),
        const SetupFieldLabel('Askerlik süresi'),
        SetupChoiceGrid(
          columns: 3,
          children: [
            _buildDurationChip(12, '12 Ay'),
            _buildDurationChip(6, '6 Ay'),
            _buildDurationChip(1, '1 Ay', caption: 'Bedelli'),
          ],
        ),
        SetupFieldError(_errorIf(selectedDuration == null, 'Lütfen süreyi seçin.')),
        const SizedBox(height: 18),
        SetupSelectField(
          label: 'Görev yeri',
          hint: 'Şehir seç',
          value: _selectedAskerlikYeri,
          icon: Icons.location_on_outlined,
          errorText: _errorIf(_selectedAskerlikYeri == null, 'Lütfen görev yerini seçin.'),
          onTap: () async {
            final value = await showSetupOptionSheet(
              context: context,
              title: 'Görev Yeri',
              items: iller,
              selectedValue: _selectedAskerlikYeri,
            );
            if (value != null) setState(() => _selectedAskerlikYeri = value);
          },
        ),
      ],
    );
  }

  Widget _buildDurationChip(int months, String label, {String? caption}) {
    return SetupChoiceChip(
      label: label,
      caption: caption,
      isSelected: selectedDuration == months,
      onTap: () => setState(() => selectedDuration = months),
    );
  }

  Widget _buildKuvvetTile(String kuvvet) {
    final bool isSelected = _selectedKuvvetKomutanligi == kuvvet;

    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          HapticFeedback.selectionClick();
          setState(() => _selectedKuvvetKomutanligi = kuvvet);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? SetupColors.gold.withValues(alpha: 0.14)
                : SetupColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? SetupColors.gold : SetupColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Image.asset('assets/images/$kuvvet.webp', width: 30, height: 34, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    kuvvet,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected ? SetupColors.goldLight : Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    const yolIzinleri = [
      '1 (Terhis)',
      '2 (Terhis)',
      '3 (Terhis)',
      '1+1 (İzin)',
      '2+2 (İzin)',
      '3+3 (İzin)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDatePicker(context),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _buildDayCounter(
                controller: _izinController,
                label: 'Kullanılan izin (gün)',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDayCounter(
                controller: _cezaController,
                label: 'Alınan ceza (gün)',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SetupFieldLabel('Yol izni (gün)'),
        SetupChoiceGrid(
          columns: 3,
          children: yolIzinleri.map((item) {
            final parts = item.split(' ');
            return SetupChoiceChip(
              label: parts[0],
              caption: parts[1].replaceAll(RegExp(r'[()]'), ''),
              isSelected: yolIzni == item,
              onTap: () => setState(() => yolIzni = item),
            );
          }).toList(),
        ),
        SetupFieldError(_errorIf(yolIzni == null, 'Lütfen yol iznini seçin.')),
        const SizedBox(height: 18),
        _buildTerhisPreview(),
      ],
    );
  }

  Widget _buildDayCounter({
    required TextEditingController controller,
    required String label,
  }) {
    final int value = int.tryParse(controller.text) ?? 0;

    void update(int next) {
      HapticFeedback.selectionClick();
      setState(() {
        controller.text = next.toString();
      });
    }

    Widget stepButton(IconData icon, String tooltip, VoidCallback? onTap) {
      return IconButton(
        icon: Icon(icon, size: 19),
        tooltip: tooltip,
        color: SetupColors.gold,
        disabledColor: SetupColors.textFaint,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 50),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SetupFieldLabel(label),
        Container(
          height: 52,
          decoration: setupFieldDecoration(),
          child: Row(
            children: [
              stepButton(
                Icons.remove_rounded,
                'Azalt',
                value > 0 ? () => update(value - 1) : null,
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              stepButton(Icons.add_rounded, 'Artır', () => update(value + 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTerhisPreview() {
    final DateTime? endDate = _calculatedEndDate;
    final int? remainingDays = endDate?.difference(DateTime.now()).inDays;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: endDate == null
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E2A1C), Color(0xFF1B1810)],
              ),
        color: endDate == null ? SetupColors.surface : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: endDate == null ? SetupColors.border : const Color(0xFF85682A),
          width: endDate == null ? 1 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available_rounded,
            color: endDate == null ? SetupColors.textFaint : SetupColors.gold,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tahmini terhis tarihi',
                  style: TextStyle(
                    color: endDate == null ? SetupColors.textFaint : const Color(0xFFD9B566),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  endDate == null
                      ? 'Sülüs ve yol iznini seç'
                      : DateFormat('d MMMM yyyy', 'tr_TR').format(endDate),
                  style: TextStyle(
                    color: endDate == null ? SetupColors.textMuted : SetupColors.goldLight,
                    fontSize: endDate == null ? 14 : 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (remainingDays != null && remainingDays > 0) ...[
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$remainingDays',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'gün kaldı',
                  style: TextStyle(
                    color: Color(0xFFD9B566),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastStep = _currentStep == _stepCount - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: setupOverlayStyle,
      child: PopScope(
        canPop: _currentStep == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _prevStep();
        },
        child: Scaffold(
          backgroundColor: SetupColors.background,
          body: SetupBackground(
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: setupTopLayoutBuilder,
                        transitionBuilder: (child, animation) {
                          final double direction = _isMovingForward ? 1 : -1;
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0.06 * direction, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: SingleChildScrollView(
                          key: ValueKey(_currentStep),
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SetupHeading(title: _stepTitle, subtitle: _stepSubtitle),
                              const SizedBox(height: 22),
                              _buildStepContent(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    child: SetupPrimaryButton(
                      label: isLastStep ? 'Kaydet ve Başlat' : 'Devam Et',
                      icon: isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      onPressed: isLastStep ? _submitForm : _nextStep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final String? errorText = _errorIf(_selectedDate == null, 'Lütfen sülüs tarihini seçin.');

    return SetupSelectField(
      label: _isRelative ? 'Askerinin sülüs tarihi' : 'Sülüs tarihi',
      hint: 'Tarih seç',
      value: _selectedDate == null ? null : DateFormat('d MMMM yyyy', 'tr_TR').format(_selectedDate!),
      icon: Icons.calendar_month_outlined,
      errorText: errorText,
      onTap: () => _showCupertinoDatePicker(context),
    );
  }

  Future<void> _showCupertinoDatePicker(BuildContext context) async {
    DateTime tempSelectedDate = _selectedDate ?? DateTime.now(); // Geçici tarih

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: SetupColors.surfaceRaised,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Sülüs Tarihi',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(
                    height: 200,
                    child: CupertinoTheme(
                      data: const CupertinoThemeData(
                        brightness: Brightness.dark,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
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
                  ),
                  const SizedBox(height: 8),
                  SetupPrimaryButton(
                    label: 'Tamam',
                    icon: null,
                    onPressed: () {
                      setState(() {
                        _selectedDate = tempSelectedDate; // Seçili olan tarihi ayarla
                      });
                      Navigator.of(sheetContext).pop(); // Onay
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
