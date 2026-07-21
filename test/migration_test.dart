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
    final txs = await db.transactionDao.transactionsInMonth(2026, 7);
    expect(txs.single.amount, 500);
    expect(txs.single.splitGroupId, isNull); // v3列もnull補完
    expect(txs.single.storeName, isNull); // v4列もnull補完（元memoも無い）
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 5); // v1からでも現行(v5)まで一気に上がる
    await db.close();
  });

  test('schema v2 → v3: splitGroupId列が追加され既存行はnull・取引も無傷', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration_v3');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v2.db');

    // v2スキーマ（categories.parent_id あり / transactions.split_group_id なし）
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
    raw.execute(
        "INSERT INTO categories (name, type, sort_order) VALUES ('食費', 'expense', 0)");
    raw.execute(
        "INSERT INTO transactions (type, amount, date, category_id, source, created_at, updated_at) "
        "VALUES ('expense', 800, '2026-07-02', 1, 'manual', "
        "'2026-07-02T00:00:00.000Z', '2026-07-02T00:00:00.000Z')");
    raw.execute('PRAGMA user_version = 2');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    final txs = await db.transactionDao.transactionsInMonth(2026, 7);
    expect(txs.single.amount, 800);
    expect(txs.single.splitGroupId, isNull); // 追加列はnull補完
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 5);
    await db.close();
  });

  test('schema v3 → v4: storeName列が追加され既存memoが店名として移る', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration_v4');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v3.db');

    // v3スキーマ（split_group_id あり / store_name なし）
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
  "split_group_id" TEXT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);''');
    raw.execute(
        "INSERT INTO categories (name, type, sort_order) VALUES ('食費', 'expense', 0)");
    // 旧「メモ・店名」欄に店名が入っていた既存行
    raw.execute(
        "INSERT INTO transactions (type, amount, date, category_id, memo, source, created_at, updated_at) "
        "VALUES ('expense', 800, '2026-07-02', 1, 'サミット', 'manual', "
        "'2026-07-02T00:00:00.000Z', '2026-07-02T00:00:00.000Z')");
    raw.execute('PRAGMA user_version = 3');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    final txs = await db.transactionDao.transactionsInMonth(2026, 7);
    expect(txs.single.storeName, 'サミット'); // memo→storeName へ移行
    expect(txs.single.memo, isNull); // 移行後のmemoは空
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 5);
    await db.close();
  });

  test('schema v4 → v5: slug列が追加され既存シード行がバックフィルされる', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration_v5');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v4.db');

    // v4スキーマ（store_name あり / slug なし）
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
  "store_name" TEXT NULL,
  "memo" TEXT NULL,
  "source" TEXT NOT NULL,
  "image_path" TEXT NULL,
  "split_group_id" TEXT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);''');
    // 旧シード相当＋ユーザー作成カテゴリ。「その他」はexpense/incomeの両方。
    raw.execute(
        "INSERT INTO categories (id, name, type, sort_order) VALUES (1,'食費','expense',0)");
    raw.execute(
        "INSERT INTO categories (id, name, type, sort_order, parent_id) VALUES (2,'外食','expense',0,1)");
    raw.execute(
        "INSERT INTO categories (id, name, type, sort_order) VALUES (3,'その他','expense',12)");
    raw.execute(
        "INSERT INTO categories (id, name, type, sort_order) VALUES (4,'その他','income',16)");
    raw.execute(
        "INSERT INTO categories (id, name, type, sort_order, is_system) VALUES (5,'未分類','expense',17,1)");
    raw.execute(
        "INSERT INTO categories (id, name, type, sort_order) VALUES (6,'マイカテゴリ','expense',20)");
    raw.execute('PRAGMA user_version = 4');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    final cats = await db.categoryDao.allCategories();
    String? slugOf(int id) => cats.firstWhere((c) => c.id == id).slug;
    expect(slugOf(1), 'food');
    expect(slugOf(2), 'dining');
    expect(slugOf(3), 'otherExpense'); // その他(expense)
    expect(slugOf(4), 'otherIncome'); // その他(income)
    expect(slugOf(5), 'uncategorized');
    expect(slugOf(6), isNull); // ユーザー作成はnullのまま
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 5);
    await db.close();
  });

  test('新規DB: システム未分類はparentId=null', () async {
    final db = newMemoryDb();
    addTearDown(db.close);
    final all = await db.categoryDao.allCategories();
    expect(all.where((c) => c.isSystem).every((c) => c.parentId == null), isTrue);
  });
}
