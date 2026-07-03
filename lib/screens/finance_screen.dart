// This file defines the FinanceScreen widget, which allows users to manage their financial transactions. Users can add income or expense entries, view a list of recent transactions, and see the current balance. The screen uses Riverpod providers to fetch transactions and forex rates from the database and external APIs.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../providers/forex_provider.dart';
import '../db/models.dart';
import '../main.dart'; // db import

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  bool _showAdd = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _type = 'expense';
  String _category = 'Shopping';

  final List<String> _categories = [
    'Mobile',
    'Shopping',
    'Food',
    'Transport',
    'Custom'
  ];

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    if (_type == 'expense' && amount > 0) {
      final currentBalance = ref.read(balanceProvider).value ?? 0.0;
      if (amount > currentBalance) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Insufficient balance.'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    final transaction = AppTransaction(
        type: _type,
        amount: amount,
        currency: 'AED',
        category: _category,
        description: _descController.text,
        date: DateTime.now());

    await db.putTransaction(transaction);

    setState(() {
      _showAdd = false;
      _amountController.clear();
      _descController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final forexAsync = ref.watch(forexRateProvider);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Ledger',
              style:
                  TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.amber),
          elevation: 0,
          actions: [
            IconButton(
              icon:
                  Icon(_showAdd ? Icons.close : Icons.add, color: Colors.amber),
              onPressed: () => setState(() => _showAdd = !_showAdd),
            )
          ],
        ),
        body: CustomScrollView(
          slivers: [
            if (_showAdd)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Add Entry',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.amber)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                                child: ChoiceChip(
                                    label: const Text('Expense'),
                                    selected: _type == 'expense',
                                    onSelected: (_) =>
                                        setState(() => _type = 'expense'),
                                    selectedColor:
                                        Colors.amber.withValues(alpha: 0.3),
                                    backgroundColor: Colors.black,
                                    labelStyle: TextStyle(
                                        color: _type == 'expense'
                                            ? Colors.amber
                                            : Colors.white))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: ChoiceChip(
                                    label: const Text('Income'),
                                    selected: _type == 'income',
                                    onSelected: (_) =>
                                        setState(() => _type = 'income'),
                                    selectedColor:
                                        Colors.amber.withValues(alpha: 0.3),
                                    backgroundColor: Colors.black,
                                    labelStyle: TextStyle(
                                        color: _type == 'income'
                                            ? Colors.amber
                                            : Colors.white))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: 'Amount (AED)',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.5))),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.3))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber))),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          dropdownColor: Colors.grey.shade900,
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                          onChanged: (val) => setState(() => _category = val!),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.5))),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.3))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber))),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                              labelText: 'Description (Optional)',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.5))),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.3))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber))),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Save Entry',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            transactionsAsync.when(
              data: (transactions) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final t = transactions[index];
                    final isIncome = t.type == 'income';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        child: Icon(
                          isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color:
                              isIncome ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ),
                      title: Text(t.category,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      subtitle: Text(
                          DateFormat('MMM dd, hh:mm a').format(t.date),
                          style: const TextStyle(color: Colors.white54)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isIncome ? '+' : '-'}${t.amount.toStringAsFixed(2)} AED',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIncome
                                    ? Colors.greenAccent
                                    : Colors.white70),
                          ),
                          forexAsync.when(
                            data: (rate) => Text(
                              '≈ ₹${(t.amount * rate).toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: transactions.length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.amber))),
              error: (err, stack) => const SliverToBoxAdapter(
                  child: Center(
                      child: Text('Failed to load ledger',
                          style: TextStyle(color: Colors.red)))),
            )
          ],
        ));
  }
}
