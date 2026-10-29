import '../services/carbon_engine.dart';
import 'badge.dart';
import 'eco_level.dart';

/// `users` row (without the password hash).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.totalEcoScore,
    required this.streak,
    required this.lastActiveDate,
    required this.badges,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final double totalEcoScore;
  final int streak;

  /// `yyyy-MM-dd`
  final String lastActiveDate;
  final List<EarnedBadge> badges;

  /// Stored level name (`level` column).
  final String level;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// `levelData` returned by the original API: derived from the stored score.
  EcoLevel get levelData => CarbonEngine.getEcoLevel(totalEcoScore);

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.first;
  }

  AppUser copyWith({
    String? name,
    double? totalEcoScore,
    int? streak,
    String? lastActiveDate,
    List<EarnedBadge>? badges,
    String? level,
    DateTime? updatedAt,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        totalEcoScore: totalEcoScore ?? this.totalEcoScore,
        streak: streak ?? this.streak,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        badges: badges ?? this.badges,
        level: level ?? this.level,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
        id: m['id']! as String,
        name: m['name']! as String,
        email: m['email']! as String,
        totalEcoScore: (m['totalEcoScore'] as num?)?.toDouble() ?? 100,
        streak: (m['streak'] as num?)?.toInt() ?? 0,
        lastActiveDate: (m['lastActiveDate'] as String?) ?? '',
        badges: EarnedBadge.decodeList(m['badges'] as String?),
        level: (m['level'] as String?) ?? 'Seedling',
        createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse((m['updatedAt'] as String?) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'totalEcoScore': totalEcoScore,
        'streak': streak,
        'lastActiveDate': lastActiveDate,
        'badges': EarnedBadge.encodeList(badges),
        'level': level,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

/// A user row plus its password hash, used only by the auth layer.
class UserCredentials {
  const UserCredentials({required this.user, required this.passwordHash});

  final AppUser user;
  final String passwordHash;
}
