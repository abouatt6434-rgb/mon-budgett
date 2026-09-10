import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category_model.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../widgets/category_selector.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType type;
  const AddTransactionScreen({super.key, required this.type});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _txService = TransactionService();

  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String _paymentMethod = paymentMethods.first;
  String? _receiptPath;
  bool _saving = false;

  bool get _isExpense => widget.type == TransactionType.depense;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _txService.getCategories(widget.type);
    setState(() {
      _categories = cats;
      if (cats.isNotEmpty) _selectedCategoryId = cats.first.id;
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickReceipt() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (file != null) setState(() => _receiptPath = file.path);
    } catch (_) {
      // La photo de reçu est facultative : on ignore silencieusement si
      // l'appareil ne supporte pas la sélection d'image.
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie.')),
      );
      return;
    }

    setState(() => _saving = true);
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    await _txService.addTransaction(
      type: widget.type,
      amount: amount,
      categoryId: _selectedCategoryId!,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      date: _selectedDate,
      paymentMethod: _paymentMethod,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      receiptPath: _receiptPath,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isExpense ? 'Dépense enregistrée.' : 'Revenu enregistré.')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final color = _isExpense ? AppColors.expense : AppColors.income;

    return Scaffold(
      appBar: AppBar(title: Text(_isExpense ? 'Nouvelle dépense' : 'Nouveau revenu')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                hintText: '0',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir un montant.';
                }
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return 'Veuillez saisir un montant valide.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(_isExpense ? 'Catégorie' : 'Source du revenu',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _categories.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: LinearProgressIndicator(),
                  )
                : CategorySelector(
                    categories: _categories,
                    selectedId: _selectedCategoryId,
                    onSelected: (id) => setState(() => _selectedCategoryId = id),
                  ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (facultatif)'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}'),
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: InputDecoration(labelText: _isExpense ? 'Moyen de paiement' : 'Moyen de réception'),
              items: paymentMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (facultatif)'),
              maxLines: 2,
            ),
            if (_isExpense) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickReceipt,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(_receiptPath == null ? 'Ajouter une photo du reçu' : 'Reçu ajouté ✓'),
              ),
              if (_receiptPath != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_receiptPath!), height: 140, fit: BoxFit.cover),
                ),
              ],
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: _saving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isExpense ? 'ENREGISTRER LA DÉPENSE' : 'ENREGISTRER LE REVENU'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
