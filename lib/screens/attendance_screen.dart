// This file defines the AttendanceScreen widget, which displays the attendance or daily trips for the user. It uses Riverpod providers to fetch today's attendance record and driver trips from the database. The screen adapts its content based on whether the user is a heavy vehicle driver or not, providing appropriate UI and actions for each case.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../db/models.dart';
import '../main.dart'; // db import

final todayTripsProvider = StreamProvider<List<DriverTrip>>((ref) async* {
  final now = DateTime.now();
  final query = db.watchDriverTrips();
  await for (final trips in query) {
    yield trips
        .where((t) =>
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .toList();
  }
});

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(attendanceTodayProvider);
    final users = db.getUsers();
    final isHeavy = users.isNotEmpty ? users.first.isHeavyVehicleDriver : false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isHeavy ? 'Daily Trips' : 'Attendance',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: Colors.amber)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.amber),
        elevation: 0,
      ),
      body: isHeavy
          ? const _HeavyDriverTripsContent()
          : todayAsync.when(
              data: (record) => _AttendanceContent(todayRecord: record),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.amber)),
              error: (err, stack) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: Colors.red))),
            ),
    );
  }
}

class _HeavyDriverTripsContent extends ConsumerStatefulWidget {
  const _HeavyDriverTripsContent();
  @override
  ConsumerState<_HeavyDriverTripsContent> createState() =>
      _HeavyDriverTripsContentState();
}

class _HeavyDriverTripsContentState
    extends ConsumerState<_HeavyDriverTripsContent> {
  Future<void> _showTripDialog({DriverTrip? existingTrip}) async {
    final destCtrl =
        TextEditingController(text: existingTrip?.destination ?? '');
    final allowCtrl = TextEditingController(
        text: existingTrip != null ? existingTrip.allowance.toString() : '');
    final vehicleCtrl =
        TextEditingController(text: existingTrip?.vehicleNumber ?? '');
    final fuelCtrl = TextEditingController(
        text: existingTrip?.fuelProvided?.toString() ?? '');
    final cargoCtrl = TextEditingController(
        text: existingTrip?.cargoTonnage?.toString() ?? '');
    final clientCtrl =
        TextEditingController(text: existingTrip?.clientName ?? '');

    // Set default trip rate from user config for new trips
    if (existingTrip == null && allowCtrl.text.isEmpty) {
      final users = db.getUsers();
      if (users.isNotEmpty && users.first.tripRate > 0) {
        allowCtrl.text = users.first.tripRate.toString();
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
            existingTrip == null ? 'Add Trip Details' : 'Edit Trip Details',
            style: const TextStyle(color: Colors.amber)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTripField(destCtrl, 'Destination / Route', false),
              const SizedBox(height: 12),
              _buildTripField(allowCtrl, 'Allowance (AED)', true),
              const SizedBox(height: 12),
              _buildTripField(clientCtrl, 'Client Name', false),
              const SizedBox(height: 12),
              _buildTripField(vehicleCtrl, 'Vehicle Number', false),
              const SizedBox(height: 12),
              _buildTripField(cargoCtrl, 'Cargo Tonnage', true),
              const SizedBox(height: 12),
              _buildTripField(fuelCtrl, 'Fuel Provided (Ltr/Amount)', true),
            ],
          ),
        ),
        actions: [
          if (existingTrip != null)
            TextButton(
                onPressed: () {
                  db.deleteDriverTrip(existingTrip.id!);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete',
                    style: TextStyle(color: Colors.redAccent))),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () async {
              final trip = DriverTrip(
                id: existingTrip?.id,
                destination: destCtrl.text.isEmpty ? 'Unknown' : destCtrl.text,
                allowance: double.tryParse(allowCtrl.text) ?? 0.0,
                date: existingTrip?.date ?? DateTime.now(),
                vehicleNumber:
                    vehicleCtrl.text.isEmpty ? null : vehicleCtrl.text,
                cargoTonnage: double.tryParse(cargoCtrl.text),
                fuelProvided: double.tryParse(fuelCtrl.text),
                clientName: clientCtrl.text.isEmpty ? null : clientCtrl.text,
              );
              await db.putDriverTrip(trip);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTripField(
      TextEditingController ctrl, String label, bool isNumeric) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber.withValues(alpha: 0.5))),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.amber)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _viewTripDetails(DriverTrip t) {
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              backgroundColor: Colors.grey.shade900,
              title: const Text('Trip Information',
                  style: TextStyle(color: Colors.amber)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Destination', t.destination),
                  _detailRow('Client Name', t.clientName ?? 'N/A'),
                  _detailRow('Vehicle No.', t.vehicleNumber ?? 'N/A'),
                  _detailRow('Cargo Tonnage',
                      t.cargoTonnage != null ? '${t.cargoTonnage} t' : 'N/A'),
                  _detailRow('Fuel Provided',
                      t.fuelProvided != null ? '${t.fuelProvided}' : 'N/A'),
                  _detailRow(
                      'Allowance', '${t.allowance.toStringAsFixed(2)} AED'),
                  _detailRow('Date', DateFormat('MMM dd, yyyy').format(t.date)),
                  _detailRow('Time', DateFormat('hh:mm a').format(t.date)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Close',
                        style: TextStyle(color: Colors.white54))),
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black),
                    onPressed: () {
                      Navigator.pop(c);
                      _showTripDialog(existingTrip: t);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'))
              ],
            ));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
            text: '$label: ',
            style: const TextStyle(
                color: Colors.white54, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                  text: value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.normal))
            ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(todayTripsProvider);
    return tripsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (e, s) => Center(
            child:
                Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (trips) {
          double totalEarned = 0;
          for (var t in trips) totalEarned += t.allowance;

          return Column(
            children: [
              Container(
                  margin: const EdgeInsets.all(24.0),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.local_shipping,
                        size: 48, color: Colors.amber),
                    const SizedBox(height: 16),
                    const Text('TODAY\'S TRIPS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white54)),
                    const SizedBox(height: 8),
                    Text('${trips.length} Trips',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('${totalEarned.toStringAsFixed(2)} AED Earned Today',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.greenAccent)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showTripDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Log New Trip',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50)),
                    ),
                  ])),
              Expanded(
                child: ListView.builder(
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final t = trips[index];
                      return ListTile(
                        leading: const Icon(Icons.map, color: Colors.amber),
                        title: Text(t.destination,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('hh:mm a').format(t.date),
                            style: const TextStyle(color: Colors.white54)),
                        trailing: Text('+${t.allowance.toStringAsFixed(2)} AED',
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        onTap: () => _viewTripDetails(t),
                      );
                    }),
              )
            ],
          );
        });
  }
}

