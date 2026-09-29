import 'package:flutter/material.dart';

enum TransactionType {
  income,
  expense;

  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Pemasukan';
      case TransactionType.expense:
        return 'Pengeluaran';
    }
  }
}

class TransactionCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
    };
  }

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return getById(id);
  }

  // Kategori default pengeluaran
  static const List<TransactionCategory> defaultExpenseCategories = [
    TransactionCategory(
      id: 'exp_food',
      name: 'Makanan & Minuman',
      icon: Icons.restaurant,
      color: Color(0xFFEF6C00),
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'exp_transport',
      name: 'Transportasi',
      icon: Icons.directions_car,
      color: Color(0xFF1976D2),
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'exp_shopping',
      name: 'Belanja',
      icon: Icons.shopping_bag,
      color: Color(0xFF8E24AA),
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'exp_bills',
      name: 'Tagihan & Utilitas',
      icon: Icons.receipt_long,
      color: Color(0xFFE53935),
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'exp_entertainment',
      name: 'Hiburan',
      icon: Icons.sports_esports,
      color: Color(0xFF00897B),
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'exp_health',
      name: 'Kesehatan',
      icon: Icons.medical_services,
      color: Color(0xFFD81B60),
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'exp_education',
      name: 'Pendidikan',
      icon: Icons.school,
      color: Color(0xFF3949AB),
      type: TransactionType.expense,
    ),
    TransactionCategory(
      id: 'exp_other',
      name: 'Lainnya',
      icon: Icons.more_horiz,
      color: Color(0xFF757575),
      type: TransactionType.expense,
    ),
  ];

  // Kategori default pemasukan
  static const List<TransactionCategory> defaultIncomeCategories = [
    TransactionCategory(
      id: 'inc_salary',
      name: 'Gaji Pokok',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF2E7D32),
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'inc_bonus',
      name: 'Bonus & THR',
      icon: Icons.card_giftcard,
      color: Color(0xFF43A047),
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'inc_investment',
      name: 'Investasi',
      icon: Icons.trending_up,
      color: Color(0xFF00ACC1),
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'inc_business',
      name: 'Usaha / Bisnis',
      icon: Icons.storefront,
      color: Color(0xFFF4511E),
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'inc_sale',
      name: 'Penjualan Barang',
      icon: Icons.sell,
      color: Color(0xFF546E7A),
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'inc_gift',
      name: 'Hadiah & Hibah',
      icon: Icons.redeem,
      color: Color(0xFFC2185B),
      type: TransactionType.income,
    ),
    TransactionCategory(
      id: 'inc_other',
      name: 'Lainnya',
      icon: Icons.savings,
      color: Color(0xFF00897B),
      type: TransactionType.income,
    ),
  ];

  static List<TransactionCategory> get allCategories => [
    ...defaultExpenseCategories,
    ...defaultIncomeCategories,
  ];

  static TransactionCategory getById(String id) {
    return allCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => defaultExpenseCategories.last,
    );
  }
}
