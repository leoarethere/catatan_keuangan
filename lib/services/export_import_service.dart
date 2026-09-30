import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import 'transaction_repository.dart';

/// Jenis kegagalan layanan ekspor/impor.
/// Dipakai agar pesan error bisa diterjemahkan UI (l10n).
enum ExportImportErrorKind {
  /// File tidak bisa dibaca.
  fileReadFailed,

  /// Struktur JSON tidak dikenali.
  invalidJson,

  /// CSV kosong / tidak punya baris data.
  emptyCsv,

  /// Tidak ada transaksi valid di file.
  noValidTransactions,
}

/// Exception ber-tipe untuk layanan ekspor/impor.
class ExportImportException implements Exception {
  final ExportImportErrorKind kind;
  const ExportImportException(this.kind);

  @override
  String toString() => 'ExportImportException(${kind.name})';
}

/// Hasil operasi impor
class ImportResult {
  final int totalImported;
  final int added;
  final int updated;
  final int skipped;
  final List<ExportImportErrorKind> errors;
  final bool success;

  const ImportResult({
    required this.totalImported,
    required this.added,
    required this.updated,
    required this.skipped,
    this.errors = const [],
    this.success = true,
  });
}

/// Preview data sebelum import
class ImportPreview {
  final String fileName;
  final String format; // 'json' atau 'csv'
  final List<Transaction> transactions;
  final int incomeCount;
  final int incomeTotal;
  final int expenseCount;
  final int expenseTotal;

  const ImportPreview({
    required this.fileName,
    required this.format,
    required this.transactions,
    required this.incomeCount,
    required this.incomeTotal,
    required this.expenseCount,
    required this.expenseTotal,
  });
}

/// Strategi impor
enum ImportStrategy {
  /// Ganti seluruh data dengan data dari file
  replace,

  /// Tambah data baru, update yang ID-nya sudah ada
  merge,

  /// Tambah data baru, skip jika ID sudah ada
  skipExisting,
}

/// Service untuk ekspor dan impor data transaksi.
class ExportImportService {
  final TransactionRepository _repository;

  ExportImportService({TransactionRepository? repository})
      : _repository = repository ?? TransactionRepository();

  // ==================== EXPORT ====================

  /// Ekspor transaksi ke format JSON
  Future<File> exportToJson(List<Transaction> transactions) async {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactionCount': transactions.length,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    return _writeToFile(jsonString, 'catatkeun_export.json');
  }

  /// Ekspor transaksi ke format CSV (untuk Excel/Google Sheets)
  Future<File> exportToCsv(List<Transaction> transactions) async {
    final buffer = StringBuffer();

    // Header CSV
    buffer.writeln('ID,Judul,Nominal,Tipe,Kategori,Tanggal,Catatan');

    // Data rows
    for (final tx in transactions) {
      final row = [
        _escapeCsv(tx.id),
        _escapeCsv(tx.title),
        tx.amount.toString(),
        tx.type == TransactionType.income ? 'Pemasukan' : 'Pengeluaran',
        _escapeCsv(tx.category.name),
        tx.date.toIso8601String(),
        _escapeCsv(tx.note ?? ''),
      ];
      buffer.writeln(row.join(','));
    }

    return _writeToFile(buffer.toString(), 'catatkeun_export.csv');
  }

