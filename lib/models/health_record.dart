class HealthRecord {
  final int? id;
  final String date;
  final int steps;
  final int calories;
  final int water;
  const HealthRecord({
    this.id,
    required this.date,
    required this.steps,
    required this.calories,
    required this.water,
  });
  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'date': date,
    'steps': steps,
    'calories': calories,
    'water': water,
  };
  factory HealthRecord.fromMap(Map<String, Object?> map) => HealthRecord(
    id: map['id'] as int,
    date: map['date'] as String,
    steps: map['steps'] as int,
    calories: map['calories'] as int,
    water: map['water'] as int,
  );
}

String dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String? validateAmount(String? value) {
  if (value == null || value.trim().isEmpty) return 'Please enter a value';
  final number = int.tryParse(value.trim());
  if (number == null || number < 0 || number > 2147483647) {
    return 'Enter a whole number from 0 to 2147483647';
  }
  return null;
}
