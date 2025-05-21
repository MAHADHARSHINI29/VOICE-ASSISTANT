import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late NoteService _noteService;
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNoteService();
  }

  Future<void> _initializeNoteService() async {
    final prefs = await SharedPreferences.getInstance();
    _noteService = NoteService(prefs);
    await _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });
    final notes = await _noteService.getNotes();
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _addNote() async {
    final TextEditingController contentController = TextEditingController();
    DateTime? reminderDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: 'Enter your note',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(reminderDate == null ? 'Set Reminder' : DateFormat('MMM d, y HH:mm').format(reminderDate!)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        reminderDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (contentController.text.isNotEmpty) {
                  final note = Note(
                    id: DateTime.now().toString(),
                    content: contentController.text,
                    createdAt: DateTime.now(),
                    isReminder: reminderDate != null,
                    reminderDate: reminderDate,
                  );
                  await _noteService.addNote(note);
                  Navigator.pop(context);
                  _loadNotes();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(String id) async {
    await _noteService.deleteNote(id);
    _loadNotes();
  }

  Future<void> _editNote(Note note) async {
    final TextEditingController contentController = TextEditingController(text: note.content);
    DateTime? reminderDate = note.reminderDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: 'Enter your note',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(reminderDate == null ? 'Set Reminder' : DateFormat('MMM d, y HH:mm').format(reminderDate!)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: reminderDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: (reminderDate != null)
                          ? TimeOfDay(hour: reminderDate!.hour, minute: reminderDate!.minute)
                          : TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        reminderDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (contentController.text.isNotEmpty) {
                  final updatedNote = Note(
                    id: note.id,
                    content: contentController.text,
                    createdAt: note.createdAt,
                    isReminder: reminderDate != null,
                    reminderDate: reminderDate,
                  );
                  await _noteService.updateNote(updatedNote);
                  Navigator.pop(context);
                  _loadNotes();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Reminders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  final isReminderActive = note.isReminder && note.reminderDate != null && note.reminderDate!.isAfter(DateTime.now());
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(note.content),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created: ${DateFormat('MMM d, y HH:mm').format(note.createdAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (note.isReminder && note.reminderDate != null)
                            Text(
                              'Reminder: ${DateFormat('MMM d, y HH:mm').format(note.reminderDate!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isReminderActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editNote(note),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteNote(note.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
} 