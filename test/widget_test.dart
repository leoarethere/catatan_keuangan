import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_project/main.dart';
import 'package:flutter_project/providers/finance_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders correctly and displays title and balance', (WidgetTester tester) async {
    final provider = FinanceProvider();
    await provider.initialize();

    await tester.pumpWidget(CatatanKeuanganApp(provider: provider));
    await tester.pumpAndSettle();

    // Pastikan judul aplikasi dan elemen utama tampil
    expect(find.text('Catatan Keuangan'), findsOneWidget);
    expect(find.text('Saldo Bulan Ini'), findsOneWidget);
    expect(find.text('Catat Transaksi'), findsOneWidget);
  });
}
