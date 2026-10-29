import '../core/app_date.dart';
import '../core/number_format.dart';
import '../models/badge.dart';
import '../models/eco_level.dart';
import '../models/suggestion.dart';

/// Emission factor in kg CO2e per unit.
class CarbonFactor {
  const CarbonFactor(this.factor, this.unit, this.label);

  final double factor;
  final String unit;
  final String label;
}

/// Per-category aggregate used for suggestion generation
/// (`{ totalCarbon, count }` in the dashboard controller).
class CategoryAggregate {
  CategoryAggregate({this.totalCarbon = 0, this.count = 0});

  double totalCarbon;
  int count;
}

/// Direct port of `backend/utils/carbonEngine.js`.
///
/// Every factor, threshold, badge and suggestion text below is copied from the
/// original source. Do not "fix" quirks here without checking the original:
///  * only `first_task`, `week_streak` and `earth_guardian` are ever awarded
///    (the other five badges are displayed but never unlocked by the source);
///  * `checkBadges` is evaluated with the streak value *before* it is updated.
class CarbonEngine {
  CarbonEngine._();

  /// Global average daily footprint (kg) used by the eco score.
  static const double globalDailyAverage = 13;

  static const Map<String, Map<String, CarbonFactor>> factors = {
    'transport': {
      'car_petrol': CarbonFactor(0.21, 'km', 'Car (Petrol) per km'),
      'car_diesel': CarbonFactor(0.17, 'km', 'Car (Diesel) per km'),
      'car_electric': CarbonFactor(0.05, 'km', 'Car (Electric) per km'),
      'motorcycle': CarbonFactor(0.11, 'km', 'Motorcycle per km'),
      'bus': CarbonFactor(0.089, 'km', 'Bus per km'),
      'train': CarbonFactor(0.041, 'km', 'Train per km'),
      'flight_domestic': CarbonFactor(0.255, 'km', 'Domestic Flight per km'),
      'flight_international':
          CarbonFactor(0.195, 'km', 'International Flight per km'),
      'cycling': CarbonFactor(-0.02, 'km', 'Cycling per km (saves emissions)'),
      'walking': CarbonFactor(-0.01, 'km', 'Walking per km (saves emissions)'),
    },
    'food': {
      'beef': CarbonFactor(27.0, 'kg', 'Beef per kg'),
      'lamb': CarbonFactor(39.2, 'kg', 'Lamb per kg'),
      'pork': CarbonFactor(12.1, 'kg', 'Pork per kg'),
      'chicken': CarbonFactor(6.9, 'kg', 'Chicken per kg'),
      'fish': CarbonFactor(6.1, 'kg', 'Fish per kg'),
      'dairy': CarbonFactor(3.2, 'kg', 'Dairy per kg'),
      'vegetables': CarbonFactor(2.0, 'kg', 'Vegetables per kg'),
      'fruits': CarbonFactor(1.1, 'kg', 'Fruits per kg'),
      'grains': CarbonFactor(1.4, 'kg', 'Grains per kg'),
      'plant_based_meal': CarbonFactor(0.5, 'meal', 'Plant-based meal'),
      'vegan_meal': CarbonFactor(0.3, 'meal', 'Vegan meal'),
    },
    'energy': {
      'electricity': CarbonFactor(0.233, 'kWh', 'Electricity per kWh'),
      'natural_gas': CarbonFactor(2.04, 'm3', 'Natural Gas per m³'),
      'solar_panel': CarbonFactor(-0.05, 'kWh', 'Solar energy generated'),
      'home_heating_oil': CarbonFactor(2.52, 'litre', 'Heating oil per litre'),
      'led_switch': CarbonFactor(-0.01, 'hour', 'LED lighting saving per hour'),
    },
    'shopping': {
      'clothing': CarbonFactor(5.0, 'item', 'Clothing item'),
      'electronics': CarbonFactor(70.0, 'item', 'Electronics item'),
      'furniture': CarbonFactor(40.0, 'item', 'Furniture item'),
      'online_shopping': CarbonFactor(0.5, 'parcel', 'Online delivery parcel'),
      'secondhand': CarbonFactor(-2.0, 'item', 'Secondhand purchase (saves)'),
    },
    'waste': {
      'recycling': CarbonFactor(-0.5, 'kg', 'Recycling per kg (saves)'),
      'composting': CarbonFactor(-0.3, 'kg', 'Composting per kg (saves)'),
      'landfill': CarbonFactor(0.58, 'kg', 'Landfill waste per kg'),
      'plastic_waste': CarbonFactor(6.0, 'kg', 'Plastic to landfill per kg'),
    },
    'water': {
      'shower': CarbonFactor(0.023, 'minute', 'Shower per minute'),
      'bath': CarbonFactor(0.092, 'bath', 'Full bath'),
      'short_shower':
          CarbonFactor(-0.046, 'shower', 'Short shower vs bath (saves)'),
    },
    'other': {
      'tree_planted':
          CarbonFactor(-21.77, 'tree', 'Tree planted (annual saving)'),
      'offset': CarbonFactor(-1.0, 'kg', 'Carbon offset per kg'),
    },
  };

