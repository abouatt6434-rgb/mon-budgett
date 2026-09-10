import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/category_selector.dart';
import '../widgets/confirm_dialog.dart';

class TransactionDetailScreen extends StatefulWidget {
  final TransactionModel transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _txService = TransactionService();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _noteController;
  late DateTime _date;
  late String _paymentMethod;
  String? _categoryId;
  List<CategoryModel> _categories = [];
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _amountController = TextEditingController(text: t.amount.toStringAsFixed(0));
    _descriptionController = TextEditingController(text: t.description ?? '');
    _noteController = TextEditingController(text: t.note ?? '');
    _date = t.date;
    _paymentMethod = t.paymentMethod;
    _categoryId = t.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _txService.getCategories(widget.transaction.type);
    setState(() => _categories = cats);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant valide.')),
      );
      return;
    }
    setState(() => _saving = true);
    final updated = widget.transaction.copyWith(
      amount: amount,
      categoryId: _categoryId,
      description: _descriptionController.text.trim(),
      date: _date,
      paymentMethod: _paymentMethod,
      note: _noteController.text.trim(),
    );
    await _txService.updateTransaction(updated);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opération mise à jour.')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer cette opération ?',
      message: 'Voulez-vous vraiment supprimer cette opération ? Cette action est irréversible.',
      confirmLabel: 'Supprimer',
    );
    if (!confirmed) return;
    await _txService.deleteTransaction(widget.transaction.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final isIncome = t.type == TransactionType.revenu;
    final color = isIncome ? AppColors.income : AppColors.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(isIncome ? 'Détail du revenu' : 'Détail de la dépense'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _editing = !_editing),
          ),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_editing) ...[
            Center(
              child: Text(
                CurrencyFormatter.formatSigned(t.amount, isIncome: isIncome),
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(height: 24),
            _infoRow('Description', t.description ?? '—'),
            _infoRow('Date', DateFormatter.long(t.date)),
            _infoRow('Moyen de paiement', t.paymentMethod),
            _infoRow('Note', t.note ?? '—'),
          ] else ...[
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant'),
            ),
            const SizedBox(height: 16),
            if (_categories.isNotEmpty)
              CategorySelector(
                categories: _categories,
                selectedId: _categoryId,
                onSelected: (id) => setState(() => _categoryId = id),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Text(DateFormatter.short(_date)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(labelText: 'Moyen de paiement'),
              items: paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('ENREGISTRER LES MODIFICATIONS'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLight)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
