// This file defines the LoansScreen widget, which allows users to manage their loans and advances. Users can add new loan records, view existing records, and settle loans. The screen uses Riverpod providers to fetch loan data from the database and displays it in a user-friendly interface. It also handles transactions related to loans, ensuring that the user's balance is updated accordingly when loans are added or settled.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/models.dart';
import '../main.dart'; // db
import '../providers/app_providers.dart';

final loansProvider = StreamProvider<List<Loan>>((ref) async* {
  final query = db.watchLoans();
  await for (final loans in query) {
    yield loans;
  }
});

class LoansScreen extends ConsumerStatefulWidget {
  const LoansScreen({super.key});

  @override
  ConsumerState<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends ConsumerState<LoansScreen> {
  bool _showAdd = false;
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'Borrowed';
  final _types = ['Borrowed', 'Lent', 'Advance'];

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _personController.text.isEmpty) return;

    if (_type == 'Lent') {
      final currentBalance = ref.read(balanceProvider).value ?? 0.0;
      if (amount > currentBalance) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Insufficient balance to lend money.'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    final loan = Loan(
        person: _personController.text,
        amount: amount,
        type: _type,
        currency: 'AED',
        date: DateTime.now(),
        status: 'Pending');
    await db.putLoan(loan);

    String? transType;
    String desc = '';
    if (_type == 'Borrowed') {
      transType = 'income';
      desc = 'Borrowed money from ${_personController.text}';
    } else if (_type == 'Advance') {
      transType = 'income';
      desc = 'Received advance from ${_personController.text}';
    } else if (_type == 'Lent') {
      transType = 'transfer';
      desc = 'Lent money to ${_personController.text}';
    }

    if (transType != null) {
      final transaction = AppTransaction(
          type: transType,
          amount: amount,
          currency: 'AED',
          category: 'Loans & Advances',
          date: DateTime.now(),
          description: desc,
          notes: 'Initial record added to wallet');
      await db.putTransaction(transaction);
    }

    setState(() {
      _showAdd = false;
      _personController.clear();
      _amountController.clear();
    });
  }

  Future<void> _handleSettle(Loan loan) async {
    if (loan.status == 'Paid') return;

    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Settle Record?'),
                content: Text(
                    'Are you sure you want to settle this record for ${loan.amount} AED?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Confirm',
                          style: TextStyle(color: Colors.cyan))),
                ]));

    if (confirm != true) return;

    final loanToUpdate = await db.getLoan(loan.id!);
    if (loanToUpdate == null) return;

    if (loanToUpdate.type == 'Borrowed' || loanToUpdate.type == 'Advance') {
      final currentBalance = ref.read(balanceProvider).value ?? 0.0;
      if (loanToUpdate.amount > currentBalance) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Insufficient balance to settle this record.'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    loanToUpdate.status = 'Paid';
    await db.putLoan(loanToUpdate);

    String? transType;
    String desc = '';
    if (loanToUpdate.type == 'Borrowed') {
      transType = 'transfer';
      desc = 'Repaid borrowed money to ${loanToUpdate.person}';
    } else if (loanToUpdate.type == 'Advance') {
      transType = 'transfer';
      desc = 'Repaid advance to ${loanToUpdate.person}';
    } else if (loanToUpdate.type == 'Lent') {
      transType = 'income';
      desc = 'Received lent repayment from ${loanToUpdate.person}';
    }

    if (transType != null) {
      final transaction = AppTransaction(
          type: transType,
          amount: loanToUpdate.amount,
          currency: 'AED',
          category: 'Loans & Advances',
          date: DateTime.now(),
          description: desc,
          notes: 'Settled record added to wallet');
      await db.putTransaction(transaction);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loansProvider);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Loans & Advances',
              style:
                  TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.amber),
          elevation: 0,
          actions: [
            IconButton(
                icon: Icon(_showAdd ? Icons.close : Icons.add,
                    color: Colors.amber),
                onPressed: () => setState(() => _showAdd = !_showAdd))
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
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        TextField(
                            controller: _personController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Person Name',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.5))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber)),
                            )),
                        const SizedBox(height: 16),
                        Theme(
                          data: Theme.of(context)
                              .copyWith(canvasColor: Colors.grey.shade900),
                          child: DropdownButtonFormField<String>(
                            initialValue: _type,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.5))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber)),
                            ),
                            items: _types
                                .map((t) =>
                                    DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Amount (AED)',
                              labelStyle:
                                  const TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.5))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber)),
                            )),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50)),
                          child: const Text('Save Record',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            loansAsync.when(
              data: (loans) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final l = loans[index];
                    final isPaid = l.status == 'Paid';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white12)),
                      color: isPaid
                          ? Colors.grey.shade900.withValues(alpha: 0.5)
                          : Colors.grey.shade900,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isPaid
                                        ? Colors.amber
                                        : Colors.grey.shade800,
                                  ),
                                  child: isPaid
                                      ? const Icon(Icons.check,
                                          size: 16, color: Colors.black)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l.person,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: isPaid
                                                  ? Colors.white54
                                                  : Colors.white)),
                                      Text(l.type,
                                          style: TextStyle(
                                              color: isPaid
                                                  ? Colors.white30
                                                  : Colors.amber.shade300,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Text('${l.amount.toStringAsFixed(2)} AED',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isPaid
                                            ? Colors.white54
                                            : Colors.white)),
                              ],
                            ),
                            if (!isPaid) ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: Colors.white12),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _handleSettle(l),
                                  style: TextButton.styleFrom(
                                      backgroundColor:
                                          Colors.amber.withValues(alpha: 0.1),
                                      foregroundColor: Colors.amber,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          side: BorderSide(
                                              color: Colors.amber
                                                  .withValues(alpha: 0.3)))),
                                  child: Text(
                                      l.type == 'Borrowed'
                                          ? 'Pay Back'
                                          : l.type == 'Advance'
                                              ? 'Pay Back Advance'
                                              : 'Receive Money',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: loans.length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SliverToBoxAdapter(
                  child: Center(child: Text('Error loading loans'))),
            )
          ],
        ));
  }
}
