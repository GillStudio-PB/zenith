// This file defines the FinesScreen widget, which allows users to track and manage their traffic fines. Users can view a list of fines, add new fines, update the status of existing fines (paid/unpaid), and delete fines. The screen uses a StreamBuilder to listen for changes in the database and updates the UI accordingly. It also provides an option to link fines to specific trips for better tracking.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/models.dart';
import '../main.dart';

class FinesScreen extends StatefulWidget {
  const FinesScreen({super.key});

  @override
  State<FinesScreen> createState() => _FinesScreenState();
}

class _FinesScreenState extends State<FinesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Traffic Fines Tracker',
            style: TextStyle(
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFineDialog,
        backgroundColor: Colors.deepOrangeAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Color(0xFF0A0A0A)),
      ),
      body: StreamBuilder<List<TrafficFine>>(
        stream: db.watchFines(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child:
                    CircularProgressIndicator(color: Colors.deepOrangeAccent));
          final fines = snapshot.data!;
          if (fines.isEmpty) {
            return const Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.greenAccent, size: 64),
                SizedBox(height: 16),
                Text('No fines recorded.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                Text('Drive safe!', style: TextStyle(color: Colors.white54)),
              ],
            ));
          }

          final trips = db.getDriverTrips(); // Used for displaying linked trip

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fines.length,
            itemBuilder: (context, index) {
              final f = fines.reversed.toList()[index];
              final linkedTrip = f.tripId != null
                  ? trips.firstWhere((t) => t.id == f.tripId,
                      orElse: () => DriverTrip(
                          destination: 'Unknown Trip',
                          allowance: 0,
                          date: DateTime.now()))
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long,
                        color: Colors.deepOrangeAccent),
                  ),
                  title: Text(f.location,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                          '${DateFormat('MMM dd, yyyy').format(f.date)} • ${f.description}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13)),
                      if (linkedTrip != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.link,
                                color: Colors.amberAccent, size: 14),
                            const SizedBox(width: 4),
                            Text('Trip: ${linkedTrip.destination}',
                                style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ],
                        )
                      ]
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('AED ${f.amount}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepOrangeAccent)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: f.status == 'Unpaid'
                              ? Colors.redAccent.withValues(alpha: 0.1)
                              : Colors.greenAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(f.status,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: f.status == 'Unpaid'
                                    ? Colors.redAccent
                                    : Colors.greenAccent)),
                      ),
                    ],
                  ),
                  onTap: () => _updateFineStatus(f),
                  onLongPress: () => _confirmDeleteFine(f),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDeleteFine(TrafficFine f) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title:
              const Text('Delete Fine?', style: TextStyle(color: Colors.white)),
          content: const Text(
              'Are you sure you want to delete this traffic fine?',
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                if (f.id != null) db.deleteFine(f.id!);
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

  void _updateFineStatus(TrafficFine f) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Fine Status',
                style: TextStyle(color: Colors.white)),
            content: Text(
                'Mark this fine as ${f.status == 'Unpaid' ? 'Paid' : 'Unpaid'}?',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  f.status = f.status == 'Unpaid' ? 'Paid' : 'Unpaid';
                  db.putFine(f);
                  Navigator.pop(context);
                },
                child: const Text('Yes',
                    style: TextStyle(color: Colors.deepOrangeAccent)),
              ),
            ],
          );
        });
  }

  void _showAddFineDialog() async {
    final locCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();

    // We can also let the user link it to a specific trip.
    final trips = db.getDriverTrips();
    DriverTrip? selectedTrip;

    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.add_task,
                        color: Colors.deepOrangeAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Log Traffic Fine',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: locCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Location (Radar area)',
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
                      controller: descCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description (e.g. Speeding)',
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
                      controller: amtCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount (AED)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (trips.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<DriverTrip>(
                            value: selectedTrip,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2A2A2A),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white54),
                            hint: const Text('Link to Trip (Optional)',
                                style: TextStyle(color: Colors.white54)),
                            items: trips
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                          '${t.destination} - ${DateFormat('MM/dd').format(t.date)}',
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setStateSB(() => selectedTrip = val);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white70))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    foregroundColor: const Color(0xFF0A0A0A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final l = locCtrl.text.trim();
                    final d = descCtrl.text.trim();
                    final a = double.tryParse(amtCtrl.text) ?? 0.0;
                    if (l.isNotEmpty && a > 0) {
                      db.putFine(TrafficFine(
                        tripId: selectedTrip?.id,
                        amount: a,
                        date: DateTime.now(),
                        location: l,
                        description: d,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          });
        });
  }
}
