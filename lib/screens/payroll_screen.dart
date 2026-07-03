// This file defines the PayrollScreen widget, which displays a list of monthly payroll records for the user. It calculates expected and received salary amounts based on attendance records, driver trips, and transactions. The screen allows users to view detailed breakdowns of their payroll, receive salary payments, and generate PDF salary slips. It uses Riverpod providers to fetch data from the local database and updates automatically when data changes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:zenith/providers/app_providers.dart';
import 'package:zenith/screens/calendar_screen.dart';
import '../db/models.dart';
import '../main.dart'; // db

class MonthlyPayroll {
  final String monthYear;
  final String displayMonth;
  final double base;
  final double dutyHrs;
  final double dutyRate;
  final double dutyPay;
  final double otHrs;
  final double otRate;
  final double otPay;
  final int trips;
  final double tripRate;
  final double tripPay;
  final bool isHeavyVehicleDriver;
  final double expectedTotal;
  final double receivedTotal;
  final DateTime date;
  final List<DriverTrip> monthTrips;

  MonthlyPayroll({
    required this.monthYear,
    required this.displayMonth,
    required this.base,
    required this.dutyHrs,
    required this.dutyRate,
    required this.dutyPay,
    required this.otHrs,
    required this.otRate,
    required this.otPay,
    required this.trips,
    required this.tripRate,
    required this.tripPay,
    required this.isHeavyVehicleDriver,
    required this.expectedTotal,
    required this.receivedTotal,
    required this.date,
    required this.monthTrips,
  });

  double get discrepancy => expectedTotal - receivedTotal;
}