  /// Share file ke aplikasi lain (WhatsApp, Email, dll)
  Future<void> shareFile(File file, {String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: text ?? 'Backup data CatetKeun',
      ),
    );
  }

  // ==================== IMPORT ====================

  /// Pilih file untuk import (tanpa apply) - return null jika dibatalkan
  Future<ImportPreview?> pickFileForImport() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );

    if (files.isEmpty) {
      // User membatalkan
      return null;
    }

    final file = files.first;

    final Uint8List bytes;
    final String content;
    try {
      bytes = await file.readAsBytes();
      content = utf8.decode(bytes);
    } catch (_) {
      throw const ExportImportException(ExportImportErrorKind.fileReadFailed);
    }

    final format = file.name.toLowerCase().endsWith('.json') ? 'json' : 'csv';

    final transactions = format == 'json'
        ? _parseJson(content)
        : _parseCsv(content);

    // Hitung statistik
    int incomeCount = 0;
    int incomeTotal = 0;
    int expenseCount = 0;
    int expenseTotal = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        incomeCount++;
        incomeTotal += tx.amount;
      } else {
        expenseCount++;
        expenseTotal += tx.amount;
      }
    }

    return ImportPreview(
      fileName: file.name,
      format: format,
      transactions: transactions,
      incomeCount: incomeCount,
      incomeTotal: incomeTotal,
      expenseCount: expenseCount,
      expenseTotal: expenseTotal,
    );
  }

  /// Apply import dengan strategi yang dipilih
  Future<ImportResult> applyImport({
    required ImportPreview preview,
    required List<Transaction> currentTransactions,
    required ImportStrategy strategy,
  }) async {
    if (preview.transactions.isEmpty) {
      return const ImportResult(
        totalImported: 0,
        added: 0,
        updated: 0,
        skipped: 0,
        success: false,
        errors: [ExportImportErrorKind.noValidTransactions],
      );
    }

    List<Transaction> finalList;
    int added = 0;
    int updated = 0;
    int skipped = 0;

    switch (strategy) {
      case ImportStrategy.replace:
        // Ganti seluruh data
        finalList = List.from(preview.transactions);
        added = preview.transactions.length;
        break;

      case ImportStrategy.merge:
        // Merge: update jika ID sama, tambah jika baru
        final merged = <String, Transaction>{};
        for (final tx in currentTransactions) {
          merged[tx.id] = tx;
        }

        for (final tx in preview.transactions) {
          if (merged.containsKey(tx.id)) {
            merged[tx.id] = tx;
            updated++;
          } else {
            merged[tx.id] = tx;
            added++;
          }
        }

        finalList = merged.values.toList();
        break;

      case ImportStrategy.skipExisting:
        // Skip jika ID sudah ada
        final existingIds = currentTransactions.map((t) => t.id).toSet();
        finalList = List.from(currentTransactions);

        for (final tx in preview.transactions) {
          if (existingIds.contains(tx.id)) {
            skipped++;
          } else {
            finalList.add(tx);
            added++;
          }
        }
        break;
    }

    // Sort by date descending
    finalList.sort((a, b) => b.date.compareTo(a.date));

    // Save
    await _repository.saveTransactions(finalList);

    return ImportResult(
      totalImported: preview.transactions.length,
      added: added,
      updated: updated,
      skipped: skipped,
    );
  }

  // ==================== PRIVATE HELPERS ====================

  Future<File> _writeToFile(String content, String fileName) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}${Platform.pathSeparator}${timestamp}_$fileName';
    final file = File(path);
    await file.writeAsString(content);
    return file;
  }

  String _escapeCsv(String value) {
    // Jika mengandung comma, quote, atau newline, bungkus dengan quote
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  List<Transaction> _parseJson(String content) {
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const ExportImportException(ExportImportErrorKind.invalidJson);
    }

    // Handle format baru (dengan wrapper)
    if (decoded is Map<String, dynamic> && decoded.containsKey('transactions')) {
      final List<dynamic> list = decoded['transactions'] as List<dynamic>;
      return _parseTransactionList(list);
    }

    // Handle format lama (plain array)
    if (decoded is List<dynamic>) {
      return _parseTransactionList(decoded);
    }

    throw const ExportImportException(ExportImportErrorKind.invalidJson);
  }

  List<Transaction> _parseTransactionList(List<dynamic> list) {
    final transactions = <Transaction>[];
    for (final item in list) {
      try {
        transactions.add(Transaction.fromJson(item as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Skip record rusak: $e');
        // Continue - skip record yang rusak
      }
    }
    return transactions;
  }

  List<Transaction> _parseCsv(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) {
      throw const ExportImportException(ExportImportErrorKind.emptyCsv);
    }

    // Skip header
    final transactions = <Transaction>[];
    for (int i = 1; i < lines.length; i++) {
      try {
        final tx = _parseCsvRow(lines[i]);
        if (tx != null) {
          transactions.add(tx);
        }
      } catch (e) {
        debugPrint('Skip CSV row $i: $e');
      }
    }

    return transactions;
  }

  Transaction? _parseCsvRow(String line) {
    final columns = _parseCsvLine(line);
    if (columns.length < 7) return null;

    final id = columns[0];
    final title = columns[1];
    final amount = int.tryParse(columns[2]);
    final typeStr = columns[3];
    final categoryName = columns[4];
    final dateStr = columns[5];
    final note = columns[6].isEmpty ? null : columns[6];

    if (amount == null || title.isEmpty) return null;

    // Terima nilai lokal (id) maupun internasional (en) agar file
    // hasil ekspor lintas bahasa tetap bisa diimpor.
    final normalizedType = typeStr.trim().toLowerCase();
    final isIncome = normalizedType == 'pemasukan' ||
        normalizedType == 'income' ||
        normalizedType == 'in';
    final type =
        isIncome ? TransactionType.income : TransactionType.expense;

    // Cari kategori berdasarkan nama
    final category = _findCategoryByName(categoryName, type);

    return Transaction(
      id: id.isEmpty ? 'imported_${DateTime.now().millisecondsSinceEpoch}' : id,
      title: title,
      amount: amount,
      type: type,
      category: category,
      date: DateTime.parse(dateStr),
      note: note,
    );
  }

  /// Parse satu baris CSV dengan handling quoted fields
  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          current.write('"');
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString());

    return result;
  }

  TransactionCategory _findCategoryByName(String name, TransactionType type) {
    final categories = type == TransactionType.income
        ? TransactionCategory.defaultIncomeCategories
        : TransactionCategory.defaultExpenseCategories;

    // Cari exact match dulu
    for (final cat in categories) {
      if (cat.name.toLowerCase() == name.toLowerCase()) {
        return cat;
      }
    }

    // Fallback ke kategori "Lainnya"
    return categories.last;
  }
}
