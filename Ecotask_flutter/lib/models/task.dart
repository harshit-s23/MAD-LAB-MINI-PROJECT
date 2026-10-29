/// `tasks` row.
class Task {
  const Task({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.carbonValue,
    required this.quantity,
    required this.unit,
    required this.date,
    required this.completed,
    required this.isRecurring,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String subcategory;

  /// kg CO2e. Positive = emission, negative = saving.
  final double carbonValue;
  final double quantity;
  final String unit;

  /// `yyyy-MM-dd`
  final String date;
  final bool completed;
  final bool isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSaving => carbonValue < 0;

  Task copyWith({bool? completed}) => Task(
        id: id,
        userId: userId,
        title: title,
        description: description,
        category: category,
        subcategory: subcategory,
        carbonValue: carbonValue,
        quantity: quantity,
        unit: unit,
        date: date,
        completed: completed ?? this.completed,
        isRecurring: isRecurring,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory Task.fromMap(Map<String, Object?> m) => Task(
        id: m['id']! as String,
        userId: m['userId']! as String,
        title: m['title']! as String,
        description: (m['description'] as String?) ?? '',
        category: m['category']! as String,
        subcategory: (m['subcategory'] as String?) ?? '',
        carbonValue: (m['carbonValue'] as num).toDouble(),
        quantity: (m['quantity'] as num?)?.toDouble() ?? 1,
        unit: (m['unit'] as String?) ?? 'unit',
        date: m['date']! as String,
        completed: ((m['completed'] as num?) ?? 0) != 0,
        isRecurring: ((m['isRecurring'] as num?) ?? 0) != 0,
        createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse((m['updatedAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'category': category,
        'subcategory': subcategory,
        'carbonValue': carbonValue,
        'quantity': quantity,
        'unit': unit,
        'date': date,
        'completed': completed ? 1 : 0,
        'isRecurring': isRecurring ? 1 : 0,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}
