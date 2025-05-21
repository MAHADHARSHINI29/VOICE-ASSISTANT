import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class NoteService {
  static const String _notesKey = 'notes';
  final SharedPreferences _prefs;

  NoteService(this._prefs);

  Future<List<Note>> getNotes() async {
    final notesJson = _prefs.getStringList(_notesKey) ?? [];
    return notesJson.map((json) => Note.fromJson(jsonDecode(json))).toList();
  }

  Future<void> addNote(Note note) async {
    final notes = await getNotes();
    notes.add(note);
    await _saveNotes(notes);
  }

  Future<void> updateNote(Note note) async {
    final notes = await getNotes();
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      notes[index] = note;
      await _saveNotes(notes);
    }
  }

  Future<void> deleteNote(String id) async {
    final notes = await getNotes();
    notes.removeWhere((note) => note.id == id);
    await _saveNotes(notes);
  }

  Future<List<Note>> getReminders() async {
    final notes = await getNotes();
    return notes.where((note) => note.isReminder).toList();
  }

  Future<List<Note>> getActiveReminders() async {
    final now = DateTime.now();
    final notes = await getNotes();
    return notes.where((note) => note.isReminder && note.reminderDate!.isAfter(now)).toList();
  }

  Future<void> _saveNotes(List<Note> notes) async {
    final notesJson = notes.map((note) => jsonEncode(note.toJson())).toList();
    await _prefs.setStringList(_notesKey, notesJson);
  }
} 