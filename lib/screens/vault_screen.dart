// This file defines the VaultScreen widget, which allows users to securely store and manage their important documents. Users can add new documents with details such as title, category, and expiry date. The screen uses Riverpod providers to fetch document data from the local database and displays it in a user-friendly interface. It also includes functionality to lock and unlock the vault for added security.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/models.dart';
import '../main.dart'; // db

final vaultProvider = StreamProvider<List<DocumentItem>>((ref) async* {
  final query = db.watchDocuments();
  await for (final docs in query) {
    yield docs;
  }
});

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  bool _showAdd = false;
  bool _isLocked = true;
  final _titleController = TextEditingController();
  String _category = 'Passport';
  final _categories = ['Passport', 'Emirates ID', 'Visa', 'Contract', 'Other'];
  DateTime? _expiryDate;

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty) return;

    final doc = DocumentItem(
        title: _titleController.text,
        category: _category,
        expiryDate: _expiryDate);
    await db.putDocument(doc);

    setState(() {
      _showAdd = false;
      _titleController.clear();
      _expiryDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Documents Vault',
              style:
                  TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.amber),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              const Text('Vault is locked',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white54)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isLocked = false),
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock Vault'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12)),
              ),
            ],
          ),
        ),
      );
    }

    final docsAsync = ref.watch(vaultProvider);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Documents Vault',
              style:
                  TextStyle(fontWeight: FontWeight.w800, color: Colors.amber)),
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.amber),
          elevation: 0,
          actions: [
            IconButton(
                icon: Icon(_showAdd ? Icons.close : Icons.add,
                    color: Colors.amber),
                onPressed: () => setState(() => _showAdd = !_showAdd))
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => setState(() => _isLocked = true),
          icon: const Icon(Icons.lock),
          label: const Text('Lock Vault',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
        body: CustomScrollView(
          slivers: [
            if (_showAdd)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Material(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Store Document',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.amber)),
                          const SizedBox(height: 16),
                          TextField(
                              controller: _titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Document Name',
                                labelStyle:
                                    const TextStyle(color: Colors.white54),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.amber
                                            .withValues(alpha: 0.5))),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.amber)),
                              )),
                          const SizedBox(height: 16),
                          Theme(
                            data: Theme.of(context)
                                .copyWith(canvasColor: Colors.grey.shade900),
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.amber
                                            .withValues(alpha: 0.5))),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.amber)),
                              ),
                              items: _categories
                                  .map((t) => DropdownMenuItem(
                                      value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (v) => setState(() => _category = v!),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: Text(
                                _expiryDate == null
                                    ? 'No Expiry Selected'
                                    : DateFormat('MMM dd, yyyy')
                                        .format(_expiryDate!),
                                style: const TextStyle(color: Colors.white)),
                            trailing: const Icon(Icons.calendar_today,
                                color: Colors.amber),
                            onTap: () async {
                              final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100));
                              if (date != null)
                                setState(() => _expiryDate = date);
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _handleSave,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50)),
                            child: const Text('Save Document',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            docsAsync.when(
              data: (docs) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final d = docs[index];
                    bool isExpiringSoon = false;
                    if (d.expiryDate != null) {
                      final daysLeft =
                          d.expiryDate!.difference(DateTime.now()).inDays;
                      if (daysLeft < 30) isExpiringSoon = true;
                    }

                    return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.description,
                              color: Colors.amber.shade300),
                        ),
                        title: Text(d.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        subtitle: Row(
                          children: [
                            Text(d.category,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: Colors.white54)),
                            if (d.expiryDate != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: isExpiringSoon
                                        ? Colors.red.withValues(alpha: 0.2)
                                        : Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: isExpiringSoon
                                            ? Colors.red
                                            : Colors.grey.shade600)),
                                child: Text(
                                    'Exp: ${DateFormat('MMM dd, yyyy').format(d.expiryDate!)}',
                                    style: TextStyle(
                                        fontSize: 8,
                                        color: isExpiringSoon
                                            ? Colors.redAccent
                                            : Colors.white70,
                                        fontWeight: FontWeight.bold)),
                              )
                            ]
                          ],
                        ));
                  },
                  childCount: docs.length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SliverToBoxAdapter(
                  child: Center(child: Text('Error loading documents'))),
            )
          ],
        ));
  }
}
