class Todo {
  final int? id;
  final String title;
  final String description;
  final String? time;
  final String? weekday; // pazartesi, salı, etc. (only for weekly todos)
  final bool isDone;
  final TodoType type; // Daily, Weekly, or Today

  Todo({
    this.id,
    required this.title,
    required this.description,
    this.time,
    this.weekday,
    this.isDone = false,
    required this.type,
  });

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      time: map['time'],
      weekday: map['weekday'],
      isDone: map['isDone'] == 1,
      type: TodoType.values[map['type']],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'time': time,
      'weekday': weekday,
      'isDone': isDone ? 1 : 0,
      'type': type.index,
    };
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    String? time,
    String? weekday,
    bool? isDone,
    TodoType? type,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      weekday: weekday ?? this.weekday,
      isDone: isDone ?? this.isDone,
      type: type ?? this.type,
    );
  }
}

enum TodoType {
  daily,    // Günlük rutin işler
  weekly,   // Haftanın belirli günlerine özel işler
  today     // Bugüne özel geçici işler
}