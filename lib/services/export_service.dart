import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../utils/constants.dart';
import 'transaction_service.dart';

class ExportService {
  final _txService = TransactionService();

  Future<File> exportToCsv(List<TransactionModel> transactions) async {
    final rows = <List<String>>[
      ['Type', 'Montant', 'Catégorie', 'Description', 'Date', 'Moyen de paiement', 'Note'],
    ];

    for (final t in transactions) {
      final category = await _txService.getCategoryById(t.categoryId);
      rows.add([
        t.type == TransactionType.depense ? 'Dépense' : 'Revenu',
        t.amount.toStringAsFixed(0),
        category?.name ?? 'Inconnue',
        t.description ?? '',
        t.date.toIso8601String().split('T').first,
        t.paymentMethod,
        t.note ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/mon_budget_export.csv');
    await file.writeAsString(csvData);
    return file;
  }

  Future<void> shareCsv(List<TransactionModel> transactions) async {
    final file = await exportToCsv(transactions);
    await Share.shareXFiles([XFile(file.path)], text: 'Export MON BUDGET');
  }
}
