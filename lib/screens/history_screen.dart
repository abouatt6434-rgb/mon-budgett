import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/export_service.dart';
import '../services/transaction_service.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _txService = TransactionService();
  final _exportService = ExportService();
  final _searchController = TextEditingController();

  List<TransactionModel> _transactions = [];
  Map<String, CategoryModel> _categoriesById = {};
  TransactionType? _typeFilter;
  String? _categoryFilter;
  String? _paymentFilter;
  String _sortBy = 'date DESC';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final txs = await _txService.search(
      query: _searchController.text,
      type: _typeFilter,
      categoryId: _categoryFilter,
      paymentMethod: _paymentFilter,
      orderBy: _sortBy,
    );

    final cats = <String, CategoryModel>{};
    for (final t in txs) {
      if (!cats.containsKey(t.categoryId)) {
        final c = await _txService.getCategoryById(t.categoryId);
        if (c != null) cats[t.categoryId] = c;
      }
    }

    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _categoriesById = cats;
      _loading = false;
    });
  }

  Future<void> _openFilters() async {
    final expenseCats = await _txService.getCategories(TransactionType.depense);
    final incomeCats = await _txService.getCategories(TransactionType.revenu);
    final allCats = [...expenseCats, ...incomeCats];

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtrer les opérations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  const Text('Type'),
                  Wrap(spacing: 8, children: [
                    ChoiceChip(
                      label: const Text('Tous'),
                      selected: _typeFilter == null,
                      onSelected: (_) => setModalState(() => _typeFilter = null),
                    ),
                    ChoiceChip(
                      label: const Text('Dépenses'),
                      selected: _typeFilter == TransactionType.depense,
                      onSelected: (_) => setModalState(() => _typeFilter = TransactionType.depense),
                    ),
                    ChoiceChip(
                      label: const Text('Revenus'),
                      selected: _typeFilter == TransactionType.revenu,
                      onSelected: (_) => setModalState(() => _typeFilter = TransactionType.revenu),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const Text('Catégorie'),
                  DropdownButton<String?>(
                    isExpanded: true,
                    value: _categoryFilter,
                    hint: const Text('Toutes les catégories'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Toutes les catégories')),
                      ...allCats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setModalState(() => _categoryFilter = v),
                  ),
                  const SizedBox(height: 16),
                  const Text('Moyen de paiement'),
                  DropdownButton<String?>(
                    isExpanded: true,
                    value: _paymentFilter,
                    hint: const Text('Tous'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tous')),
                      ...paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                    ],
                    onChanged: (v) => setModalState(() => _paymentFilter = v),
                  ),
                  const SizedBox(height: 16),
                  const Text('Trier par'),
                  Wrap(spacing: 8, children: [
                    ChoiceChip(
                      label: const Text('Date (récent)'),
                      selected: _sortBy == 'date DESC',
                      onSelected: (_) => setModalState(() => _sortBy = 'date DESC'),
                    ),
                    ChoiceChip(
                      label: const Text('Montant'),
                      selected: _sortBy == 'amount DESC',
                      onSelected: (_) => setModalState(() => _sortBy = 'amount DESC'),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: const Text('Appliquer'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exporter en CSV',
            onPressed: _transactions.isEmpty
                ? null
                : () => _exportService.shareCsv(_transactions),
          ),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _openFilters),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une opération...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _load(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const EmptyState(
                        title: 'Aucune opération trouvée',
                        subtitle: 'Essayez de modifier vos filtres ou votre recherche.',
                        icon: Icons.search_off,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _transactions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final t = _transactions[i];
                            return TransactionTile(
                              transaction: t,
                              category: _categoriesById[t.categoryId],
                              onTap: () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(builder: (_) => TransactionDetailScreen(transaction: t)),
                                );
                                if (changed == true) _load();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
