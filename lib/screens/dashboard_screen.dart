// This file defines the DashboardScreen widget, which serves as the main dashboard for the application. It displays the user's cash balance, quick action buttons, statistics and charts, and recent activity. The screen uses Riverpod providers to fetch data such as balance, transactions, forex rates, goals, attendance records, and driver trips. It adapts its content based on whether the user is a heavy vehicle driver or not, providing relevant information and actions accordingly.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_providers.dart';
import '../providers/forex_provider.dart';
import '../main.dart'; // import db
import 'goals_screen.dart';
import 'calendar_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final forexAsync = ref.watch(forexRateProvider);

    // Get username
    final users = db.getUsers();
    final username = users.isNotEmpty ? users.first.name : 'User';
    final isHeavy = users.isNotEmpty ? users.first.isHeavyVehicleDriver : false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Marhaba, $username',
                style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.5,
                    color: Colors.white)),
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
            expandedHeight: 280,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(top: 120, left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CASH BALANCE',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    balanceAsync.when(
                      data: (balance) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                balance.toStringAsFixed(2),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 2,
                                    height: 1),
                              ),
                              const SizedBox(width: 12),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text('AED',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                        fontWeight: FontWeight.normal)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          forexAsync.when(
                            data: (rate) {
                              final inrBalance = balance * rate;
                              return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.1)),
                                  ),
                                  child: Text(
                                      '≈ ₹ ${inrBalance.toStringAsFixed(2)}  (AED / INR : $rate)',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1)));
                            },
                            loading: () => const Text('Syncing market rates...',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            error: (_, __) => const Text('Forex offline',
                                style: TextStyle(
                                    color: Color(0xFFFF5252), fontSize: 12)),
                          ),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                      error: (err, stack) => const Text('Error loading balance',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QUICK ACTIONS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickAction(
                          icon: isHeavy
                              ? Icons.local_shipping
                              : Icons.access_time_filled,
                          color: const Color(0xFF64FFDA),
                          label: isHeavy ? 'Trips' : 'Check In',
                          onTap: () => context.go('/attendance')),
                      _QuickAction(
                          icon: Icons.account_balance_wallet,
                          color: const Color(0xFF536DFE),
                          label: 'Ledger',
                          onTap: () => context.go('/finance')),
                      _QuickAction(
                          icon: Icons.currency_rupee,
                          color: const Color(0xFF69F0AE),
                          label: 'Transfer',
                          onTap: () => context.push('/transfers')),
                      _QuickAction(
                          icon: Icons.monetization_on,
                          color: Colors.white.withValues(alpha: 0.8),
                          label: 'Gold',
                          onTap: () => context.push('/gold')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('STATISTICS & CHARTS',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                  _DashboardCharts(ref: ref, isHeavy: isHeavy),
                  const SizedBox(height: 32),
                  Text('RECENT ACTIVITY',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Transactions List
          transactionsAsync.when(
            data: (transactions) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final t = transactions[index];
                  final isIncome = t.type == 'income';
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: isIncome
                                  ? const Color(0xFF69F0AE)
                                  : const Color(0xFFFF5252),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.category,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        fontSize: 14,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(DateFormat('MMM dd, yyyy').format(t.date),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2)),
                              ],
                            ),
                          ),
                          Text(
                            '${isIncome ? '+' : '-'}${t.amount.toStringAsFixed(2)} ${t.currency}',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: isIncome
                                    ? const Color(0xFF69F0AE)
                                    : Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: transactions.length > 5
                    ? 5
                    : transactions.length, // Show up to 5
              ),
            ),
            loading: () => const SliverToBoxAdapter(
                child: Center(
                    child: CircularProgressIndicator(color: Colors.white))),
            error: (err, stack) => const SliverToBoxAdapter(
                child: Text('Error loading transactions',
                    style: TextStyle(color: Colors.red))),
          ),
        ],
      ),
    );
  }
}

