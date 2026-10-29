import 'dart:convert';

/// Static badge definition (BADGES in carbonEngine.js merged with the
/// description shown by the frontend BadgeGrid).
class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.displayDescription,
    required this.condition,
  });

  final String id;
  final String name;
  final String emoji;

  /// Description stored in the user's badge JSON (backend wording).
  final String description;

  /// Description shown in the UI (frontend `ALL_BADGES` wording).
  final String displayDescription;

  /// Human readable unlock condition (backend `condition`).
  final String condition;

  EarnedBadge toEarned() => EarnedBadge(
        id: id,
        name: name,
        emoji: emoji,
        description: description,
        condition: condition,
      );
}

/// A badge stored in `users.badges` (JSON array). The seed data stores only
/// `id/name/emoji`, awarded badges store the full definition.
class EarnedBadge {
  const EarnedBadge({
    required this.id,
    required this.name,
    required this.emoji,
    this.description,
    this.condition,
  });

  final String id;
  final String name;
  final String emoji;
  final String? description;
  final String? condition;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        if (description != null) 'description': description,
        if (condition != null) 'condition': condition,
      };

  factory EarnedBadge.fromJson(Map<String, Object?> json) => EarnedBadge(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        emoji: (json['emoji'] ?? '').toString(),
        description: json['description'] as String?,
        condition: json['condition'] as String?,
      );

  /// Parses the `badges` TEXT column. Mirrors the model getter
  /// (`val ? JSON.parse(val) : []`) but tolerates corrupt data.
  static List<EarnedBadge> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => EarnedBadge.fromJson(Map<String, Object?>.from(m)))
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  static String encodeList(List<EarnedBadge> badges) =>
      jsonEncode(badges.map((b) => b.toJson()).toList());
}