  static const List<EcoLevel> ecoLevels = [
    EcoLevel(
        name: 'Seedling',
        minScore: 0,
        maxScore: 30,
        emoji: '🌱',
        colorValue: 0xFFA8D8A8),
    EcoLevel(
        name: 'Sprout',
        minScore: 30,
        maxScore: 50,
        emoji: '🌿',
        colorValue: 0xFF74C69D),
    EcoLevel(
        name: 'Leaf',
        minScore: 50,
        maxScore: 65,
        emoji: '🍃',
        colorValue: 0xFF52B788),
    EcoLevel(
        name: 'Tree',
        minScore: 65,
        maxScore: 80,
        emoji: '🌳',
        colorValue: 0xFF40916C),
    EcoLevel(
        name: 'Forest',
        minScore: 80,
        maxScore: 90,
        emoji: '🌲',
        colorValue: 0xFF2D6A4F),
    EcoLevel(
        name: 'Earth Guardian',
        minScore: 90,
        maxScore: 100,
        emoji: '🌍',
        colorValue: 0xFF1B4332),
  ];

  static const List<BadgeDefinition> badges = [
    BadgeDefinition(
        id: 'first_task',
        name: 'First Step',
        emoji: '🎯',
        description: 'Logged your first eco task',
        displayDescription: 'Logged your first eco task',
        condition: 'tasks >= 1'),
    BadgeDefinition(
        id: 'week_streak',
        name: 'Week Warrior',
        emoji: '🔥',
        description: '7-day logging streak',
        displayDescription: '7-day logging streak',
        condition: 'streak >= 7'),
    BadgeDefinition(
        id: 'carbon_saver',
        name: 'Carbon Saver',
        emoji: '💚',
        description: 'Saved 10kg CO2 in a week',
        displayDescription: 'Saved 10kg CO₂ in a week',
        condition: 'weekly_saved >= 10'),
    BadgeDefinition(
        id: 'green_commuter',
        name: 'Green Commuter',
        emoji: '🚲',
        description: 'Used eco transport 5 times',
        displayDescription: 'Used eco transport 5 times',
        condition: 'eco_transport >= 5'),
    BadgeDefinition(
        id: 'plant_power',
        name: 'Plant Power',
        emoji: '🥗',
        description: 'Chose plant-based 10 times',
        displayDescription: 'Chose plant-based 10 times',
        condition: 'plant_meals >= 10'),
    BadgeDefinition(
        id: 'energy_saver',
        name: 'Energy Saver',
        emoji: '⚡',
        description: 'Reduced energy by 20% this week',
        displayDescription: 'Reduced energy by 20%',
        condition: 'energy_reduced >= 20'),
    BadgeDefinition(
        id: 'recycler',
        name: 'Recycler Pro',
        emoji: '♻️',
        description: 'Recycled 50kg of waste',
        displayDescription: 'Recycled 50kg of waste',
        condition: 'recycled >= 50'),
    BadgeDefinition(
        id: 'earth_guardian',
        name: 'Earth Guardian',
        emoji: '🌍',
        description: 'Achieved maximum eco score',
        displayDescription: 'Achieved maximum eco score',
        condition: 'score >= 90'),
  ];

  /// `calculateCarbonValue(category, subcategory, quantity = 1)`.
  /// Unknown category / subcategory yields 0, exactly like the original.
  static double calculateCarbonValue(String? category, String? subcategory,
      [double quantity = 1]) {
    final categoryFactors = factors[category];
    if (categoryFactors == null) return 0;
    final sub = categoryFactors[subcategory];
    if (sub == null) return 0;
    return JsNumber.round(sub.factor * quantity, 3);
  }

