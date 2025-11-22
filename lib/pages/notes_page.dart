import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/sqlite_service.dart';
import '../services/auth_service.dart';
import 'dart:async';
import '../widgets/findmed_logo.dart';
import 'note_form_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> notes = [];
  int? _userId;
  bool _loading = true;
  bool _authMissing = false;

  @override
  void initState() {
    super.initState();
    _initUserAndLoad();
  }

  Future<void> _initUserAndLoad() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _authMissing = true;
        _loading = false;
      });
      return;
    }
    final fetched = await SqliteService.fetchNotes(user.id);
    if (!mounted) return;
    setState(() {
      _userId = user.id;
      notes = fetched;
      _loading = false;
      _authMissing = false;
    });
  }

  void _navigateCreateNote() {
    if (_userId == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => NoteFormPage(
              title: 'Create Note',
              userId: _userId!,
              onSaved: (created) async {
                final fetched = await SqliteService.fetchNotes(_userId!);
                if (!mounted) return;
                setState(() => notes = fetched);
              },
            ),
          ),
        )
        .then((_) => _refreshNotes());
  }

  void _navigateEditNote(Note note) {
    if (_userId == null) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => NoteFormPage(
              title: 'Edit Note',
              userId: _userId!,
              existing: note,
              onSaved: (updated) async {
                final fetched = await SqliteService.fetchNotes(_userId!);
                if (!mounted) return;
                setState(() => notes = fetched);
              },
            ),
          ),
        )
        .then((_) => _refreshNotes());
  }

  Future<void> _refreshNotes() async {
    if (_userId == null) return;
    final fetched = await SqliteService.fetchNotes(_userId!);
    if (!mounted) return;
    setState(() => notes = fetched);
  }

  Future<void> _deleteNote(int index) async {
    final note = notes[index];
    await SqliteService.removeNote(note.id);
    if (!mounted) return;
    setState(() => notes.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Fallback: navigate to root/home if no back stack
              Navigator.of(context).pushReplacementNamed('/');
            }
          },
          tooltip: 'Back',
        ),
        title: const Row(
          children: [
            FindMedLogo(size: 34),
            SizedBox(width: 10),
            Text(
              'FindMed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _authMissing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Login to create and view notes',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.isEmpty ? 1 : notes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'My Shopping Notes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notes.isEmpty
                                ? 'Create notes to track items you plan to buy.'
                                : 'You have ${notes.length} saved note${notes.length == 1 ? '' : 's'}.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (notes.isEmpty)
                            ElevatedButton.icon(
                              onPressed: _navigateCreateNote,
                              icon: const Icon(Icons.add),
                              label: const Text('Create First Note'),
                            ),
                        ],
                      ),
                    ),
                  );
                }
                final note = notes[index - 1];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 0,
                  child: InkWell(
                    onTap: () => _navigateEditNote(note),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _deleteNote(index - 1),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.content,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _authMissing
          ? null
          : FloatingActionButton(
              onPressed: _navigateCreateNote,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            ),
    );
  }
}

// Dialog removed; replaced with dedicated form page
