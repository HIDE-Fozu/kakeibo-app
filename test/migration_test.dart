import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/test_db.dart';

void main() {
  test('schema v1 → v2: parentId列が追加され既存行はnull・取引も無傷', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v1.db');

    // v1スキーマを素のsqlite3で構築（v1当時のdrift生成DDL相当。
    // datetime列は store_date_time_values_as_text: true によりTEXT）
    final raw = sqlite3.open(file.path);
    raw.execute('''
CREATE TABLE "categories" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "name" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "icon" TEXT NULL,
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "is_archived" INTEGER NOT NULL DEFAULT 0,
  "is_system" INTEGER NOT NULL DEFAULT 0
);''');
    raw.execute('''
CREATE TABLE "transactions" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "type" TEXT NOT NULL,
  "amount" INTEGER NOT NULL,
  "date" TEXT NOT NULL,
  "category_id" INTEGER NOT NULL REFERENCES "categories" ("id") ON DELETE RESTRICT,
  "payment_method" TEXT NULL,
  "memo" TEXT NULL,
  "source" TEXT NOT NULL,
  "image_path" TEXT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);''');
    raw.execute(
        "INSERT INTO categories (name, type, sort_order) VALUES ('旧食費', 'expense', 0)");
    raw.execute(
        "INSERT INTO transactions (type, amount, date, category_id, source, created_at, updated_at) "
        "VALUES ('expense', 500, '2026-07-01', 1, 'manual', "
        "'2026-07-01T00:00:00.000Z', '2026-07-01T00:00:00.000Z')");
    raw.execute('PRAGMA user_version = 1');
    raw.close();

    // AppDatabase で開く → onUpgrade が走る
    final db = AppDatabase(NativeDatabase(file));
    final cats = await db.categoryDao.allCategories();
    expect(cats.single.name, '旧食費');
    expect(cats.single.parentId, isNull); // 追加列はnull補完
    expect(cats.single.icon, isNull); // v3バックフィルはプリセット名のみ対象
    final txs = await db.transactionDao.transactionsInMonth(2026, 7);
    expect(txs.single.amount, 500);
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 3);
    await db.close();
  });

  test('schema v2 → v3: プリセット名でicon補完・設定済み/独自名は不変', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration_v3');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v2.db');

    // v2スキーマ（v1 + parent_id）を素のsqlite3で構築
    final raw = sqlite3.open(file.path);
    raw.execute('''
CREATE TABLE "categories" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "name" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "icon" TEXT NULL,
  "sort_order" INTEGER NOT NULL DEFAULT 0,
  "is_archived" INTEGER NOT NULL DEFAULT 0,
  "is_system" INTEGER NOT NULL DEFAULT 0,
  "parent_id" INTEGER NULL REFERENCES "categories" ("id")
);''');
    raw.execute('''
CREATE TABLE "transactions" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "type" TEXT NOT NULL,
  "amount" INTEGER NOT NULL,
  "date" TEXT NOT NULL,
  "category_id" INTEGER NOT NULL REFERENCES "categories" ("id") ON DELETE RESTRICT,
  "payment_method" TEXT NULL,
  "memo" TEXT NULL,
  "source" TEXT NOT NULL,
  "image_path" TEXT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);''');
    raw.execute("INSERT INTO categories (name, type, sort_order) "
        "VALUES ('食費', 'expense', 0)"); // icon null → 🍚 に補完される
    raw.execute("INSERT INTO categories (name, type, icon, sort_order) "
        "VALUES ('日用品', 'expense', '🌟', 1)"); // 設定済み → 尊重
    raw.execute("INSERT INTO categories (name, type, sort_order) "
        "VALUES ('推し活', 'expense', 2)"); // 独自名 → null のまま
    raw.execute('PRAGMA user_version = 2');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    final cats = await db.categoryDao.allCategories();
    String? iconOf(String name) => cats.firstWhere((c) => c.name == name).icon;
    expect(iconOf('食費'), '🍚');
    expect(iconOf('日用品'), '🌟'); // ユーザー設定を上書きしない
    expect(iconOf('推し活'), isNull);
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 3);
    await db.close();
  });

  test('新規DB: システム未分類はparentId=null', () async {
    final db = newMemoryDb();
    addTearDown(db.close);
    final all = await db.categoryDao.allCategories();
    expect(all.where((c) => c.isSystem).every((c) => c.parentId == null), isTrue);
  });
}
