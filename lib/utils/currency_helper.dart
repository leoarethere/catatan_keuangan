import 'package:intl/intl.dart';

class CurrencyHelper {
  /// Locale aktif untuk format angka ('id' atau 'en').
  /// Diubah oleh FinanceProvider.setLocale().
  ///
  /// Catatan: simbol mata uang selalu Rp karena aplikasi ini
  /// khusus untuk pencatatan keuangan Rupiah. Locale hanya
  /// memengaruhi pemisah ribuan (id: 1.450.000 / en: 1,450,000).
  static String locale = 'id';

  static NumberFormat _formatterFor(String locale) {
    final numberLocale = locale == 'en' ? 'en_US' : 'id_ID';
    return NumberFormat.currency(
      locale: numberLocale,
      symbol: 'Rp ',
      decimalDigits: 0,
    );
  }

  static String format(num amount) {
    return _formatterFor(locale).format(amount);
  }

  static int? parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
}
