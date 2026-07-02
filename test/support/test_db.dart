import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kakeibo_app/data/db/database.dart';

/// 1テスト＝新規インメモリDB。stream購読のタイマーがテスト間に漏れないよう
/// closeStreamsSynchronously を有効化する。
AppDatabase newMemoryDb() => AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
