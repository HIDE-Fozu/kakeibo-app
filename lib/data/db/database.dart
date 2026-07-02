import 'package:drift/drift.dart';
import 'tables.dart';
import 'daos.dart';
import 'enums.dart';
import 'converters.dart';
import '../../domain/money/civil_date.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions],
  daos: [CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          // FK は接続ごとに有効化しないと SQLite が無視する。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
