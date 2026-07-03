// This file defines the PayrollScreen widget, which displays a list of monthly payroll records for the user. It calculates expected and received salary amounts based on attendance, overtime, and trip allowances. The screen allows users to view detailed breakdowns of their payroll, receive salary payments, and generate PDF salary slips. It uses Riverpod providers to fetch data from the local database and updates automatically when relevant data changes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../db/models.dart';
import '../main.dart';
import '../providers/forex_provider.dart';
import '../providers/app_providers.dart';

final transfersProvider = StreamProvider<List<AppTransaction>>((ref) async* {
  final query = db.watchTransactions();
  await for (final transactions in query) {
    final list =
        transactions.where((t) => t.category == 'Family Transfer').toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    yield list;
  }
});

class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  bool _showAdd = false;
  final _amountController = TextEditingController();
  final _rateController = TextEditingController(text: '22.50');
  final _descController = TextEditingController();

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text);
    final rate = double.tryParse(_rateController.text);
    if (amount == null || rate == null) return;

    if (amount > 0) {
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

    final t = AppTransaction(
      type: 'transfer',
      amount: amount,
      currency: 'AED',
      category: 'Family Transfer',
      description: _descController.text.isEmpty
          ? 'Transfer to India'
          : _descController.text,
      date: DateTime.now(),
      exchangeRate: rate,
      inrReceived: amount * rate,
    );
    await db.putTransaction(t);

    setState(() {
      _showAdd = false;
      _amountController.clear();
      _descController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transfersAsync = ref.watch(transfersProvider);
    final forexAsync = ref.watch(forexRateProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('India Transfers',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showAdd ? Icons.close : Icons.add, color: Colors.amber),
            onPressed: () => setState(() {
              _showAdd = !_showAdd;
              if (_showAdd) {
                final liveRate = ref.read(forexRateProvider).value;
                if (liveRate != null) {
                  _rateController.text = liveRate.toStringAsFixed(2);
                }
              }
            }),
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
                          color: Colors.amber.withValues(alpha: 0.3))),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Live Exchange Rate:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70)),
                          forexAsync.when(
                            data: (rate) => Text('1 AED = $rate INR',
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold)),
                            loading: () => const Text('loading...',
                                style: TextStyle(color: Colors.white54)),
                            error: (_, __) => const Text('offline',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _rateController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Exchange Rate',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.amber.withValues(alpha: 0.5))),
                          focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Bank Name / Notes',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.amber.withValues(alpha: 0.5))),
                          focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50)),
                        child: const Text('Save Transfer',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          transfersAsync.when(
            data: (transactions) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final t = transactions[index];
                  return ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                        child: const Icon(Icons.currency_rupee,
                            color: Colors.greenAccent)),
                    title: Text('₹ ${(t.inrReceived ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('MMM d, yyyy • h:mm a').format(t.date),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white54)),
                        Text('${t.description ?? ''} • @ ${t.exchangeRate}',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${t.amount.toStringAsFixed(2)} AED',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf,
                              color: Colors.amber),
                          onPressed: () => _generateTransferPdf(t),
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
                    child: Text('Error loading transfers',
                        style: TextStyle(color: Colors.red)))),
          )
        ],
      ),
    );
  }

  Future<void> _generateTransferPdf(AppTransaction t) async {
    final pdf = pw.Document();
    final users = db.getUsers();
    final username = users.isNotEmpty ? users.first.name : 'User';

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('TRANSFER RECEIPT',
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900)),
                    pw.SizedBox(height: 20),
                    pw.Text('From: $username',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.Text(
                        'Date: ${DateFormat('MMMM dd, yyyy - hh:mm a').format(t.date)}',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(height: 40),
                    pw.Table(border: pw.TableBorder.all(), columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(2),
                    }, children: [
                      pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Details',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Value',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                          ]),
                      pw.TableRow(children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Description/Notes')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(t.description ?? 'None')),
                      ]),
                      pw.TableRow(children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Amount Sent (AED)')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(t.amount.toStringAsFixed(2))),
                      ]),
                      pw.TableRow(children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Exchange Rate')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(t.exchangeRate != null
                                ? t.exchangeRate!.toStringAsFixed(4)
                                : 'N/A')),
                      ]),
                      pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.teal100),
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Amount Received (INR)',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                    t.inrReceived != null
                                        ? t.inrReceived!.toStringAsFixed(2)
                                        : 'N/A',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                          ]),
                    ]),
                    pw.SizedBox(height: 40),
                    pw.Text(
                        'This is a system generated receipt and requires no signature.',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ]));
        }));

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
