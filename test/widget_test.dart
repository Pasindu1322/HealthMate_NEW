import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthmate/data/health_repository.dart';
import 'package:healthmate/models/health_record.dart';
import 'package:healthmate/viewmodels/health_view_model.dart';
import 'package:healthmate/main.dart';

class MemoryRepository extends HealthRepository {
  final List<HealthRecord> entries = [];
  @override
  Future<List<HealthRecord>> all() async => List.of(entries);
  @override
  Future<void> save(HealthRecord r) async {
    if (r.id != null) entries.removeWhere((e) => e.id == r.id);
    entries.add(
      HealthRecord(
        id: r.id ?? entries.length + 1,
        date: r.date,
        steps: r.steps,
        calories: r.calories,
        water: r.water,
      ),
    );
  }

  @override
  Future<void> delete(int id) async => entries.removeWhere((e) => e.id == id);
}

void main() {
  late HealthViewModel vm;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    vm = HealthViewModel(
      MemoryRepository(),
      await SharedPreferences.getInstance(),
    );
  });
  test('Validation rejects blanks, negatives, decimals and overflow', () {
    for (final value in ['', '-1', '1.5', 'abc', '2147483648']) {
      expect(validateAmount(value), isNotNull);
    }
    expect(validateAmount('0'), isNull);
    expect(validateAmount('1000'), isNull);
  });
  test(
    'Daily summary totals multiple entries without including other dates',
    () async {
      await vm.save(
        const HealthRecord(
          date: '2026-10-29',
          steps: 100,
          calories: 20,
          water: 250,
        ),
      );
      await vm.save(
        const HealthRecord(
          date: '2026-10-29',
          steps: 200,
          calories: 30,
          water: 500,
        ),
      );
      await vm.save(
        const HealthRecord(
          date: '2026-10-28',
          steps: 999,
          calories: 999,
          water: 999,
        ),
      );
      final sum = vm.totals('2026-10-29');
      expect([sum.steps, sum.calories, sum.water], [300, 50, 750]);
    },
  );
  test(
    'Updating replaces existing entry and deletion updates summary',
    () async {
      await vm.save(
        const HealthRecord(
          date: '2026-10-29',
          steps: 100,
          calories: 20,
          water: 250,
        ),
      );
      await vm.save(
        const HealthRecord(
          id: 1,
          date: '2026-10-29',
          steps: 500,
          calories: 40,
          water: 750,
        ),
      );
      expect(vm.records.length, 1);
      expect(vm.totals('2026-10-29').steps, 500);
      await vm.delete(1);
      expect(vm.records, isEmpty);
      expect(vm.totals('2026-10-29').water, 0);
    },
  );
  test('Theme persists across view model recreation', () async {
    await vm.setTheme(ThemeMode.dark);
    final restored = HealthViewModel(
      MemoryRepository(),
      await SharedPreferences.getInstance(),
    );
    expect(restored.themeMode, ThemeMode.dark);
  });
  testWidgets('Record form validates, saves and refreshes dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: vm, child: const HealthMateApp()),
    );
    await tester.tap(find.text('Add record'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a value'), findsNWidgets(3));
    await tester.enterText(find.byType(TextFormField).at(0), '7500');
    await tester.enterText(find.byType(TextFormField).at(1), '350');
    await tester.enterText(find.byType(TextFormField).at(2), '1500');
    await tester.ensureVisible(find.text('Save record'));
    await tester.tap(find.text('Save record'));
    await tester.pumpAndSettle();
    expect(vm.records.length, 1);
    expect(find.text('7,500 steps'), findsOneWidget);
  });
}
