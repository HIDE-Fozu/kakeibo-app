import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kakeibo_app/data/db/database.dart';
import 'package:kakeibo_app/data/db/enums.dart';
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
    expect(v, 10); // v1からでも現行(v10)まで一気に上がる
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
    expect(v, 10);
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
    expect(v, 10);
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
    expect(v, 10);
    await db.close();
  });

  test('schema v5 → v6: recurring_rules テーブルが作られ既存データも無傷', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration_v6');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v5.db');

    // v5スキーマ（slug あり / recurring_rules なし）
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
  "slug" TEXT NULL,
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
    raw.execute(
        "INSERT INTO categories (id, name, type, sort_order, slug) VALUES (1,'食費','expense',0,'food')");
    raw.execute(
        "INSERT INTO transactions (type, amount, date, category_id, source, created_at, updated_at) "
        "VALUES ('expense', 1200, '2026-08-01', 1, 'manual', "
        "'2026-08-01T00:00:00.000Z', '2026-08-01T00:00:00.000Z')");
    raw.execute('PRAGMA user_version = 5');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    // 既存データ無傷
    final txs = await db.transactionDao.transactionsInMonth(2026, 8);
    expect(txs.single.amount, 1200);
    // 新テーブルが使える（挿入→読み出し）
    expect(await db.recurringRuleDao.allRules(), isEmpty);
    await db.customStatement(
        "INSERT INTO recurring_rules (type, amount, category_id, day_of_month, start_ym, created_at, updated_at) "
        "VALUES ('expense', 80000, 1, 1, 202608, '2026-08-01T00:00:00.000Z', '2026-08-01T00:00:00.000Z')");
    final rules = await db.recurringRuleDao.allRules();
    expect(rules.single.amount, 80000);
    expect(rules.single.isActive, isTrue); // 既定値
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 10);
    await db.close();
  });

  test('schema v6 → v7: chore_tasks/chore_records が作られ既存データも無傷', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration_v7');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v6.db');

    // v6スキーマ（recurring_rules あり / chore_* なし）
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
  "slug" TEXT NULL,
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
    raw.execute('''
CREATE TABLE "recurring_rules" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "type" TEXT NOT NULL,
  "amount" INTEGER NOT NULL,
  "category_id" INTEGER NOT NULL REFERENCES "categories" ("id") ON DELETE RESTRICT,
  "day_of_month" INTEGER NOT NULL,
  "store_name" TEXT NULL,
  "memo" TEXT NULL,
  "is_active" INTEGER NOT NULL DEFAULT 1,
  "start_ym" INTEGER NOT NULL,
  "end_ym" INTEGER NULL,
  "last_generated_ym" INTEGER NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);''');
    raw.execute(
        "INSERT INTO categories (id, name, type, sort_order, slug) VALUES (1,'食費','expense',0,'food')");
    raw.execute(
        "INSERT INTO recurring_rules (type, amount, category_id, day_of_month, start_ym, created_at, updated_at) "
        "VALUES ('expense', 80000, 1, 27, 202608, '2026-08-01T00:00:00.000Z', '2026-08-01T00:00:00.000Z')");
    raw.execute('PRAGMA user_version = 6');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    // 既存データ無傷
    final rules = await db.recurringRuleDao.allRules();
    expect(rules.single.amount, 80000);
    // 新テーブルが使える（挿入→読み出し→カスケード削除）
    expect(await db.choreDao.allTasks(), isEmpty);
    await db.customStatement(
        "INSERT INTO chore_tasks (name, day_of_month, anchor_date) VALUES ('ハブラシ交換', 30, '2026-08-01')");
    final task = (await db.choreDao.allTasks()).single;
    expect(task.emoji, '📌'); // 既定値
    expect(task.anchorDate.toIso(), '2026-08-01');
    await db.customStatement(
        "INSERT INTO chore_records (task_id, done_date) VALUES (${task.id}, '2026-08-05')");
    expect((await db.choreDao.allRecords()).length, 1);
    await db.choreDao.deleteTask(task.id);
    expect(await db.choreDao.allRecords(), isEmpty); // FK ON でカスケード
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 10);
    await db.close();
  });

  test('schema v7 → v9: 「N日ごと」を維持しつつ毎月の予定日を初期化', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration_v8');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v7.db');

    // v7当時の chore_tasks（interval_days）を素のsqlite3で構築
    // （transactions は v10 マイグレーションが列追加で触るので最小定義を用意）
    final raw = sqlite3.open(file.path);
    raw.execute('''
CREATE TABLE "transactions" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "type" TEXT NOT NULL,
  "amount" INTEGER NOT NULL,
  "date" TEXT NOT NULL,
  "category_id" INTEGER NOT NULL,
  "payment_method" TEXT NULL,
  "store_name" TEXT NULL,
  "memo" TEXT NULL,
  "source" TEXT NOT NULL,
  "image_path" TEXT NULL,
  "split_group_id" TEXT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);''');
    raw.execute('''
CREATE TABLE "chore_tasks" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "name" TEXT NOT NULL,
  "emoji" TEXT NOT NULL DEFAULT '📌',
  "interval_days" INTEGER NOT NULL,
  "anchor_date" TEXT NOT NULL,
  "archived" INTEGER NOT NULL DEFAULT 0,
  "created_at" TEXT NOT NULL
);''');
    raw.execute('''
CREATE TABLE "chore_records" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "task_id" INTEGER NOT NULL REFERENCES "chore_tasks" ("id") ON DELETE CASCADE,
  "done_date" TEXT NOT NULL,
  "memo" TEXT NOT NULL DEFAULT '',
  "created_at" TEXT NOT NULL
);''');
    raw.execute(
        "INSERT INTO chore_tasks (name, emoji, interval_days, anchor_date, created_at) "
        "VALUES ('ハブラシ交換', '🪥', 14, '2026-08-08', '2026-08-08T00:00:00.000Z')");
    raw.execute(
        "INSERT INTO chore_tasks (name, emoji, interval_days, anchor_date, created_at) "
        "VALUES ('まくら干し', '🛏', 45, '2026-07-20', '2026-07-20T00:00:00.000Z')");
    raw.execute(
        "INSERT INTO chore_records (task_id, done_date, created_at) "
        "VALUES (1, '2026-08-01', '2026-08-01T00:00:00.000Z')");
    raw.execute('PRAGMA user_version = 7');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    final tasks = await db.choreDao.allTasks();
    // 繰り返し方は everyDays を維持し、間隔もそのまま（意味が変わらない）
    expect(tasks.map((t) => (t.name, t.repeatUnit, t.intervalDays)).toList(), [
      ('ハブラシ交換', ChoreRepeatUnit.everyDays, 14),
      ('まくら干し', ChoreRepeatUnit.everyDays, 45),
    ]);
    // 毎月の予定日は次回期日の日を初期値に（8/8+14=8/22 / 7/20+45=9/3）
    expect(tasks.map((t) => t.dayOfMonth).toList(), [22, 3]);
    expect(tasks.first.anchorDate.toIso(), '2026-08-08'); // 他列は無傷
    expect(tasks.first.emoji, '🪥');
    // 記録も無傷・FKカスケードも生きている
    expect((await db.choreDao.allRecords()).length, 1);
    await db.choreDao.deleteTask(tasks.first.id);
    expect(await db.choreDao.allRecords(), isEmpty);
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 10);
    await db.close();
  });

  test('schema v8 → v9: 毎月N日はそのまま・繰り返し方と間隔が既定で入る', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration_v9');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v8.db');

    // v8当時の chore_tasks（day_of_month のみ・interval_days なし）
    final raw = sqlite3.open(file.path);
    raw.execute('''
CREATE TABLE "transactions" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "type" TEXT NOT NULL,
  "amount" INTEGER NOT NULL,
  "date" TEXT NOT NULL,
  "category_id" INTEGER NOT NULL,
  "payment_method" TEXT NULL,
  "store_name" TEXT NULL,
  "memo" TEXT NULL,
  "source" TEXT NOT NULL,
  "image_path" TEXT NULL,
  "split_group_id" TEXT NULL,
  "created_at" TEXT NOT NULL,
  "updated_at" TEXT NOT NULL
);''');

    raw.execute('''
CREATE TABLE "chore_tasks" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "name" TEXT NOT NULL,
  "emoji" TEXT NOT NULL DEFAULT '📌',
  "day_of_month" INTEGER NOT NULL,
  "anchor_date" TEXT NOT NULL,
  "archived" INTEGER NOT NULL DEFAULT 0,
  "created_at" TEXT NOT NULL
);''');
    raw.execute('''
CREATE TABLE "chore_records" (
  "id" INTEGER PRIMARY KEY AUTOINCREMENT,
  "task_id" INTEGER NOT NULL REFERENCES "chore_tasks" ("id") ON DELETE CASCADE,
  "done_date" TEXT NOT NULL,
  "memo" TEXT NOT NULL DEFAULT '',
  "created_at" TEXT NOT NULL
);''');
    raw.execute(
        "INSERT INTO chore_tasks (name, emoji, day_of_month, anchor_date, created_at) "
        "VALUES ('ハブラシ交換', '🪥', 22, '2026-08-08', '2026-08-08T00:00:00.000Z')");
    raw.execute(
        "INSERT INTO chore_records (task_id, done_date, created_at) "
        "VALUES (1, '2026-08-01', '2026-08-01T00:00:00.000Z')");
    raw.execute('PRAGMA user_version = 8');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    final t = (await db.choreDao.allTasks()).single;
    expect(t.repeatUnit, ChoreRepeatUnit.monthlyDay); // 既定
    expect(t.dayOfMonth, 22); // 既存値は無傷
    expect(t.intervalDays, 30); // 列のdefault
    expect(t.emoji, '🪥');
    expect((await db.choreDao.allRecords()).length, 1);
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 10);
    await db.close();
  });

  test('schema v9 → v10: installment_plans が作られ取引に紐付け列が付く', () async {
    final dir = Directory.systemTemp.createTempSync('kakeibo_migration_v10');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windowsのハンドル解放遅延。OSのクリーンアップに任せる。
      }
    });
    final file = File('${dir.path}${Platform.pathSeparator}v9.db');

    // v9スキーマの必要最小限（categories / transactions は v10 で触られる側）
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
  "slug" TEXT NULL,
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
    raw.execute(
        "INSERT INTO categories (id, name, type, sort_order, slug) VALUES (1,'食費','expense',0,'food')");
    raw.execute(
        "INSERT INTO transactions (type, amount, date, category_id, source, created_at, updated_at) "
        "VALUES ('expense', 1200, '2026-08-01', 1, 'manual', "
        "'2026-08-01T00:00:00.000Z', '2026-08-01T00:00:00.000Z')");
    raw.execute('PRAGMA user_version = 9');
    raw.close();

    final db = AppDatabase(NativeDatabase(file));
    // 既存データ無傷・新列は null
    final txs = await db.transactionDao.transactionsInMonth(2026, 8);
    expect(txs.single.amount, 1200);
    expect(txs.single.installmentPlanId, isNull);
    // 計画テーブルが使え、取引を紐づけられる
    await db.customStatement(
        "INSERT INTO installment_plans (principal, count, annual_rate_percent, category_id, day_of_month, start_ym, created_at, updated_at) "
        "VALUES (33000, 10, 17.0, 1, 15, 202609, '2026-08-16T00:00:00.000Z', '2026-08-16T00:00:00.000Z')");
    await db.customStatement(
        "INSERT INTO transactions (type, amount, date, category_id, source, installment_plan_id, created_at, updated_at) "
        "VALUES ('expense', 3567, '2026-09-15', 1, 'manual', 1, "
        "'2026-08-16T00:00:00.000Z', '2026-08-16T00:00:00.000Z')");
    final sep = await db.transactionDao.transactionsInMonth(2026, 9);
    expect(sep.single.installmentPlanId, 1);
    final v = await db
        .customSelect('PRAGMA user_version')
        .getSingle()
        .then((r) => r.read<int>('user_version'));
    expect(v, 10);
    await db.close();
  });

  test('新規DB: システム未分類はparentId=null', () async {
    final db = newMemoryDb();
    addTearDown(db.close);
    final all = await db.categoryDao.allCategories();
    expect(all.where((c) => c.isSystem).every((c) => c.parentId == null), isTrue);
  });
}
