class NoteColumn {
  final String id;
  String title;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;
  int order;

  NoteColumn({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.order = 0,
  });

  factory NoteColumn.fromMap(Map<String, dynamic> map, String id) {
    return NoteColumn(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      order: (map['order'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'content': content,
        'order': order,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };
}

class Heading {
  final String id;
  String title;
  String emoji;
  final DateTime createdAt;
  DateTime updatedAt;
  List<NoteColumn> columns;
  int order;

  Heading({
    required this.id,
    required this.title,
    required this.emoji,
    required this.createdAt,
    required this.updatedAt,
    this.columns = const [],
    this.order = 0,
  });

  factory Heading.fromMap(Map<String, dynamic> map, String id) {
    return Heading(
      id: id,
      title: map['title'] ?? '',
      emoji: map['emoji'] ?? '📝',
      order: (map['order'] as int?) ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      columns: [],
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'emoji': emoji,
        'order': order,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };
}