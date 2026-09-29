import 'package:flutter/material.dart';
import '../models/category.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_helper.dart';
import '../utils/date_helper.dart';
import 'widgets/empty_state.dart';

class StatisticsScreen extends StatefulWidget {
  final FinanceProvider provider;

  const StatisticsScreen({super.key, required this.provider});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  TransactionType _selectedType = TransactionType.expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = widget.provider;

    final stats = _selectedType == TransactionType.expense
        ? provider.getExpenseCategoryStats()
        : provider.getIncomeCategoryStats();

    final totalAmount = _selectedType == TransactionType.expense
        ? provider.currentMonthExpense
        : provider.currentMonthIncome;

    final isExpense = _selectedType == TransactionType.expense;
    final activeColor = isExpense ? Colors.redAccent : Colors.teal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Statistik'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Period Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: provider.previousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Bulan Sebelumnya',
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  DateHelper.formatMonthYear(provider.selectedMonth),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: provider.nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Bulan Berikutnya',
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented Button Pengeluaran / Pemasukan
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment<TransactionType>(
                  value: TransactionType.expense,
                  label: Text('Pengeluaran'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
                ButtonSegment<TransactionType>(
                  value: TransactionType.income,
                  label: Text('Pemasukan'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (set) {
                setState(() => _selectedType = set.first);
              },
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: activeColor.withValues(alpha: 0.15),
                selectedForegroundColor: activeColor,
              ),
            ),
            const SizedBox(height: 20),

            // Card Total Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.surfaceContainerLowest,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Total ${isExpense ? 'Pengeluaran' : 'Pemasukan'} Bulan Ini',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyHelper.format(totalAmount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: activeColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${stats.length} Kategori tercatat',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // List Kategori & Bar Progress
            Text(
              'Rincian per Kategori',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (stats.isEmpty)
              EmptyState(
                title: 'Belum Ada Data',
                message:
                    'Tidak ada catatan ${isExpense ? 'pengeluaran' : 'pemasukan'} pada periode ${DateHelper.formatMonthYear(provider.selectedMonth)}.',
              )
            else
              ...stats.map((stat) {
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  color: colorScheme.surfaceContainerLowest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: stat.category.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                stat.category.icon,
                                color: stat.category.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stat.category.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${stat.count} transaksi',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyHelper.format(stat.totalAmount),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${stat.percentage.toStringAsFixed(1)}%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: stat.percentage / 100.0,
                            minHeight: 8,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              stat.category.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