class _AttendanceContent extends StatefulWidget {
  final Attendance? todayRecord;
  const _AttendanceContent({required this.todayRecord});

  @override
  State<_AttendanceContent> createState() => _AttendanceContentState();
}

class _AttendanceContentState extends State<_AttendanceContent> {
  bool _isLoading = false;

  Future<void> _handleAction(String action) async {
    setState(() => _isLoading = true);
    final now = DateTime.now();

    try {
      if (widget.todayRecord == null) {
        if (action == 'checkin') {
          final newRecord = Attendance(
              date: DateTime(now.year, now.month, now.day),
              dutyStart: now,
              status: 'Present');
          await db.putAttendance(newRecord);
        }
      } else {
        final record = widget.todayRecord!;
        if (action == 'checkout' && record.dutyStart != null) {
          record.dutyEnd = now;
          record.dutyHours = now.difference(record.dutyStart!).inMinutes / 60.0;
        } else if (action == 'otStart') {
          record.otStart = now;
        } else if (action == 'otEnd' && record.otStart != null) {
          record.otEnd = now;
          record.otHours = now.difference(record.otStart!).inMinutes / 60.0;
        }
        await db.putAttendance(record);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  String _getActiveState() {
    if (widget.todayRecord == null || widget.todayRecord?.dutyStart == null)
      return 'Not Started';
    if (widget.todayRecord?.dutyStart != null &&
        widget.todayRecord?.dutyEnd == null) return 'On Duty';
    if (widget.todayRecord?.dutyEnd != null &&
        widget.todayRecord?.otStart == null) return 'Duty Completed';
    if (widget.todayRecord?.otStart != null &&
        widget.todayRecord?.otEnd == null) return 'On Overtime';
    return 'Day Completed';
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.todayRecord;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.access_time_filled,
                    size: 48, color: Colors.amber),
                const SizedBox(height: 16),
                const Text('CURRENT STATUS',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white54)),
                const SizedBox(height: 8),
                Text(_getActiveState(),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.amber)
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      if (record == null || record.dutyStart == null)
                        ElevatedButton.icon(
                          onPressed: () => _handleAction('checkin'),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Check In',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black),
                        ),
                      if (record?.dutyStart != null && record?.dutyEnd == null)
                        ElevatedButton.icon(
                          onPressed: () => _handleAction('checkout'),
                          icon: const Icon(Icons.stop),
                          label: const Text('Check Out',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.black),
                        ),
                      if (record?.dutyEnd != null && record?.otStart == null)
                        ElevatedButton.icon(
                          onPressed: () => _handleAction('otStart'),
                          icon: const Icon(Icons.play_circle_outline),
                          label: const Text('Start OT',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.black),
                        ),
                      if (record?.otStart != null && record?.otEnd == null)
                        ElevatedButton.icon(
                          onPressed: () => _handleAction('otEnd'),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('End OT',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.black),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
