// This file defines the NotesScreen widget, which allows users to create, view, and manage their notes and diary entries. It uses Riverpod providers to fetch notes from the local database and displays them in a user-friendly interface. Users can add new notes, view existing notes sorted by creation date, and the screen provides a simple form for entering note titles and content.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../db/models.dart';
import '../main.dart'; // db

final notesProvider = StreamProvider<List<NoteItem>>((ref) async* {
  final query = db.watchNotes();
  await for (final notes in query) {
    final list = List<NoteItem>.from(notes);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield list;
  }
});

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  bool _showAdd = false;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty)
      return;

    final note = NoteItem(
        title: _titleController.text,
        content: _contentController.text,
        type: 'General',
        createdAt: DateTime.now().millisecondsSinceEpoch);
    await db.putNote(note);

    setState(() {
      _showAdd = false;
      _titleController.clear();
      _contentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Notes & Diary',
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
                        TextField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Note Title',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.5))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber)),
                            )),
                        const SizedBox(height: 16),
                        TextField(
                            controller: _contentController,
                            maxLines: 5,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Start typing...',
                              labelStyle:
                                  const TextStyle(color: Colors.white70),
                              alignLabelWithHint: true,
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color:
                                          Colors.amber.withValues(alpha: 0.5))),
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.amber)),
                            )),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50)),
                          child: const Text('Save Note',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            notesAsync.when(
              data: (notes) => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final n = notes[index];
                    return Card(
                      color: Colors.grey.shade900,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(n.content,
                                style: const TextStyle(
                                    color: Colors.white70, height: 1.5)),
                            const SizedBox(height: 16),
                            Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        n.createdAt)),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: notes.length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.amber))),
              error: (err, stack) => const SliverToBoxAdapter(
                  child: Center(
                      child: Text('Error loading notes',
                          style: TextStyle(color: Colors.red)))),
            )
          ],
        ));
  }
}
