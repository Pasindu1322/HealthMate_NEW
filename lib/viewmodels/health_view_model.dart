import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/health_repository.dart';
import '../models/health_record.dart';

class HealthViewModel extends ChangeNotifier {
  final HealthRepository repository;
  final SharedPreferences preferences;
  HealthViewModel(this.repository, this.preferences);
  List<HealthRecord> records = [];
  bool loading = false;
  String? error;
  ThemeMode get themeMode =>
      ThemeMode.values[preferences.getInt('theme') ?? ThemeMode.system.index];
  Future<void> setTheme(ThemeMode value) async {
    await preferences.setInt('theme', value.index);
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      records = await repository.all();
    } catch (_) {
      error = 'Could not load your records. Please try again.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> _change(Future<void> Function() action) async {
    error = null;
    try {
      await action();
      await load();
      return error == null;
    } catch (_) {
      error = 'Could not save the change. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> save(HealthRecord record) =>
      _change(() => repository.save(record));
  Future<bool> delete(int id) => _change(() => repository.delete(id));
  Future<bool> addDemoRecords() => _change(repository.addDemoRecords);
  HealthRecord totals(String date) {
    final daily = records.where((r) => r.date == date);
    return HealthRecord(
      date: date,
      steps: daily.fold(0, (n, r) => n + r.steps),
      calories: daily.fold(0, (n, r) => n + r.calories),
      water: daily.fold(0, (n, r) => n + r.water),
    );
  }
}
