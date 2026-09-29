import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class TransactionRepository {
  static const String _storageKey = 'financial_records_key_v1';

  Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      // Sediakan initial sample data yang realistis untuk pengalaman pertama pengguna
      final initialData = _getInitialSampleData();
      await saveTransactions(initialData);
      return initialData;
    }

    try {
      final List<dynamic> decodedList = jsonDecode(jsonString) as List<dynamic>;
      return decodedList
          .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Jika corrupt, fallback ke sample data
      return _getInitialSampleData();
    }
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  List<Transaction> _getInitialSampleData() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 'sample_1',
        title: 'Gaji Bulanan',
        amount: 8500000,
        type: TransactionType.income,
        category: TransactionCategory.getById('inc_salary'),
        date: DateTime(now.year, now.month, now.day - 3, 9, 0),
        note: 'Transfer gaji kantor',
      ),
      Transaction(
        id: 'sample_2',
        title: 'Belanja Mingguan',
        amount: 350000,
        type: TransactionType.expense,
        category: TransactionCategory.getById('exp_shopping'),
        date: DateTime(now.year, now.month, now.day - 2, 14, 30),
        note: 'Supermarket',
      ),
      Transaction(
        id: 'sample_3',
        title: 'Bensin & Tol',
        amount: 150000,
        type: TransactionType.expense,
        category: TransactionCategory.getById('exp_transport'),
        date: DateTime(now.year, now.month, now.day - 1, 8, 15),
        note: 'Isi Pertamax',
      ),
      Transaction(
        id: 'sample_4',
        title: 'Makan Siang & Kopi',
        amount: 55000,
        type: TransactionType.expense,
        category: TransactionCategory.getById('exp_food'),
        date: DateTime(now.year, now.month, now.day, 12, 45),
        note: 'Kafe dekat kantor',
      ),
      Transaction(
        id: 'sample_5',
        title: 'Project Sampingan',
        amount: 1200000,
        type: TransactionType.income,
        category: TransactionCategory.getById('inc_business'),
        date: DateTime(now.year, now.month, now.day, 15, 0),
        note: 'Desain UI freelance',
      ),
    ];
  }
}
