/// `carbon_logs` row (one per task; powers the dashboard analytics).
class CarbonLog {
  const CarbonLog({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.date,
    required this.category,
    required this.carbonAmount,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? taskId;
  final String date;
  final String category;
  final double carbonAmount;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CarbonLog.fromMap(Map<String, Object?> m) => CarbonLog(
        id: m['id']! as String,
        userId: m['userId']! as String,
        taskId: m['taskId'] as String?,
        date: m['date']! as String,
        category: m['category']! as String,
        carbonAmount: (m['carbonAmount'] as num).toDouble(),
        description: (m['description'] as String?) ?? '',
        createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse((m['updatedAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'userId': userId,
        'taskId': taskId,
        'date': date,
        'category': category,
        'carbonAmount': carbonAmount,
        'description': description,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}