class _DashboardCharts extends StatelessWidget {
  final WidgetRef ref;
  final bool isHeavy;
  const _DashboardCharts({required this.ref, required this.isHeavy});

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final attendanceAsync = ref.watch(calendarProvider);
    final driverTripsAsync = ref.watch(driverTripsListProvider);

    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Expenses Pie Chart
          Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: Column(
              children: [
                Text('Expenses',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.5))),
                const SizedBox(height: 10),
                Expanded(
                    child: transactionsAsync.when(
                  data: (transactions) {
                    final expenses =
                        transactions.where((t) => t.type == 'expense');
                    if (expenses.isEmpty)
                      return const Center(
                          child: Text('No Data',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.white)));
                    final Map<String, double> catSum = {};
                    for (var e in expenses) {
                      catSum[e.category] = (catSum[e.category] ?? 0) + e.amount;
                    }
                    final List<PieChartSectionData> sections = [];
                    final colors = [
                      const Color(0xFFFF5252),
                      Colors.orangeAccent,
                      Colors.white,
                      const Color(0xFF448AFF),
                      Colors.purpleAccent,
                      Colors.cyanAccent
                    ];
                    int i = 0;
                    catSum.forEach((cat, amt) {
                      sections.add(PieChartSectionData(
                          color: colors[i % colors.length],
                          value: amt,
                          title: cat,
                          radius: 40,
                          titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: const Color(0xFF0A0A0A))));
                      i++;
                    });
                    return PieChart(PieChartData(
                        sections: sections, centerSpaceRadius: 20));
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                  error: (_, __) => const Center(
                      child:
                          Text('Error', style: TextStyle(color: Colors.red))),
                )),
              ],
            ),
          ),
          // Goals Chart
          Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: Column(
              children: [
                Text('Goals Progress',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.5))),
                const SizedBox(height: 10),
                Expanded(
                    child: goalsAsync.when(
                  data: (goals) {
                    if (goals.isEmpty)
                      return const Center(
                          child: Text('No Data',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.white)));
                    double totalTarget = 0;
                    double totalCurrent = 0;
                    for (var g in goals) {
                      totalTarget += g.targetAmount;
                      totalCurrent += g.currentAmount;
                    }
                    final double toGo =
                        (totalTarget - totalCurrent).clamp(0, double.infinity);
                    return PieChart(PieChartData(sections: [
                      PieChartSectionData(
                          color: const Color(0xFF69F0AE),
                          value: totalCurrent,
                          title: 'Saved',
                          radius: 40,
                          titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: const Color(0xFF0A0A0A))),
                      PieChartSectionData(
                          color: const Color(0xFF202020),
                          value: toGo > 0 ? toGo : 1,
                          title: 'To Go',
                          radius: 40,
                          titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Colors.white)),
                    ], centerSpaceRadius: 20));
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                  error: (_, __) => const Center(
                      child:
                          Text('Error', style: TextStyle(color: Colors.red))),
                )),
              ],
            ),
          ),
          // Duty vs Overtime
          Container(
            width: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: Column(
              children: [
                Text(isHeavy ? 'Trips Recorded' : 'Duty Time (Hrs)',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.5))),
                const SizedBox(height: 10),
                Expanded(
                    child: isHeavy
                        ? driverTripsAsync.when(
                            data: (trips) {
                              if (trips.isEmpty)
                                return const Center(
                                    child: Text('No Data',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white)));
                              return Center(
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                    const Icon(Icons.local_shipping,
                                        size: 48, color: Colors.white),
                                    const SizedBox(height: 8),
                                    Text('${trips.length}',
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.2,
                                            color: Colors.white)),
                                  ]));
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white)),
                            error: (_, __) => const Center(
                                child: Text('Error',
                                    style: TextStyle(color: Colors.red))),
                          )
                        : attendanceAsync.when(
                            data: (attendances) {
                              if (attendances.isEmpty)
                                return const Center(
                                    child: Text('No Data',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white)));
                              double regHours = 0;
                              double otHours = 0;
                              for (var a in attendances) {
                                regHours += a.dutyHours;
                                otHours += a.otHours;
                              }
                              return PieChart(PieChartData(sections: [
                                if (regHours > 0)
                                  PieChartSectionData(
                                      color: const Color(0xFF536DFE),
                                      value: regHours,
                                      title: 'Reg',
                                      radius: 40,
                                      titleStyle: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                          color: const Color(0xFF0A0A0A))),
                                if (otHours > 0)
                                  PieChartSectionData(
                                      color: Colors.deepOrangeAccent,
                                      value: otHours,
                                      title: 'OT',
                                      radius: 40,
                                      titleStyle: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                          color: const Color(0xFF0A0A0A))),
                                if (regHours == 0 && otHours == 0)
                                  PieChartSectionData(
                                      color: const Color(0xFF202020),
                                      value: 1,
                                      title: '0',
                                      radius: 40)
                              ], centerSpaceRadius: 20));
                            },
                            loading: () => const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white)),
                            error: (_, __) => const Center(
                                child: Text('Error',
                                    style: TextStyle(color: Colors.red))),
                          )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF0A0A0A).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ]),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white70)),
        ],
      ),
    );
  }
}
