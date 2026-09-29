import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/transaction_repository.dart';
import '../utils/date_helper.dart';

class CategoryStat {
  final TransactionCategory category;
  final double totalAmount;
  final int count;
  final double percentage;

  const CategoryStat({
    required this.category,
    required this.totalAmount,
    required this.count,
    required this.percentage,
  });
}

class FinanceProvider extends ChangeNotifier {
  final TransactionRepository _repository = TransactionRepository();

  List<Transaction> _transactions = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  TransactionType? _selectedTypeFilter;
  String _searchQuery = '';
  ThemeMode _themeMode = ThemeMode.system;

  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  DateTime get selectedMonth => _selectedMonth;
  TransactionType? get selectedTypeFilter => _selectedTypeFilter;
  String get searchQuery => _searchQuery;
  List<Transaction> get allTransactions => _transactions;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _transactions = await _repository.loadTransactions();
    _isLoading = false;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  // Daftar transaksi bulan terpilih
  List<Transaction> get currentMonthTransactions {
    return _transactions.where((t) {
      return DateHelper.isSameMonth(t.date, _selectedMonth);
    }).toList();
  }

  // Transaksi yang difilter untuk ditampilkan di list
  List<Transaction> get filteredTransactions {
    final list = currentMonthTransactions.where((t) {
      final matchesType = _selectedTypeFilter == null || t.type == _selectedTypeFilter;
      final matchesQuery = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          t.category.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesType && matchesQuery;
    }).toList();

    // Urutkan dari yang paling baru
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // Total Pemasukan bulan ini
  double get currentMonthIncome {
    return currentMonthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Total Pengeluaran bulan ini
  double get currentMonthExpense {
    return currentMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Saldo bersih bulan ini
  double get currentMonthBalance => currentMonthIncome - currentMonthExpense;

  // Total saldo keseluruhan sepanjang waktu
  double get totalBalance {
    final totalInc = _transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExp = _transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    return totalInc - totalExp;
  }

  // Statistik Kategori untuk Pengeluaran bulan ini
  List<CategoryStat> getExpenseCategoryStats() {
    return _calculateCategoryStats(TransactionType.expense);
  }

  // Statistik Kategori untuk Pemasukan bulan ini
  List<CategoryStat> getIncomeCategoryStats() {
    return _calculateCategoryStats(TransactionType.income);
  }

  List<CategoryStat> _calculateCategoryStats(TransactionType type) {
    final targetTransactions = currentMonthTransactions.where((t) => t.type == type).toList();
    final total = targetTransactions.fold(0.0, (sum, t) => sum + t.amount);

    if (total == 0) return [];

    final Map<String, List<Transaction>> grouped = {};
    for (final t in targetTransactions) {
      grouped.putIfAbsent(t.category.id, () => []).add(t);
    }

    final stats = grouped.entries.map((entry) {
      final category = entry.value.first.category;
      final catTotal = entry.value.fold(0.0, (sum, t) => sum + t.amount);
      final count = entry.value.length;
      final percentage = (catTotal / total) * 100.0;

      return CategoryStat(
        category: category,
        totalAmount: catTotal,
        count: count,
        percentage: percentage,
      );
    }).toList();

    // Urutkan dari nominal pengeluaran/pemasukan terbesar
    stats.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return stats;
  }

  // Aksi CRUD
  Future<void> addTransaction(Transaction tx) async {
    _transactions.insert(0, tx);
    await _repository.saveTransactions(_transactions);
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction tx) async {
    final index = _transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      _transactions[index] = tx;
      await _repository.saveTransactions(_transactions);
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _repository.saveTransactions(_transactions);
    notifyListeners();
  }
}
