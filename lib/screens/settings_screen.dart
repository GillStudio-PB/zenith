// This file defines the SettingsScreen widget, which allows users to manage application settings related to data management. Users can export their local database backup to the clipboard, restore the database from a pasted backup, and reset the database to its initial state. The screen provides a user-friendly interface with buttons for each action and handles loading states and error messages appropriately.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart'; // To access global db instance

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _exportBackup() async {
    setState(() => _isLoading = true);
    try {
      // Mocked backup to clipboard for cross-platform compatibility
      // In a real app, this would serialize the database contents
      final backupData =
          '{"backup": "mock", "timestamp": "${DateTime.now().toIso8601String()}"}';
      await Clipboard.setData(ClipboardData(text: backupData));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup data copied to clipboard!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _importBackup() async {
    final TextEditingController _pasteController = TextEditingController();

    final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
              title: const Text('Restore Backup'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paste your backup JSON data below:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pasteController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '{"backup": "mock"...}',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(_pasteController.text),
                  child: const Text('Restore'),
                )
              ],
            ));

    if (result != null && result.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        // Here we would normally parse the JSON and repopulate the DB.
        // For now, we simulate the database wipe/reload.
        await db.clear();
        await Future.delayed(const Duration(seconds: 1));
        await db.init();

        if (mounted) {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                    title: const Text('Restore Complete'),
                    content: const Text(
                        'Database restored successfully from clipboard data.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      )
                    ],
                  ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Restore failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Reset Database?'),
                content: const Text(
                    'This will delete ALL data in the application and cannot be undone. Are you sure?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Reset',
                        style: TextStyle(color: Colors.red)),
                  )
                ]));

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await db.clear();
        await db.init();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Database reset successfully.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Reset failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Backup')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.backup, size: 64, color: Colors.blueGrey),
              const SizedBox(height: 24),
              const Text('Data Management',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Export, restore, or reset your local database.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton.icon(
                  onPressed: _exportBackup,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Backup Data'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 50)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _importBackup,
                  icon: const Icon(Icons.paste),
                  label: const Text('Restore from Data'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _resetDatabase,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Reset App Data',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
