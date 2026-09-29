import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/date_helper.dart';
import 'add_edit_transaction_screen.dart';
import 'statistics_screen.dart';
import 'widgets/balance_card.dart';
import 'widgets/empty_state.dart';
import 'widgets/filter_bar.dart';
import 'widgets/transaction_item_tile.dart';

class HomeScreen extends StatefulWidget {
  final FinanceProvider provider;

  const HomeScreen({super.key, required this.provider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTransaction(BuildContext context, [Transaction? tx]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          provider: widget.provider,
          initialTransaction: tx,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentNavIndex == 0
          ? _buildTransactionsTab(context)
          : StatisticsScreen(provider: widget.provider),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentNavIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Statistik',
          ),
        ],
      ),
      floatingActionButton: _currentNavIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openAddTransaction(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat Transaksi'),
              elevation: 3,
            )
          : null,
    );
  }

  Widget _buildTransactionsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final provider = widget.provider;

    return CustomScrollView(
      slivers: [
        // App Bar Material 3
        SliverAppBar(
          floating: true,
          pinned: true,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Cari transaksi...',
                    border: InputBorder.none,
                  ),
                  onChanged: provider.setSearchQuery,
                )
              : Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colorScheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Catatan Keuangan',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
              tooltip: _isSearching ? 'Tutup Pencarian' : 'Cari Transaksi',
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchController.clear();
                    provider.setSearchQuery('');
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
              onPressed: provider.toggleTheme,
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Main content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                BalanceCard(provider: provider),
                const SizedBox(height: 16),

                // Filter Bar
                FilterBar(provider: provider),
                const SizedBox(height: 12),

                // Subheader
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Transaksi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${provider.filteredTransactions.length} transaksi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Transactions List or Empty State
        if (provider.isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (provider.filteredTransactions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              title: 'Belum Ada Transaksi',
              message: provider.searchQuery.isNotEmpty
                  ? 'Tidak ditemukan transaksi yang cocok dengan kata kunci "${provider.searchQuery}".'
                  : 'Belum ada catatan keuangan pada periode ${DateHelper.formatMonthYear(provider.selectedMonth)}.',
              actionLabel: 'Tambah Catatan Baru',
              onAction: () => _openAddTransaction(context),
            ),
          )
        else
          _buildGroupedTransactionsSliver(context, provider),

        // Bottom space so FAB doesn't obscure the last item
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildGroupedTransactionsSliver(
    BuildContext context,
    FinanceProvider provider,
  ) {
    final transactions = provider.filteredTransactions;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Grouping by Date
    final Map<String, List<Transaction>> grouped = {};
    for (final tx in transactions) {
      final headerKey = DateHelper.formatGroupHeader(tx.date);
      grouped.putIfAbsent(headerKey, () => []).add(tx);
    }

    final groupKeys = grouped.keys.toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, groupIndex) {
            final groupTitle = groupKeys[groupIndex];
            final items = grouped[groupTitle]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text(
                      groupTitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Items in this group
                  ...items.map((tx) {
                    return TransactionItemTile(
                      transaction: tx,
                      onTap: () => _openAddTransaction(context, tx),
                      onDelete: () {
                        final deletedTx = tx;
                        provider.deleteTransaction(tx.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Catatan "${deletedTx.title}" dihapus'),
                            action: SnackBarAction(
                              label: 'Urungkan',
                              onPressed: () {
                                provider.addTransaction(deletedTx);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          },
          childCount: groupKeys.length,
        ),
      ),
    );
  }
}