  /// `calculateEcoScore(totalCarbon, days = 30)`.
  static double calculateEcoScore(double totalCarbon, [int days = 30]) {
    final dailyAvg = days > 0 ? totalCarbon / days : totalCarbon;
    final ratio = dailyAvg / globalDailyAverage;
    final score = (100 - (ratio * 50)).clamp(0.0, 100.0).toDouble();
    return JsNumber.round(score, 1);
  }

  /// `getEcoLevel(score)`: first level whose inclusive range contains the
  /// score (so a score of exactly 30 is "Seedling"), falling back to the first.
  static EcoLevel getEcoLevel(double score) {
    for (final l in ecoLevels) {
      if (score >= l.minScore && score <= l.maxScore) return l;
    }
    return ecoLevels.first;
  }

  /// `generateSuggestions(tasksByCategory)`.
  static List<Suggestion> generateSuggestions(
      Map<String, CategoryAggregate> byCategory) {
    final suggestions = <Suggestion>[];

    if ((byCategory['transport']?.totalCarbon ?? 0) > 5) {
      suggestions.add(const Suggestion(
        category: 'transport',
        tip:
            'Switch to public transport or cycling to cut your travel emissions by up to 70%.',
        impact: 'Save ~3.5 kg CO2 per day',
        icon: '🚲',
      ));
    }
    if ((byCategory['food']?.totalCarbon ?? 0) > 8) {
      suggestions.add(const Suggestion(
        category: 'food',
        tip:
            'Try one plant-based meal per day. It can reduce your food footprint significantly.',
        impact: 'Save ~2.5 kg CO2 per meal',
        icon: '🥗',
      ));
    }
    if ((byCategory['energy']?.totalCarbon ?? 0) > 3) {
      suggestions.add(const Suggestion(
        category: 'energy',
        tip:
            'Switch to LED lighting and unplug devices on standby to reduce home energy use.',
        impact: 'Save ~1.2 kg CO2 per day',
        icon: '💡',
      ));
    }
    final waste = byCategory['waste'];
    if (waste == null || waste.count < 3) {
      suggestions.add(const Suggestion(
        category: 'waste',
        tip: 'Start composting and recycling to divert waste from landfill.',
        impact: 'Save ~0.5 kg CO2 per kg recycled',
        icon: '♻️',
      ));
    }
    if (suggestions.length < 2) {
      suggestions.add(const Suggestion(
        category: 'general',
        tip:
            'Plant a tree to offset ~21 kg CO2 annually and support biodiversity.',
        impact: 'Offset 21.77 kg CO2 per tree/year',
        icon: '🌳',
      ));
    }

    return suggestions.length > 3 ? suggestions.sublist(0, 3) : suggestions;
  }

  /// `checkBadges(user, stats)`: returns the full badge list after awarding.
  ///
  /// [streak] must be the user's streak *before* the current update, as in the
  /// original (`checkBadges` receives the stale `user` instance).
  static List<EarnedBadge> checkBadges({
    required List<EarnedBadge> currentBadges,
    required int streak,
    required int totalTasks,
    required double ecoScore,
  }) {
    bool has(String id) => currentBadges.any((b) => b.id == id);
    BadgeDefinition def(String id) => badges.firstWhere((b) => b.id == id);

    final added = <EarnedBadge>[];
    if (totalTasks >= 1 && !has('first_task')) {
      added.add(def('first_task').toEarned());
    }
    if (streak >= 7 && !has('week_streak')) {
      added.add(def('week_streak').toEarned());
    }
    if (ecoScore >= 90 && !has('earth_guardian')) {
      added.add(def('earth_guardian').toEarned());
    }

    return [...currentBadges, ...added];
  }

  /// `updateStreak(user)`: the streak value to store.
  ///
  /// * no previous activity, or already active today -> unchanged
  /// * last active yesterday -> streak + 1
  /// * otherwise -> reset to 1
  static int updateStreak({
    required int streak,
    required String? lastActiveDate,
    DateTime? now,
  }) {
    final current = now ?? AppDate.now();
    final today = AppDate.dayOf(current);
    if (lastActiveDate == null ||
        lastActiveDate.isEmpty ||
        lastActiveDate == today) {
      return streak;
    }
    final yesterday = AppDate.daysAgo(1, from: current);
    if (lastActiveDate == yesterday) return streak + 1;
    return 1;
  }
}
