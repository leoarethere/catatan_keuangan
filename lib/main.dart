import 'package:flutter/material.dart';
import 'providers/finance_provider.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final financeProvider = FinanceProvider();
  await financeProvider.initialize();

  runApp(CatatanKeuanganApp(provider: financeProvider));
}

class CatatanKeuanganApp extends StatelessWidget {
  final FinanceProvider provider;

  const CatatanKeuanganApp({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Warna dasar Material 3 bernuansa financial green / teal yang seimbang dan tenang
    const primarySeedColor = Color(0xFF00796B);

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return MaterialApp(
          title: 'Catatan Keuangan',
          debugShowCheckedModeBanner: false,
          themeMode: provider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primarySeedColor,
              brightness: Brightness.light,
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 2,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primarySeedColor,
              brightness: Brightness.dark,
            ),
            cardTheme: const CardThemeData(
              elevation: 0,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 2,
            ),
          ),
          home: HomeScreen(provider: provider),
        );
      },
    );
  }
}
