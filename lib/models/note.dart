class Note {
  final String id; // UUID / timestamp string
  final int userId;
  final String title;
  final String content;
  final DateTime createdAt;
  const Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'content': content,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'] as String,
    userId: map['user_id'] as int,
    title: (map['title'] as String?) ?? '',
    content: (map['content'] as String?) ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    ),
  );
}
