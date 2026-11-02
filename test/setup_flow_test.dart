import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:safaksayar/pages/onboarding_showcase_page.dart';
import 'package:safaksayar/pages/user_input_page.dart';
import 'package:safaksayar/pages/welcome_role_page.dart';
import 'package:safaksayar/widgets/setup_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR', null));

  void useSmallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  group('calculateTerhisDate', () {
    DateTime? calculate({int months = 12, String? yol = '1 (Terhis)', int izin = 0, int ceza = 0}) {
      return calculateTerhisDate(
        sulusDate: DateTime(2026, 1, 15),
        durationMonths: months,
        yolIzni: yol,
        izinGunu: izin,
        cezaGunu: ceza,
      );
    }

    test('12 aylık süreden 11 gün düşer', () {
      expect(calculate(), DateTime(2027, 1, 4));
    });

    test('6 aylık süreden 5 gün düşer', () {
      expect(calculate(months: 6), DateTime(2026, 7, 10));
    });

    test('bedelli süresinde düzeltme yoktur', () {
      expect(calculate(months: 1), DateTime(2026, 2, 15));
    });

    test('izin, ceza ve yol izni terhis tarihine yansır', () {
      expect(calculate(yol: '3 (Terhis)', izin: 4, ceza: 2), DateTime(2027, 1, 12));
      expect(calculate(yol: '2+2 (İzin)'), DateTime(2027, 1, 3));
    });

    test('eksik bilgide null döner', () {
      expect(calculate(yol: null), isNull);
      expect(calculate(yol: ''), isNull);
    });
  });

  testWidgets('sihirbaz eksik alanla ilerlemez, alanları işaretler', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: UserInputPage(initialRole: 'asker')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(find.text('Seni tanıyalım'), findsOneWidget);
    expect(find.text('Lütfen adı girin.'), findsOneWidget);
    expect(find.text('Lütfen memleketi seçin.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Enver');
    await tester.pump();
    expect(find.text('Lütfen adı girin.'), findsNothing);
  });

  testWidgets('kayıtlı kullanıcı son adımda hesaplanan terhisi görür', (tester) async {
    SharedPreferences.setMockInitialValues({
      'name': 'Enver',
      'surname': 'Amil',
      'memleket': 'Ankara',
      'askerlik_yeri': 'Şırnak',
      'kuvvet_komutanligi': 'Kara',
      'rutbe': 'ER',
      'duration': 12,
      'sulus_tarihi': '2026-01-15T00:00:00.000',
      'yolIzni': '1 (Terhis)',
    });
    await tester.pumpWidget(const MaterialApp(home: UserInputPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(find.text('Şafağını hesaplayalım'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('4 Ocak 2027'), 200);
    expect(find.text('4 Ocak 2027'), findsOneWidget);

    await tester.tap(find.byTooltip('Artır').first);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('5 Ocak 2027'), findsOneWidget);
  });

  testWidgets('asker yakını kod ekranına geçer, geri dönebilir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: WelcomeRolePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asker Yakınıyım'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(find.text('Askerine bağlan'), findsOneWidget);

    await tester.tap(find.text('Askeri Bul'));
    await tester.pumpAndSettle();
    expect(find.text('Lütfen askerinize ait takip kodunu giriniz.'), findsOneWidget);

    await tester.tap(find.byType(SetupBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Asker Yakınıyım'), findsOneWidget);
  });

  testWidgets('tanıtım tüm slaytlarda taşmadan ilerler', (tester) async {
    SharedPreferences.setMockInitialValues({});
    useSmallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: OnboardingShowcasePage()));

    for (int i = 0; i < 3; i++) {
      await tester.pump();
      await tester.tap(find.text('Devam Et'));
      for (int frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }
    expect(find.text('Hadi Başlayalım'), findsOneWidget);
    expect(find.text('Atla'), findsNothing);
  });

  test('arama Türkçe karakterleri sadeleştirir', () {
    expect(normalizeForSearch('Şırnak'), normalizeForSearch('sirnak'));
    expect(normalizeForSearch('İzmir'), 'izmir');
  });
}
