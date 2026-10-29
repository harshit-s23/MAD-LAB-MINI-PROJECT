/// Data needed to create a task (POST /tasks body).
class TaskInput {
  const TaskInput({
    required this.title,
    this.description = '',
    required this.category,
    this.subcategory = '',
    this.quantity = 1,
    this.unit = 'unit',
    required this.date,
    this.isRecurring = false,
  });

  final String title;
  final String description;
  final String category;
  final String subcategory;
  final double quantity;
  final String unit;
  final String date;
  final bool isRecurring;
}

/// Partial task update (PUT /tasks/:id body). A `null` field means
/// "not provided", reproducing JavaScript's `undefined` semantics.
class TaskUpdate {
  const TaskUpdate({
    this.title,
    this.description,
    this.category,
    this.subcategory,
    this.quantity,
    this.unit,
    this.date,
    this.completed,
  });

  final String? title;
  final String? description;
  final String? category;
  final String? subcategory;
  final double? quantity;
  final String? unit;
  final String? date;
  final bool? completed;
}
