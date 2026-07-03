// This file defines various providers using Riverpod to manage state and data flow in the application. It includes providers for retrieving the current balance, today's attendance record, recent transactions, and driver trips. Each provider listens to changes in the database and yields updated values accordingly.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/models.dart';
import '../main.dart'; // To access global `db`

// Retrieves the current balance
final balanceProvider = StreamProvider<double>((ref) async* {
  final query = db.watchTransactions();
  await for (final transactions in query) {
    double currentBalance = 0;
    for (var t in transactions) {
      if (t.type == 'income') currentBalance += t.amount;
      if (t.type == 'expense' || t.type == 'transfer')
        currentBalance -= t.amount;
    }
    yield currentBalance;
  }
});

// Retrieves the attendance record for the current day
final attendanceTodayProvider = StreamProvider<Attendance?>((ref) async* {
  final today = DateTime.now();

  final query = db.watchAttendances();

  await for (final results in query) {
    try {
      final rec = results.firstWhere((e) =>
          e.date.year == today.year &&
          e.date.month == today.month &&
          e.date.day == today.day);
      yield rec;
    } catch (_) {
      yield null;
    }
  }
});

// Retrieves all recent transactions sorted by date
final transactionsProvider = StreamProvider<List<AppTransaction>>((ref) async* {
  final query = db.watchTransactions();
  await for (final transactions in query) {
    final list = List<AppTransaction>.from(transactions);
    list.sort((a, b) => b.date.compareTo(a.date));
    yield list;
  }
});

final driverTripsListProvider = StreamProvider<List<DriverTrip>>((ref) async* {
  final query = db.watchDriverTrips();
  await for (final trips in query) {
    final list = List<DriverTrip>.from(trips);
    list.sort((a, b) => b.date.compareTo(a.date));
    yield list;
  }
});
