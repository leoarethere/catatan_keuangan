import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/category_l10n.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/budget.dart';
import '../providers/finance_provider.dart';
import '../utils/currency_helper.dart';

/// Screen untuk mengelola anggaran (budget) bulanan.
class BudgetScreen extends StatefulWidget {
  final FinanceProvider provider;

  const BudgetScreen({super.key, required this.provider});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = widget.provider;

    final globalProgress = provider.getGlobalBudgetProgress();
    final categoryProgress = provider.getCategoryBudgetProgress();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageBudgetTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.savings_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.budgetIntro,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ============ BUDGET GLOBAL ============
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.totalMonthlyExpense,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BudgetCard(
            provider: provider,
            title: l10n.totalBudgetCard,
            progress: globalProgress,
            color: colorScheme.primary,
            onEdit: () => _showBudgetDialog(context, categoryId: null),
          ),
          const SizedBox(height: 24),

          // ============ BUDGET PER KATEGORI ============
          Row(
            children: [
              Icon(Icons.category_rounded,
                  size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.perExpenseCategory,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (categoryProgress.isEmpty)
            _buildEmptyHint(l10n.noCategoryBudget)
          else
            ...categoryProgress.map((p) {
              final cat = provider.getCategoryById(p.budget.categoryId!);
              return _BudgetCard(
                provider: provider,
                title: cat.localized(context),
                icon: cat.icon,
                progress: p,
                color: cat.color,
                onEdit: () =>
                    _showBudgetDialog(context, categoryId: cat.id),
              );
            }),

          const SizedBox(height: 24),

          // ============ TAMBAH BUDGET KATEGORI ============
          OutlinedButton.icon(
            onPressed: () => _showBudgetDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addCategoryBudget),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyHint(String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBudgetDialog(BuildContext context,
      {String? categoryId}) async {
    await showDialog(
      context: context,
      builder: (_) => _BudgetDialog(
        provider: widget.provider,
        categoryId: categoryId,
      ),
    );

    if (mounted) setState(() {});
  }
}

/// Card menampilkan progress satu budget.
class _BudgetCard extends StatelessWidget {
  final FinanceProvider provider;
  final String title;
  final IconData? icon;
  final BudgetProgress? progress;
  final Color color;
  final VoidCallback onEdit;

  const _BudgetCard({
    required this.provider,
    required this.title,
    this.icon,
    required this.progress,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final p = progress;
    final status = p?.status ?? BudgetStatus.safe;

    final statusColor = switch (status) {
      BudgetStatus.safe => Colors.green,
      BudgetStatus.warning => Colors.orange,
      BudgetStatus.over => Colors.red,
    };

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: status == BudgetStatus.over
              ? Colors.red.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      color: colorScheme.surfaceContainerLowest,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: p == null
              ? _buildUnset(l10n, theme, colorScheme)
              : _buildProgress(l10n, theme, colorScheme, p, statusColor),
        ),
      ),
    );
  }

  Widget _buildUnset(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
        ] else
          Icon(Icons.add_circle_outline_rounded,
              color: colorScheme.outline, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.notSetTapToSet,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
      ],
    );
  }

  Widget _buildProgress(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
    BudgetProgress p,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${p.percentage.toStringAsFixed(0)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.budgetSpent(CurrencyHelper.format(p.spent)),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
            Text(
              l10n.ofLimit(CurrencyHelper.format(p.limit)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (p.percentage / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),
        if (p.status == BudgetStatus.over) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                l10n.overBudgetBy(CurrencyHelper.format(p.spent - p.limit)),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ] else if (p.status == BudgetStatus.warning) ...[
          const SizedBox(height: 6),
          Text(
            l10n.budgetRemaining(CurrencyHelper.format(p.remaining)),
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Dialog untuk set/update/hapus budget.
class _BudgetDialog extends StatefulWidget {
  final FinanceProvider provider;
  final String? categoryId;

  const _BudgetDialog({
    required this.provider,
    this.categoryId,
  });

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late TextEditingController _amountController;
  bool _isSaving = false;

  bool get isGlobal => widget.categoryId == null;

  Budget? get existing => widget.categoryId == null
      ? widget.provider.getBudgetById('global')
      : widget.provider.getBudgetById(widget.categoryId!);

  @override
  void initState() {
    super.initState();
    final budget = existing;
    _amountController = TextEditingController(
      text: budget != null ? budget.monthlyLimit.toString() : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _titleFor(AppLocalizations l10n) {
    if (isGlobal) return l10n.globalBudgetTitle;
    final cat = widget.provider.getCategoryById(widget.categoryId!);
    return l10n.categoryBudgetTitle(cat.localized(context));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _amountController.text.replaceAll('.', '').trim();
    final amount = int.tryParse(text) ?? 0;

    if (amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidAmount)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.provider.setBudget(
        categoryId: widget.categoryId,
        monthlyLimit: amount, // 0 = hapus budget
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.budgetSaveFailed('$e'))),
        );
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteBudgetTitle),
        content: Text(l10n.deleteBudgetMessage(_titleFor(l10n))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.provider.deleteBudget(isGlobal ? 'global' : widget.categoryId!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasExisting = existing != null;

    return AlertDialog(
      title: Text(_titleFor(l10n)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isGlobal ? l10n.globalBudgetDesc : l10n.categoryBudgetDesc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofocus: true,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              hintText: '0',
              helperText: l10n.enterZeroToDelete,
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (hasExisting) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: colorScheme.outline),
                const SizedBox(width: 6),
                Text(
                  l10n.currentBudget(
                    CurrencyHelper.format(existing!.monthlyLimit),
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (hasExisting)
          TextButton.icon(
            onPressed: _isSaving ? null : _delete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(l10n.delete),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: Text(hasExisting ? l10n.save : l10n.setBudget),
        ),
      ],
    );
  }
}
