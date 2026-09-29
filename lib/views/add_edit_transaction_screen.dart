import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/finance_provider.dart';
import '../utils/date_helper.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final FinanceProvider provider;
  final Transaction? initialTransaction;

  const AddEditTransactionScreen({
    super.key,
    required this.provider,
    this.initialTransaction,
  });

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late TransactionCategory _selectedCategory;

  bool get isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTransaction;

    if (initial != null) {
      _selectedType = initial.type;
      _titleController = TextEditingController(text: initial.title);
      _amountController = TextEditingController(
        text: initial.amount.toStringAsFixed(0),
      );
      _noteController = TextEditingController(text: initial.note ?? '');
      _selectedDate = initial.date;
      _selectedCategory = initial.category;
    } else {
      _selectedType = TransactionType.expense;
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedCategory = TransactionCategory.defaultExpenseCategories.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(Set<TransactionType> newSelection) {
    final newType = newSelection.first;
    if (newType != _selectedType) {
      setState(() {
        _selectedType = newType;
        // Ganti kategori default sesuai tipe baru
        if (_selectedType == TransactionType.expense) {
          _selectedCategory = TransactionCategory.defaultExpenseCategories.first;
        } else {
          _selectedCategory = TransactionCategory.defaultIncomeCategories.first;
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        // Pertahankan jam/menit saat ini jika tanggal sama
        final now = DateTime.now();
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          now.hour,
          now.minute,
        );
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    final newTransaction = Transaction(
      id: widget.initialTransaction?.id ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      amount: amount,
      type: _selectedType,
      category: _selectedCategory,
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (isEditing) {
      widget.provider.updateTransaction(newTransaction);
    } else {
      widget.provider.addTransaction(newTransaction);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentCategories = _selectedType == TransactionType.expense
        ? TransactionCategory.defaultExpenseCategories
        : TransactionCategory.defaultIncomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Catatan' : 'Tambah Catatan Baru'),
        centerTitle: true,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Hapus Catatan',
              onPressed: () async {
                final navigator = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Catatan?'),
                    content: const Text('Catatan ini akan dihapus secara permanen.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );

                if (!mounted) return;
                if (confirm == true) {
                  widget.provider.deleteTransaction(widget.initialTransaction!.id);
                  navigator.pop();
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Segmented Button Tipe Transaksi
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
                onSelectionChanged: _onTypeChanged,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: _selectedType == TransactionType.expense
                      ? Colors.redAccent.withValues(alpha: 0.15)
                      : Colors.teal.withValues(alpha: 0.15),
                  selectedForegroundColor: _selectedType == TransactionType.expense
                      ? Colors.redAccent
                      : Colors.teal,
                ),
              ),
              const SizedBox(height: 24),

              // Input Nominal
              Text(
                'Nominal',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _selectedType == TransactionType.expense
                      ? Colors.redAccent
                      : Colors.teal,
                ),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _selectedType == TransactionType.expense
                        ? Colors.redAccent
                        : Colors.teal,
                  ),
                  hintText: '0',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Masukkan nominal transaksi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Input Judul
              Text(
                'Judul Transaksi',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Misal: Makan Siang, Gaji Kantor, dll.',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul transaksi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Pilih Kategori
              Text(
                'Kategori',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentCategories.map((cat) {
                  final isSelected = _selectedCategory.id == cat.id;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 18,
                      color: isSelected ? colorScheme.onPrimary : cat.color,
                    ),
                    label: Text(cat.name),
                    selected: isSelected,
                    selectedColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Pemilih Tanggal
              Text(
                'Tanggal',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateHelper.formatFullDate(_selectedDate),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Input Catatan Tambahan (Opsional)
              Text(
                'Catatan Tambahan (Opsional)',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Keterangan atau rincian tambahan...',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Simpan
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(isEditing ? 'Perbarui Catatan' : 'Simpan Transaksi'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
