import 'package:flutter/material.dart';
import '../services/sqlite_service.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class NoteFormPage extends StatefulWidget {
  final String title;
  final int userId;
  final Note? existing;
  final Future<void> Function(Note saved) onSaved;
  const NoteFormPage({
    super.key,
    required this.title,
    required this.userId,
    required this.onSaved,
    this.existing,
  });
  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existing?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.existing?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      Note note;
      if (widget.existing == null) {
        note = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: widget.userId,
          title: title,
          content: content,
          createdAt: DateTime.now(),
        );
        await SqliteService.addNote(note);
      } else {
        note = Note(
          id: widget.existing!.id,
          userId: widget.existing!.userId,
          title: title,
          content: content,
          createdAt: widget.existing!.createdAt,
        );
        await SqliteService.updateNote(note);
      }
      await widget.onSaved(note);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), leading: const BackButton()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: 'Content',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 6,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
