import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/health_record.dart';

class HealthRepository {
  Database? _database;
  Future<Database> get database async => _database ??= await openDatabase(
    join(await getDatabasesPath(), 'healthmate.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE health_records (id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT NOT NULL, steps INTEGER NOT NULL CHECK(steps >= 0), calories INTEGER NOT NULL CHECK(calories >= 0), water INTEGER NOT NULL CHECK(water >= 0))',
      );
      await db.execute('CREATE INDEX records_date ON health_records(date)');
    },
  );
  Future<List<HealthRecord>> all() async => (await (await database).query(
    'health_records',
    orderBy: 'date DESC, id DESC',
  )).map(HealthRecord.fromMap).toList();
  Future<void> save(HealthRecord record) async {
    final db = await database;
    if (record.id == null) {
      await db.insert('health_records', record.toMap());
    } else {
      await db.update(
        'health_records',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
    }
  }

  Future<void> delete(int id) async => (await database).delete(
    'health_records',
    where: 'id = ?',
    whereArgs: [id],
  );
  Future<void> addDemoRecords() async {
    final db = await database;
    final batch = db.batch();
    for (var day = 1; day <= 7; day++) {
      batch.insert(
        'health_records',
        HealthRecord(
          date: dateKey(DateTime.now().subtract(Duration(days: day))),
          steps: 4200 + day * 450,
          calories: 180 + day * 25,
          water: 1200 + day * 100,
        ).toMap(),
      );
    }
    await batch.commit(noResult: true);
  }
}
