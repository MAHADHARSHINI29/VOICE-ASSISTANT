import 'dart:convert';

class Note {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isReminder;
  final DateTime? reminderDate;

  Note({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isReminder = false,
    this.reminderDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isReminder': isReminder,
      'reminderDate': reminderDate?.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      isReminder: json['isReminder'] ?? false,
      reminderDate: json['reminderDate'] != null ? DateTime.parse(json['reminderDate']) : null,
    );
  }

  Note copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? reminderDate,
    bool? isReminder,
  }) {
    return Note(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      reminderDate: reminderDate ?? this.reminderDate,
      isReminder: isReminder ?? this.isReminder,
    );
  }
} 