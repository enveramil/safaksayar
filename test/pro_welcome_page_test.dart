import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:safaksayar/Services/revenue_cat_service.dart';
import 'package:safaksayar/pages/premium_paywall_page.dart';
import 'package:safaksayar/pages/pro_welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR', null));

  Future<void> openPage(WidgetTester tester, {bool isRestore = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => ProWelcomePage.show(
              context,
              planLabel: 'Yıllık Plan',
              isRestore: isRestore,
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('kullanıcıyı adıyla karşılar ve devam edince kapanır', (tester) async {
    SharedPreferences.setMockInitialValues({'name': 'Enver', 'rutbe': 'Er'});
    await openPage(tester);

    expect(find.text('Artık PRO Plandasın'), findsOneWidget);
    expect(find.textContaining('Hoş geldin, Er Enver.'), findsOneWidget);
    expect(find.text('Yıllık Plan'), findsOneWidget);

    await tester.tap(find.text('Keşfetmeye Başla'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ProWelcomePage), findsNothing);
  });

  testWidgets('geri yüklemede ayrı başlık gösterir, ad yoksa boş bırakmaz', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await openPage(tester, isRestore: true);

    expect(find.text('PRO Üyeliğin Geri Yüklendi'), findsOneWidget);
    expect(find.textContaining('Tekrar hoş geldin.'), findsOneWidget);

    await tester.tap(find.text('Keşfetmeye Başla'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('PRO üye paywall yerine sade üyelik özetini görür', (tester) async {
    SharedPreferences.setMockInitialValues({'name': 'Enver', 'rutbe': 'Er'});
    final premium = RevenueCatService.instance.isPremiumNotifier;
    premium.value = true;
    addTearDown(() => premium.value = false);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => PremiumPaywallPage.show(context, source: 'app_bar'),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(PremiumPaywallPage), findsNothing);
    expect(find.text('PRO Plandasın'), findsOneWidget);
    expect(find.textContaining('Merhaba, Er Enver.'), findsOneWidget);

    await tester.tap(find.text('Tamam'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ProWelcomePage), findsNothing);
  });
}
