// This file defines the GoldAccumulationScreen widget, which allows users to set a gold accumulation target, track their progress, and convert savings from other goals into gold based on live Dubai 24K gold rates. It uses Riverpod providers to fetch the current gold rate and interacts with the local database to manage goals and transactions. The screen provides a user-friendly interface with progress indicators, action buttons, and dialogs for adding goals and purchases.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/forex_provider.dart';
import '../db/models.dart';
import '../main.dart'; // To access global db
import 'package:intl/intl.dart';

class GoldAccumulationScreen extends ConsumerStatefulWidget {
  const GoldAccumulationScreen({super.key});

  @override
  ConsumerState<GoldAccumulationScreen> createState() =>
      _GoldAccumulationScreenState();
}

class _GoldAccumulationScreenState
    extends ConsumerState<GoldAccumulationScreen> {
  Goal? _goldGoal;
  double _goldSavingsAed = 0.0;
  List<Goal> _goldSavingGoals = [];

  @override
  void initState() {
    super.initState();
    _loadGoldGoal();
  }

  void _loadGoldGoal() {
    final goals = db.getGoals();
    final goldGoals = goals.where((g) => g.type == 'gold').toList();
    final savingsGoals = goals.where((g) => g.type == 'Gold Purchase').toList();

    double totalSavings = 0;
    for (var g in savingsGoals) {
      totalSavings += g.currentAmount;
    }

    if (mounted) {
      setState(() {
        _goldGoal = goldGoals.isNotEmpty ? goldGoals.first : null;
        _goldSavingsAed = totalSavings;
        _goldSavingGoals = savingsGoals;
      });
    }
  }

  void _showAddGoalDialog() {
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Gold Target',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter target in Grams (24K Gold)'),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. 50',
                hintStyle: const TextStyle(color: Colors.white54),
                suffixText: 'Grams',
                suffixStyle: const TextStyle(color: Colors.amber),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.amber.withValues(alpha: 0.5))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.amber.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.amber)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(targetController.text) ?? 0;
              if (val > 0) {
                final newGoal = Goal(
                  type: 'gold',
                  title: 'Gold Accumulation',
                  targetAmount: val, // Storing grams as targetAmount
                  currentAmount: 0,
                  deadline: DateTime.now().add(const Duration(days: 365)),
                );
                db.putGoal(newGoal);
                _loadGoldGoal();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.black),
            child: const Text('Set Goal',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _buyGoldWithSavings(double currentGoldRateAed) {
    if (_goldSavingsAed <= 0 || _goldGoal == null) return;
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Convert Savings to Gold',
                  style: TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
              content: Text(
                  'You have saved AED ${_goldSavingsAed.toStringAsFixed(2)} toward Gold Purchase goals.\n\nAt the current rate of AED ${currentGoldRateAed.toStringAsFixed(2)}/g, this buys:\n\n${(_goldSavingsAed / currentGoldRateAed).toStringAsFixed(2)} Grams',
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.grey.shade900,
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70))),
                ElevatedButton(
                  onPressed: () {
                    final gramsPurchased = _goldSavingsAed / currentGoldRateAed;
                    // Add grams to vault
                    _goldGoal!.currentAmount += gramsPurchased;
                    db.putGoal(_goldGoal!);

                    // Reset goal savings
                    for (var g in _goldSavingGoals) {
                      // We use a custom type so it doesn't deduct from wallet balance twice
                      final transaction = AppTransaction(
                        type: 'system',
                        amount: g.currentAmount,
                        currency: 'AED',
                        category: 'Gold Vault Conversion',
                        date: DateTime.now(),
                        description:
                            'Converted AED ${g.currentAmount.toStringAsFixed(2)} to Gold',
                      );
                      db.putTransaction(transaction);
                      g.currentAmount = 0;
                      db.putGoal(g);
                    }

                    _loadGoldGoal();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Bought ${gramsPurchased.toStringAsFixed(2)}g of Gold!')));
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text('Confirm Purchase',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ));
  }

  void _showAddGoldDialog() {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Gold',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter amount of Grams purchased:'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. 5.5',
                hintStyle: const TextStyle(color: Colors.white54),
                suffixText: 'Grams',
                suffixStyle: const TextStyle(color: Colors.amber),
                filled: true,
                fillColor: Colors.grey.shade900,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.amber.withValues(alpha: 0.5))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Colors.amber.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.amber)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountController.text) ?? 0;
              if (val > 0 && _goldGoal != null) {
                _goldGoal!.currentAmount += val;
                db.putGoal(_goldGoal!);
                _loadGoldGoal();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.black),
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goldRateAsync = ref.watch(goldRateProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Dark luxurious background
      appBar: AppBar(
        title: const Text('Gold Vault',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.amber),
            onPressed: () {
              if (_goldGoal != null) {
                // Option to delete or update target
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                            title: const Text('Reset Goal?'),
                            content: const Text(
                                'This will delete your current gold tracking.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () {
                                    db.deleteGoal(_goldGoal!.id!);
                                    _loadGoldGoal();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Reset',
                                      style: TextStyle(color: Colors.red))),
                            ]));
              }
            },
          )
        ],
      ),
      body: goldRateAsync.when(
        data: (rate) => _buildContent(rate),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (e, st) => Center(
            child: Text('Error loading live gold rates',
                style: TextStyle(color: Colors.red.shade300))),
      ),
    );
  }

  Widget _buildContent(double currentGoldRateAed) {
    if (_goldGoal == null) {
      // Empty State
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, size: 100, color: Colors.amber),
              const SizedBox(height: 24),
              const Text('Start Accumulating Gold',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                  'Secure your future by setting a gold accumulation target. Track your progress dynamically with live Dubai 24K gold rates.',
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey.shade400, height: 1.5),
                  textAlign: TextAlign.center),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _showAddGoalDialog,
                icon: const Icon(Icons.flag, color: Colors.black),
                label: const Text('Set Gold Target',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                    shadowColor: Colors.amber.withValues(alpha: 0.5)),
              )
            ],
          ),
        ),
      );
    }

    final accumulatedGrams = _goldGoal!.currentAmount;
    final targetGrams = _goldGoal!.targetAmount;
    final progress = targetGrams > 0
        ? (accumulatedGrams / targetGrams).clamp(0.0, 1.0)
        : 0.0;
    final accumulatedValueAed = accumulatedGrams * currentGoldRateAed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Rate Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Text('Live 24K Gold Rate',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                Text(
                  '${currentGoldRateAed.toStringAsFixed(2)} AED/g',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w900,
                      fontSize: 16),
                )
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Accumulated Big Text
          const Center(
            child: Text('TOTAL ACCUMULATED',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ),
          const SizedBox(height: 12),
          Center(
            child: RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: accumulatedGrams.toStringAsFixed(2),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      height: 1),
                ),
                const TextSpan(
                  text: ' g',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 32,
                      fontWeight: FontWeight.w900),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                '≈ ${NumberFormat("#,##0.00").format(accumulatedValueAed)} AED',
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 64),

          // Progress Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target: ${targetGrams.toStringAsFixed(1)} g',
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          // Custom Progress Bar
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amberAccent, Colors.orangeAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 1)
                    ]),
              ),
            ),
          ),
          const SizedBox(height: 48),

          if (_goldSavingsAed > 0) ...[
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.5))),
                child: Column(children: [
                  const Text('Goals Savings (AED) Ready to Buy Gold',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('AED ${_goldSavingsAed.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                      onPressed: () => _buyGoldWithSavings(currentGoldRateAed),
                      icon: const Icon(Icons.sync),
                      label: const Text('Convert Savings to Gold'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ))
                ])),
            const SizedBox(height: 24),
          ],

          // Action Button
          ElevatedButton.icon(
            onPressed: _showAddGoldDialog,
            icon: const Icon(Icons.add_circle, color: Colors.black, size: 28),
            label: const Text('Add Gold Purchase',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 10,
                shadowColor: Colors.amber.withValues(alpha: 0.4)),
          )
        ],
      ),
    );
  }
}
