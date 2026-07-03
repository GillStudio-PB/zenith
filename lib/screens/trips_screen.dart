// This file defines the TripsScreen widget, which allows users to track their trips and associated traffic fines. Users can add new trips, view a list of recorded trips, and see a summary of total fines accumulated. The screen uses a StreamBuilder to listen for changes in the database and updates the UI accordingly. It also provides functionality to delete trips and displays relevant information such as trip destination, date, allowance, and fines.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/models.dart';
import '../main.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Trip Tracker',
            style: TextStyle(
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTripDialog,
        backgroundColor: Colors.amberAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Color(0xFF0A0A0A)),
      ),
      body: StreamBuilder<List<DriverTrip>>(
        stream: db.watchDriverTrips(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Colors.amberAccent));
          final trips = snapshot.data!;

          return StreamBuilder<List<TrafficFine>>(
            stream: db.watchFines(),
            builder: (context, finesSnapshot) {
              final fines = finesSnapshot.data ?? [];
              double totalFinesAED =
                  fines.fold(0.0, (sum, f) => sum + f.amount);
              double totalFinesINR =
                  totalFinesAED * 22.6; // Approximate conversion

              return Column(
                children: [
                  // --- Fines Summary Card ---
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amberAccent.withValues(alpha: 0.1),
                          Colors.deepOrangeAccent.withValues(alpha: 0.1)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.receipt_long,
                              color: Colors.deepOrangeAccent, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Fines Accumulated',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text('AED ${totalFinesAED.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('≈ ₹${totalFinesINR.toStringAsFixed(2)} INR',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Trips List ---
                  Expanded(
                    child: trips.isEmpty
                        ? const Center(
                            child: Text('No trips recorded.',
                                style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: trips.length,
                            itemBuilder: (context, index) {
                              final t = trips.reversed.toList()[index];
                              // Check if there are fines for this trip
                              final tripFines =
                                  fines.where((f) => f.tripId == t.id).toList();
                              final tripFinesTotal = tripFines.fold(
                                  0.0, (sum, f) => sum + f.amount);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.05)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: Colors.amberAccent
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.local_shipping,
                                        color: Colors.amberAccent),
                                  ),
                                  title: Text(t.destination,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 16)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                          DateFormat('MMM dd, yyyy')
                                              .format(t.date),
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.5),
                                              fontSize: 13)),
                                      if (tripFines.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.deepOrangeAccent,
                                                size: 14),
                                            const SizedBox(width: 4),
                                            Text('Fines: AED $tripFinesTotal',
                                                style: const TextStyle(
                                                    color:
                                                        Colors.deepOrangeAccent,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ],
                                        )
                                      ]
                                    ],
                                  ),
                                  trailing: Text('AED ${t.allowance}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.amberAccent)),
                                  onLongPress: () => _confirmDeleteTrip(t),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDeleteTrip(DriverTrip t) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title:
              const Text('Delete Trip?', style: TextStyle(color: Colors.white)),
          content: const Text(
              'Are you sure you want to delete this trip? Associated fines will not be automatically deleted.',
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                if (t.id != null) db.deleteDriverTrip(t.id!);
                Navigator.pop(context);
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showAddTripDialog() {
    final destCtrl = TextEditingController();
    final allowanceCtrl = TextEditingController();
    DateTime date = DateTime.now();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.amberAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.add_road,
                      color: Colors.amberAccent, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Add Trip',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: destCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Destination (e.g. Abu Dhabi Port)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: allowanceCtrl,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Trip Allowance (AED)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: const Color(0xFF0A0A0A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final d = destCtrl.text.trim();
                  final a = double.tryParse(allowanceCtrl.text) ?? 0.0;
                  if (d.isNotEmpty) {
                    db.putDriverTrip(
                        DriverTrip(destination: d, allowance: a, date: date));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
  }
}