final payrollProvider = Provider<List<MonthlyPayroll>>((ref) {
  final users = db.getUsers();
  final user = users.isNotEmpty ? users.first : null;
  final isHeavy = user?.isHeavyVehicleDriver ?? false;

  // Watch streams so it updates automatically
  final allRecords = ref.watch(calendarProvider).value ?? [];
  final allTransactions = ref.watch(transactionsProvider).value ?? [];
  final allTrips = ref.watch(driverTripsListProvider).value ?? [];

  // Group attendances by monthYear "MM/yyyy"
  Map<String, List<Attendance>> recordsByMonth = {};
  for (var r in allRecords) {
    String my = DateFormat('MM/yyyy').format(r.date);
    recordsByMonth.putIfAbsent(my, () => []).add(r);
  }

  // Group driver trips by monthYear
  Map<String, List<DriverTrip>> tripsByMonth = {};
  for (var t in allTrips) {
    String my = DateFormat('MM/yyyy').format(t.date);
    tripsByMonth.putIfAbsent(my, () => []).add(t);
  }

  // ensure current month exists even if no attendance
  String currentMY = DateFormat('MM/yyyy').format(DateTime.now());
  recordsByMonth.putIfAbsent(currentMY, () => []);
  if (isHeavy) tripsByMonth.putIfAbsent(currentMY, () => []);

  // Set of all month keys
  Set<String> allMonths = {...recordsByMonth.keys, ...tripsByMonth.keys};

  // Group salary received transactions by monthYear (description)
  Map<String, double> receivedByMonth = {};
  for (var t in allTransactions) {
    if (t.category == 'Salary' && t.description != null) {
      receivedByMonth[t.description!] =
          (receivedByMonth[t.description!] ?? 0) + t.amount;
    }
  }

  List<MonthlyPayroll> list = [];

  for (var my in allMonths) {
    List<Attendance> monthRecords = recordsByMonth[my] ?? [];
    List<DriverTrip> monthTrips = tripsByMonth[my] ?? [];

    double totalDutyHrs = 0;
    double totalOtHrs = 0;

    for (var r in monthRecords) {
      totalDutyHrs += r.dutyHours;
      totalOtHrs += r.otHours;
    }

    int totalTrips = monthTrips.length;
    double calculatedTripPay = 0;
    for (var t in monthTrips) {
      calculatedTripPay += t.allowance;
    }

    int m = int.parse(my.substring(0, 2));
    int y = int.parse(my.substring(3, 7));
    String displayMonth = DateFormat('MMMM yyyy').format(DateTime(y, m));

    double base = user?.fixedSalary ?? 1500.0;

    // Calculate prorated salary if joining date is in this month
    if (user != null && user.joiningDate != null) {
      final jd = user.joiningDate!;
      if (jd.year == y && jd.month == m) {
        int daysInMonth =
            DateTime(y, m + 1, 0).day; // Number of days in the month
        int workedDays = daysInMonth - jd.day + 1; // Inclusive worked days
        base = (base / daysInMonth) * workedDays;
      } else if (DateTime(y, m, 1).isBefore(DateTime(jd.year, jd.month, 1))) {
        base = 0.0; // Salary for months before joining date is 0
      }
    }

    final dutyRate = user?.dutyRatePerHour ?? 5.0;
    final otRate = user?.otRatePerHour ?? 5.0;
    final tripRate = user?.tripRate ?? 0.0;

    final dutyPay = isHeavy ? 0.0 : totalDutyHrs * dutyRate;
    final otPay = isHeavy ? 0.0 : totalOtHrs * otRate;
    final tripPay = isHeavy ? calculatedTripPay : 0.0;
    final expectedTotal = base + dutyPay + otPay + tripPay;
    final receivedTotal = receivedByMonth[my] ?? 0.0;

    list.add(MonthlyPayroll(
      monthYear: my,
      displayMonth: displayMonth,
      base: base,
      dutyHrs: totalDutyHrs,
      dutyRate: dutyRate,
      dutyPay: dutyPay,
      otHrs: totalOtHrs,
      otRate: otRate,
      otPay: otPay,
      trips: totalTrips,
      tripRate: tripRate, // Not strictly used for math anymore but nice to pass
      tripPay: tripPay,
      isHeavyVehicleDriver: isHeavy,
      expectedTotal: expectedTotal,
      receivedTotal: receivedTotal,
      date: DateTime(y, m),
      monthTrips: monthTrips,
    ));
  }

  // sort descending by date
  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
});

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  Future<void> _showSettingsDialog(BuildContext context, WidgetRef ref) async {
    final users = db.getUsers();
    if (users.isEmpty) return;
    final user = users.first;

    final baseController =
        TextEditingController(text: user.fixedSalary.toString());
    final dutyController =
        TextEditingController(text: user.dutyRatePerHour.toString());
    final otController =
        TextEditingController(text: user.otRatePerHour.toString());
    bool isHeavy = user.isHeavyVehicleDriver;
    DateTime? selectedJoiningDate = user.joiningDate;

    await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  backgroundColor: const Color(0xFF141414),
                  title: const Text('Salary Structure',
                      style: TextStyle(color: Colors.white)),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile(
                          title: const Text('Heavy Vehicle Driver',
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text('Paid via Basic + Trips',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12)),
                          value: isHeavy,
                          activeThumbColor: Colors.white,
                          onChanged: (val) => setState(() => isHeavy = val),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          title: const Text('Joining Date',
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text(
                              selectedJoiningDate != null
                                  ? DateFormat('MMMM dd, yyyy')
                                      .format(selectedJoiningDate!)
                                  : 'Not set',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5))),
                          trailing: const Icon(Icons.calendar_today,
                              color: Colors.white),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  selectedJoiningDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => selectedJoiningDate = date);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: baseController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(),
                          decoration: InputDecoration(
                            labelText: 'Basic Salary (AED)',
                            labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7)),
                            enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color:
                                        Colors.white.withValues(alpha: 0.5))),
                            focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white)),
                          ),
                        ),
                        if (!isHeavy) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: dutyController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(),
                            decoration: InputDecoration(
                              labelText: 'Duty Rate / Hour (AED)',
                              labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7)),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.5))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: otController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            style: const TextStyle(),
                            decoration: InputDecoration(
                              labelText: 'OT Rate / Hour (AED)',
                              labelStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7)),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.5))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7)))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0A0A0A)),
                      onPressed: () async {
                        user.isHeavyVehicleDriver = isHeavy;
                        user.joiningDate = selectedJoiningDate;
                        user.fixedSalary =
                            double.tryParse(baseController.text) ?? 1500.0;
                        user.dutyRatePerHour =
                            double.tryParse(dutyController.text) ?? 5.0;
                        user.otRatePerHour =
                            double.tryParse(otController.text) ?? 5.0;
                        await db.putUser(user);
                        ref.invalidate(payrollProvider);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                )));
  }

  Future<void> _showReceiveSalaryDialog(
      BuildContext context, WidgetRef ref, MonthlyPayroll item) async {
    final controller = TextEditingController(
        text: item.discrepancy > 0 ? item.discrepancy.toStringAsFixed(2) : '');
    await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF141414),
              title: Text('Receive Salary - ${item.displayMonth}',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              content: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(),
                decoration: InputDecoration(
                  labelText: 'Amount Received (AED)',
                  labelStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.5))),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white)),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7)))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0A0A0A)),
                  onPressed: () async {
                    final amt = double.tryParse(controller.text) ?? 0;
                    if (amt > 0) {
                      final t = AppTransaction(
                        type: 'income',
                        amount: amt,
                        currency: 'AED',
                        category: 'Salary',
                        description: item.monthYear,
                        date: DateTime.now(),
                      );
                      await db.putTransaction(t);
                      ref.invalidate(payrollProvider);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Added $amt AED to Wallet!'),
                            backgroundColor: Colors.green));
                      }
                    }
                  },
                  child: const Text('Save to Wallet',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollList = ref.watch(payrollProvider);

    return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Payroll Verification',
              style: TextStyle(
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.5,
                  color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => _showSettingsDialog(context, ref),
            )
          ],
        ),
        body: RefreshIndicator(
            color: Colors.white,
            onRefresh: () async {
              ref.invalidate(calendarProvider);
              ref.invalidate(transactionsProvider);
              ref.invalidate(driverTripsListProvider);
              ref.invalidate(payrollProvider);
            },
            child: payrollList.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 200),
                    Center(
                        child: Text('No attendance or payroll data yet.',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5)))),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: payrollList.length,
                    itemBuilder: (context, index) {
                      final item = payrollList[index];
                      final isAllReceived = item.discrepancy <= 0;
                      return Card(
                          color: Colors.white.withValues(alpha: 0.05),
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                  iconColor: Colors.white,
                                  collapsedIconColor: Colors.white54,
                                  title: Text(item.displayMonth,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                          color: Colors.white,
                                          fontSize: 18)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 12.0, bottom: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Expected',
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.5),
                                                      fontSize: 11)),
                                              const SizedBox(height: 4),
                                              Text(
                                                  '${item.expectedTotal.toStringAsFixed(0)} AED',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 1.2,
                                                      fontSize: 14)),
                                            ]),
                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Received',
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.5),
                                                      fontSize: 11)),
                                              const SizedBox(height: 4),
                                              Text(
                                                  '${item.receivedTotal.toStringAsFixed(0)} AED',
                                                  style: const TextStyle(
                                                      color: const Color(
                                                          0xFF69F0AE),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 1.2,
                                                      fontSize: 14)),
                                            ]),
                                        Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Discrepancy',
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.5),
                                                      fontSize: 11)),
                                              const SizedBox(height: 4),
                                              Text(
                                                  '${item.discrepancy > 0 ? item.discrepancy.toStringAsFixed(0) : '0'} AED',
                                                  style: TextStyle(
                                                      color:
                                                          item.discrepancy > 0
                                                              ? const Color(
                                                                  0xFFFF5252)
                                                              : Colors.white70,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 1.2,
                                                      fontSize: 14)),
                                            ]),
                                      ],
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(children: [
                                          Divider(
                                              color: Colors.white
                                                  .withValues(alpha: 0.15)),
                                          const SizedBox(height: 12),
                                          _row(
                                              'Base Salary',
                                              '${item.base.toStringAsFixed(2)} AED',
                                              Colors.white),
                                          const SizedBox(height: 8),
                                          if (!item.isHeavyVehicleDriver) ...[
                                            _row(
                                                'Duty Pay (${item.dutyHrs.toStringAsFixed(1)}h)',
                                                '+${item.dutyPay.toStringAsFixed(2)} AED',
                                                const Color(0xFF69F0AE)),
                                            const SizedBox(height: 8),
                                            _row(
                                                'Overtime Pay (${item.otHrs.toStringAsFixed(1)}h)',
                                                '+${item.otPay.toStringAsFixed(2)} AED',
                                                const Color(0xFF64FFDA)),
                                          ] else ...[
                                            _row(
                                                'Trip Allowance (${item.trips} trips)',
                                                '+${item.tripPay.toStringAsFixed(2)} AED',
                                                const Color(0xFF448AFF)),
                                          ],
                                          const SizedBox(height: 24),
                                          if (!isAllReceived) ...[
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _showReceiveSalaryDialog(
                                                      context, ref, item),
                                              icon: const Icon(
                                                  Icons.account_balance_wallet),
                                              label:
                                                  const Text('Receive Salary'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFF69F0AE),
                                                  foregroundColor:
                                                      const Color(0xFF0A0A0A),
                                                  minimumSize: const Size(
                                                      double.infinity, 44),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12))),
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                          ElevatedButton.icon(
                                            onPressed: () => _generatePdf(item),
                                            icon: const Icon(
                                                Icons.picture_as_pdf),
                                            label:
                                                const Text('Generate PDF Slip'),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor:
                                                    const Color(0xFF0A0A0A),
                                                minimumSize: const Size(
                                                    double.infinity, 44),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12))),
                                          )
                                        ]))
                                  ])));
                    })));
  }

  Future<void> _generatePdf(MonthlyPayroll item) async {
    final pdf = pw.Document();
    final users = db.getUsers();
    final username = users.isNotEmpty ? users.first.name : 'Employee';

    pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('SALARY SLIP',
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900)),
                    pw.SizedBox(height: 20),
                    pw.Text('Name: $username',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.Text('Month: ${item.displayMonth}',
                        style: pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(height: 40),
                    pw.Table(border: pw.TableBorder.all(), columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                    }, children: [
                      pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey300),
                          children: [
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
                      pw.TableRow(children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Base Salary')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item.base.toStringAsFixed(2))),
                      ]),
                      if (!item.isHeavyVehicleDriver) ...[
                        pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  'Duty Pay (${item.dutyHrs.toStringAsFixed(1)}h @ ${item.dutyRate})')),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(item.dutyPay.toStringAsFixed(2))),
                        ]),
                        pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  'Overtime Pay (${item.otHrs.toStringAsFixed(1)}h @ ${item.otRate})')),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(item.otPay.toStringAsFixed(2))),
                        ]),
                      ] else ...[
                        pw.TableRow(children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  'Trip Allowance (${item.trips} trips)')),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(item.tripPay.toStringAsFixed(2))),
                        ]),
                      ],
                      pw.TableRow(
                          decoration: const pw.BoxDecoration(
                              color: PdfColors.indigo100),
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('Total Expected Salary',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                    item.expectedTotal.toStringAsFixed(2),
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                          ]),
                      pw.TableRow(children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Received Salary')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                item.receivedTotal.toStringAsFixed(2),
                                style: const pw.TextStyle(
                                    color: PdfColors.green))),
                      ]),
                      pw.TableRow(children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Discrepancy (Pending)')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(item.discrepancy.toStringAsFixed(2),
                                style:
                                    const pw.TextStyle(color: PdfColors.red))),
                      ]),
                    ]),
                    pw.SizedBox(height: 40),
                    pw.Text(
                        'This is a system generated document and requires no signature.',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ]));
        }));

    if (item.isHeavyVehicleDriver && item.monthTrips.isNotEmpty) {
      pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Text('TRIP DETAILS LOG',
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900)),
              pw.SizedBox(height: 20),
              pw.Table(border: pw.TableBorder.all(), children: [
                pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Date/Time',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Vehicle',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Destination',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Cargo (t)',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Fuel',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Allowance',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                    ]),
                ...item.monthTrips.map((t) => pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              DateFormat('MM/dd hh:mm a').format(t.date),
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(t.vehicleNumber ?? '-',
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(t.destination,
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(t.cargoTonnage?.toString() ?? '-',
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(t.fuelProvided?.toString() ?? '-',
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(t.allowance.toStringAsFixed(2),
                              style: const pw.TextStyle(fontSize: 10))),
                    ]))
              ])
            ];
          }));
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _row(String label, String val, Color valColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        Text(val,
            style: TextStyle(
                color: valColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2)),
      ],
    );
  }
}
