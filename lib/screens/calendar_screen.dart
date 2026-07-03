// This file defines the CalendarScreen widget, which displays a log of user activities, including attendances and trips. It uses Riverpod providers to fetch data from the database and formats durations for display. The screen adapts its content based on whether the user is a heavy vehicle driver or not, providing appropriate UI and actions for each case.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/models.dart';
import '../main.dart'; // db
import '../providers/app_providers.dart';

final calendarProvider = StreamProvider<List<Attendance>>((ref) async* {
  final query = db.watchAttendances();
  await for (final attendances in query) {
    final list = List<Attendance>.from(attendances);
    list.sort((a, b) => b.date.compareTo(a.date));
    yield list;
  }
});

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  String _formatDuration(DateTime? start, DateTime? end) {
    if (start == null) return '00.00.00';
    final effectiveEnd = end ?? DateTime.now();
    final diff = effectiveEnd.difference(start);
    return _formatDurationObject(diff);
  }

  String _formatDurationObject(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}.${minutes.toString().padLeft(2, '0')}.${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTotalDuration(
      DateTime? dStart, DateTime? dEnd, DateTime? oStart, DateTime? oEnd) {
    Duration duty = Duration.zero;
    if (dStart != null) {
      duty = (dEnd ?? DateTime.now()).difference(dStart);
    }

    Duration ot = Duration.zero;
    if (oStart != null) {
      ot = (oEnd ?? DateTime.now()).difference(oStart);
    }

    return _formatDurationObject(duty + ot);
  }

// Updated Activity Log to show either Trips or Attendances
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(calendarProvider);
    final tripsAsync = ref.watch(driverTripsListProvider);

    final users = db.getUsers();
    final isHeavy = users.isNotEmpty ? users.first.isHeavyVehicleDriver : false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Activity Log',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 0,
      ),
      body: isHeavy
          ? tripsAsync.when(
              data: (trips) {
                if (trips.isEmpty) {
                  return _buildEmptyState(
                      'No Trips Logged', 'Your daily trips will appear here.');
                }
                return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final t = trips[index];
                      return Card(
                        color: Colors.grey.shade900,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: Colors.amber.withValues(alpha: 0.3))),
                        child: ListTile(
                          leading: const Icon(Icons.map, color: Colors.amber),
                          title: Text(t.destination,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          subtitle: Text(
                              DateFormat('MMM dd, yyyy (EEEE)').format(t.date),
                              style: const TextStyle(color: Colors.white54)),
                          trailing: Text(
                              '+${t.allowance.toStringAsFixed(2)} AED',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                  fontSize: 16)),
                        ),
                      );
                    });
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.amber)),
              error: (e, s) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.red))))
          : calendarAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return _buildEmptyState('No Activity Logged',
                      'Your daily check-ins will appear here.');
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final r = records[index];
                    return Card(
                      color: Colors.grey.shade900,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                              color: Colors.amber.withValues(alpha: 0.3))),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                DateFormat('MMM dd, yyyy (EEEE)')
                                    .format(r.date),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white)),
                            const Divider(height: 24, color: Colors.white24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Duty Time:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70)),
                                Text(_formatDuration(r.dutyStart, r.dutyEnd),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.tealAccent)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Overtime Time:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70)),
                                Text(_formatDuration(r.otStart, r.otEnd),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orangeAccent)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Time:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                                Text(
                                    _formatTotalDuration(r.dutyStart, r.dutyEnd,
                                        r.otStart, r.otEnd),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.amber)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.amber)),
              error: (err, stack) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: Colors.red))),
            ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month, size: 64, color: Colors.white24),
              const SizedBox(height: 24),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}
