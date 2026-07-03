// This file defines the GoalsScreen widget, which allows users to manage their financial goals. Users can create new goals, add progress towards existing goals, withdraw funds from goals back to their wallet, and view detailed information about each goal. The screen uses Riverpod providers to fetch goals and transactions from the database and displays them in a user-friendly interface. It also includes functionality to generate a PDF report of a specific goal's details and transactions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../db/models.dart';
import '../main.dart'; // db
import '../providers/app_providers.dart';
import '../providers/forex_provider.dart';

final goalsProvider = StreamProvider<List<Goal>>((ref) async* {
  final query = db.watchGoals();
  await for (final goals in query) {
    yield goals;
  }
});

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  bool _showAdd = false;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'Savings';
  final _types = ['Savings', 'India Transfer', 'Return Home', 'Gold Purchase'];

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _titleController.text.isEmpty) return;

    final goal = Goal(
        title: _titleController.text,
        type: _type,
        targetAmount: amount,
        currentAmount: 0,
        deadline: DateTime.now().add(const Duration(days: 90)));
    await db.putGoal(goal);

    setState(() {
      _showAdd = false;
      _titleController.clear();
      _amountController.clear();
    });
  }

  Future<void> _deleteGoal(Goal goal) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text(
            'Are you sure you want to delete this goal?\n\nIf you have saved money (AED ${goal.currentAmount}), it will be transferred back to your Wallet.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                if (goal.currentAmount > 0) {
                  final transaction = AppTransaction(
                      type: 'income',
                      amount: goal.currentAmount,
                      currency: 'AED',
                      category: 'Goal Refund',
                      date: DateTime.now(),
                      description: 'Refund from deleted goal: ${goal.title}',
                      notes: 'Goal was deleted');
                  await db.putTransaction(transaction);
                }
                await db.deleteGoal(goal.id!);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Goal deleted and funds returned to wallet')));
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _addProgress(Goal goal) async {
    final controller = TextEditingController();
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Add Money',
                  style: TextStyle(color: Colors.amber)),
              backgroundColor: Colors.grey.shade900,
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (AED)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.5))),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber)),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    final amount = double.tryParse(controller.text);
                    if (amount != null && amount > 0) {
                      final currentBalance =
                          ref.read(balanceProvider).value ?? 0.0;
                      if (amount > currentBalance) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Insufficient wallet balance')));
                        }
                        return;
                      }

                      final actualAdded =
                          (goal.targetAmount - goal.currentAmount)
                              .clamp(0.0, amount);
                      if (actualAdded <= 0) {
                        if (mounted) Navigator.pop(context);
                        return;
                      }

                      goal.currentAmount += actualAdded;
                      await db.putGoal(goal);

                      final transaction = AppTransaction(
                          type: 'transfer',
                          amount: actualAdded,
                          currency: 'AED',
                          category: 'Goal Transfer',
                          date: DateTime.now(),
                          description: 'Transfer to goal: ${goal.title}',
                          notes: 'Auto-deducted from wallet');
                      await db.putTransaction(transaction);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Add'),
                )
              ],
            ));
  }

  Future<void> _withdrawFromGoal(Goal goal) async {
    final controller = TextEditingController();
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Withdraw to Wallet',
                  style: TextStyle(color: Colors.amber)),
              backgroundColor: Colors.grey.shade900,
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount (AED)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.amber.withValues(alpha: 0.5))),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber)),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black),
                  onPressed: () async {
                    final amount = double.tryParse(controller.text);
                    if (amount != null && amount > 0) {
                      if (amount > goal.currentAmount) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Cannot withdraw more than goal balance',
                                      style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.red));
                        }
                        return;
                      }

                      goal.currentAmount -= amount;
                      await db.putGoal(goal);

                      final transaction = AppTransaction(
                          type: 'income',
                          amount: amount,
                          currency: 'AED',
                          category: 'Goal Withdrawal',
                          date: DateTime.now(),
                          description: 'Withdrawal from goal: ${goal.title}',
                          notes: 'Transferred back to wallet');
                      await db.putTransaction(transaction);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Withdraw'),
                )
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final forexAsync = ref.watch(forexRateProvider);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Financial Goals',
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
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3))),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Live Exchange Rate:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            forexAsync.when(
                              data: (rate) => Text('1 AED = $rate INR',
                                  style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold)),
                              loading: () => const Text('fetching...',
                                  style: TextStyle(color: Colors.grey)),
                              error: (_, __) => const Text('offline',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Goal Title',
                              labelStyle:
                                  TextStyle(color: Colors.amber.shade200),
                              enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade800)),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber)),
                            )),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _type,
                          dropdownColor: Colors.grey.shade900,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.grey.shade800)),
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.amber)),
                          ),
                          items: _types
                              .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Target Amount (AED)',
                              labelStyle:
                                  TextStyle(color: Colors.amber.shade200),
                              enabledBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade800)),
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
                          child: const Text('Create Goal',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            goalsAsync.when(
              data: (goals) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final g = goals[index];
                    // Filter out the Gold Accumulation goal created by GoldScreen if we want, or display it identically. But the goal type is 'gold'.
                    if (g.type == 'gold') return const SizedBox.shrink();

                    final pct = g.targetAmount > 0
                        ? (g.currentAmount / g.targetAmount).clamp(0.0, 1.0)
                        : 0.0;
                    return Card(
                        color: Colors.grey.shade900,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade800)),
                        clipBehavior: Clip.antiAlias,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        GoalDetailsScreen(goal: g)));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: Text(g.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white))),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _deleteGoal(g),
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.redAccent),
                                          tooltip: 'Delete Goal',
                                        ),
                                        IconButton(
                                          onPressed: () => _withdrawFromGoal(g),
                                          icon: Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.orange.shade300),
                                          tooltip: 'Withdraw to Wallet',
                                        ),
                                        IconButton(
                                          onPressed: () => _addProgress(g),
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.amber),
                                          tooltip: 'Add Money',
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${(pct * 100).toInt()}%',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 32,
                                            color: Colors.amber)),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                            '${g.currentAmount} / ${g.targetAmount} AED',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        forexAsync.when(
                                          data: (rate) => Text(
                                              '≈ ₹${(g.currentAmount * rate).toStringAsFixed(0)} / ₹${(g.targetAmount * rate).toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12)),
                                          loading: () =>
                                              const SizedBox.shrink(),
                                          error: (_, __) =>
                                              const SizedBox.shrink(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  height: 12,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: pct,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [
                                          Colors.amberAccent,
                                          Colors.orangeAccent
                                        ]),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ));
                  },
                  childCount: goals.length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.amber))),
              error: (err, stack) => const SliverToBoxAdapter(
                  child: Center(
                      child: Text('Error loading goals',
                          style: TextStyle(color: Colors.red)))),
            )
          ],
        ));
  }
}

