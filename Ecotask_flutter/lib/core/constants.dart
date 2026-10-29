/// Category display metadata (from frontend `utils/constants.js` CATEGORIES).
class CategoryMeta {
  const CategoryMeta({
    required this.value,
    required this.label,
    required this.emoji,
    required this.colorValue,
    required this.bgValue,
  });

  final String value;
  final String label;
  final String emoji;

  /// ARGB colour values (convert with `Color(meta.colorValue)` in the UI).
  final int colorValue;
  final int bgValue;
}

/// A selectable type inside a category (SUBCATEGORIES in constants.js).
class SubcategoryOption {
  const SubcategoryOption(this.value, this.label, this.unit);

  final String value;
  final String label;
  final String unit;
}

class AppConstants {
  AppConstants._();

  static const List<CategoryMeta> categories = [
    CategoryMeta(
        value: 'transport',
        label: 'Transport',
        emoji: '🚗',
        colorValue: 0xFF0369A1,
        bgValue: 0xFFE0F2FE),
    CategoryMeta(
        value: 'food',
        label: 'Food',
        emoji: '🍽️',
        colorValue: 0xFF15803D,
        bgValue: 0xFFDCFCE7),
    CategoryMeta(
        value: 'energy',
        label: 'Energy',
        emoji: '⚡',
        colorValue: 0xFFB45309,
        bgValue: 0xFFFEF3C7),
    CategoryMeta(
        value: 'shopping',
        label: 'Shopping',
        emoji: '🛍️',
        colorValue: 0xFF7C3AED,
        bgValue: 0xFFEDE9FE),
    CategoryMeta(
        value: 'waste',
        label: 'Waste',
        emoji: '♻️',
        colorValue: 0xFF065F46,
        bgValue: 0xFFD1FAE5),
    CategoryMeta(
        value: 'water',
        label: 'Water',
        emoji: '💧',
        colorValue: 0xFF0284C7,
        bgValue: 0xFFE0F2FE),
    CategoryMeta(
        value: 'other',
        label: 'Other',
        emoji: '🌿',
        colorValue: 0xFF6B7280,
        bgValue: 0xFFF3F4F6),
  ];

  /// Valid values of the Task.category ENUM.
  static final List<String> categoryValues =
      categories.map((c) => c.value).toList(growable: false);

  static const Map<String, List<SubcategoryOption>> subcategories = {
    'transport': [
      SubcategoryOption('car_petrol', 'Car (Petrol)', 'km'),
      SubcategoryOption('car_diesel', 'Car (Diesel)', 'km'),
      SubcategoryOption('car_electric', 'Car (Electric)', 'km'),
      SubcategoryOption('motorcycle', 'Motorcycle', 'km'),
      SubcategoryOption('bus', 'Bus', 'km'),
      SubcategoryOption('train', 'Train', 'km'),
      SubcategoryOption('flight_domestic', 'Domestic Flight', 'km'),
      SubcategoryOption('flight_international', 'International Flight', 'km'),
      SubcategoryOption('cycling', 'Cycling 🟢', 'km'),
      SubcategoryOption('walking', 'Walking 🟢', 'km'),
    ],
    'food': [
      SubcategoryOption('beef', 'Beef', 'kg'),
      SubcategoryOption('lamb', 'Lamb', 'kg'),
      SubcategoryOption('pork', 'Pork', 'kg'),
      SubcategoryOption('chicken', 'Chicken', 'kg'),
      SubcategoryOption('fish', 'Fish', 'kg'),
      SubcategoryOption('dairy', 'Dairy', 'kg'),
      SubcategoryOption('vegetables', 'Vegetables', 'kg'),
      SubcategoryOption('plant_based_meal', 'Plant-based Meal 🟢', 'meal'),
      SubcategoryOption('vegan_meal', 'Vegan Meal 🟢', 'meal'),
    ],
    'energy': [
      SubcategoryOption('electricity', 'Electricity', 'kWh'),
      SubcategoryOption('natural_gas', 'Natural Gas', 'm³'),
      SubcategoryOption('home_heating_oil', 'Heating Oil', 'litre'),
      SubcategoryOption('solar_panel', 'Solar Generated 🟢', 'kWh'),
      SubcategoryOption('led_switch', 'LED Lighting 🟢', 'hour'),
    ],
    'shopping': [
      SubcategoryOption('clothing', 'Clothing', 'item'),
      SubcategoryOption('electronics', 'Electronics', 'item'),
      SubcategoryOption('furniture', 'Furniture', 'item'),
      SubcategoryOption('online_shopping', 'Online Delivery', 'parcel'),
      SubcategoryOption('secondhand', 'Secondhand Purchase 🟢', 'item'),
    ],
    'waste': [
      SubcategoryOption('landfill', 'Landfill Waste', 'kg'),
      SubcategoryOption('plastic_waste', 'Plastic Waste', 'kg'),
      SubcategoryOption('recycling', 'Recycling 🟢', 'kg'),
      SubcategoryOption('composting', 'Composting 🟢', 'kg'),
    ],
    'water': [
      SubcategoryOption('shower', 'Shower', 'minute'),
      SubcategoryOption('bath', 'Full Bath', 'bath'),
      SubcategoryOption('short_shower', 'Short Shower 🟢', 'shower'),
    ],
    'other': [
      SubcategoryOption('tree_planted', 'Tree Planted 🟢', 'tree'),
      SubcategoryOption('offset', 'Carbon Offset 🟢', 'kg'),
    ],
  };

  /// `getCategoryMeta`: falls back to the last category ("other").
  static CategoryMeta categoryMeta(String value) {
    for (final c in categories) {
      if (c.value == value) return c;
    }
    return categories.last;
  }

  static List<SubcategoryOption> subcategoriesOf(String category) =>
      subcategories[category] ?? const [];

  /// Demo account created by `seed.js` and used by "Use Demo Account".
  static const String demoEmail = 'demo@ecotask.com';
  static const String demoPassword = 'demo123';
  static const String demoName = 'Alex Green';

  /// JWT_EXPIRES_IN=7d in the original backend.
  static const Duration sessionLifetime = Duration(days: 7);
}