class GoalDetailsScreen extends ConsumerWidget {
  final Goal goal;
  const GoalDetailsScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final forexAsync = ref.watch(forexRateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Goal Details',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF',
            onPressed: () => _generateGoalPdf(
                goal, transactionsAsync.value ?? [], forexAsync.value),
          )
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade900,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Type: ${goal.type}',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.amber)),
                    ),
                    const SizedBox(height: 16),
                    Text('Target: ${goal.targetAmount.toStringAsFixed(2)} AED',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white70)),
                    Text('Saved: ${goal.currentAmount.toStringAsFixed(2)} AED',
                        style: const TextStyle(
                            fontSize: 18,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold)),
                    if (forexAsync.value != null)
                      Text(
                          'Approx. Value (INR): ₹${(goal.currentAmount * forexAsync.value!).toStringAsFixed(0)} / ₹${(goal.targetAmount * forexAsync.value!).toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white54)),
                    const SizedBox(height: 32),
                    const Text('Transactions History',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: Colors.amber)),
                    const SizedBox(height: 12),
                  ]),
            ),
          ),
          transactionsAsync.when(
            data: (transactions) {
              final goalTransactions = transactions
                  .where((t) =>
                      (t.category == 'Goal Transfer' &&
                          t.description == 'Transfer to goal: ${goal.title}') ||
                      (t.category == 'Goal Withdrawal' &&
                          t.description ==
                              'Withdrawal from goal: ${goal.title}') ||
                      (t.category == 'Goal Refund' &&
                          t.description ==
                              'Refund from deleted goal: ${goal.title}'))
                  .toList();

              if (goalTransactions.isEmpty) {
                return const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No transactions yet.',
                                style: TextStyle(color: Colors.grey)))));
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final t = goalTransactions[index];
                    final isAddition = t.category == 'Goal Transfer';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isAddition
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        child: Icon(
                            isAddition ? Icons.add_circle : Icons.remove_circle,
                            color: isAddition
                                ? Colors.greenAccent
                                : Colors.redAccent),
                      ),
                      title: Text(t.description ?? 'Goal Activity',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          DateFormat('MMM dd, yyyy - HH:mm').format(t.date),
                          style: const TextStyle(color: Colors.white54)),
                      trailing: Text(
                        '${isAddition ? '+' : '-'}${t.amount.toStringAsFixed(2)} AED',
                        style: TextStyle(
                            color: isAddition
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    );
                  },
                  childCount: goalTransactions.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
                child: Center(
                    child: CircularProgressIndicator(color: Colors.amber))),
            error: (_, __) => const SliverToBoxAdapter(
                child: Center(
                    child: Text('Error loading transactions',
                        style: TextStyle(color: Colors.red)))),
          )
        ],
      ),
    );
  }

  Future<void> _generateGoalPdf(Goal goal, List<AppTransaction> allTransactions,
      double? forexRate) async {
    final pdf = pw.Document();

    final goalTransactions = allTransactions
        .where((t) =>
            (t.category == 'Goal Transfer' &&
                t.description == 'Transfer to goal: ${goal.title}') ||
            (t.category == 'Goal Withdrawal' &&
                t.description == 'Withdrawal from goal: ${goal.title}'))
        .toList();

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('GOAL REPORT',
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.orange900)),
                    pw.SizedBox(height: 20),
                    pw.Text('Title: ${goal.title}',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.Text('Type: ${goal.type}',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.Text(
                        'Target Amount: ${goal.targetAmount.toStringAsFixed(2)} AED',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.Text(
                        'Saved Amount: ${goal.currentAmount.toStringAsFixed(2)} AED',
                        style:
                            pw.TextStyle(fontSize: 16, color: PdfColors.green)),
                    if (forexRate != null)
                      pw.Text(
                          'Approx. Target (INR): ₹${(goal.targetAmount * forexRate).toStringAsFixed(0)}',
                          style: pw.TextStyle(
                              fontSize: 14, color: PdfColors.grey700)),
                    if (forexRate != null)
                      pw.Text(
                          'Approx. Saved (INR): ₹${(goal.currentAmount * forexRate).toStringAsFixed(0)}',
                          style: pw.TextStyle(
                              fontSize: 14, color: PdfColors.grey700)),
                    pw.SizedBox(height: 40),
                    pw.Text('TRANSACTION HISTORY',
                        style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey800)),
                    pw.SizedBox(height: 10),
                    pw.Table(border: pw.TableBorder.all(), columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FlexColumnWidth(2),
                    }, children: [
                      pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Date',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Description',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Amount (AED)',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                          ]),
                      ...goalTransactions.map((t) {
                        final isAddition = t.category == 'Goal Transfer';
                        return pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(DateFormat('MM-dd-yyyy HH:mm')
                                  .format(t.date))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(t.description ?? 'Goal Activity')),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  '${isAddition ? '+' : '-'}${t.amount.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                      color: isAddition
                                          ? PdfColors.green
                                          : PdfColors.red,
                                      fontWeight: pw.FontWeight.bold))),
                        ]);
                      }).toList(),
                    ]),
                    pw.SizedBox(height: 40),
                    pw.Text(
                        'This is a system generated report and requires no signature.',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ]));
        }));

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
