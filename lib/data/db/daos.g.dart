// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daos.dart';

// ignore_for_file: type=lint
mixin _$TransactionDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $InstallmentPlansTable get installmentPlans =>
      attachedDatabase.installmentPlans;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  TransactionDaoManager get managers => TransactionDaoManager(this);
}

class TransactionDaoManager {
  final _$TransactionDaoMixin _db;
  TransactionDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$InstallmentPlansTableTableManager get installmentPlans =>
      $$InstallmentPlansTableTableManager(
        _db.attachedDatabase,
        _db.installmentPlans,
      );
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}

mixin _$RecurringRuleDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $RecurringRulesTable get recurringRules => attachedDatabase.recurringRules;
  $InstallmentPlansTable get installmentPlans =>
      attachedDatabase.installmentPlans;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  RecurringRuleDaoManager get managers => RecurringRuleDaoManager(this);
}

class RecurringRuleDaoManager {
  final _$RecurringRuleDaoMixin _db;
  RecurringRuleDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$RecurringRulesTableTableManager get recurringRules =>
      $$RecurringRulesTableTableManager(
        _db.attachedDatabase,
        _db.recurringRules,
      );
  $$InstallmentPlansTableTableManager get installmentPlans =>
      $$InstallmentPlansTableTableManager(
        _db.attachedDatabase,
        _db.installmentPlans,
      );
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}

mixin _$ChoreDaoMixin on DatabaseAccessor<AppDatabase> {
  $ChoreTasksTable get choreTasks => attachedDatabase.choreTasks;
  $ChoreRecordsTable get choreRecords => attachedDatabase.choreRecords;
  ChoreDaoManager get managers => ChoreDaoManager(this);
}

class ChoreDaoManager {
  final _$ChoreDaoMixin _db;
  ChoreDaoManager(this._db);
  $$ChoreTasksTableTableManager get choreTasks =>
      $$ChoreTasksTableTableManager(_db.attachedDatabase, _db.choreTasks);
  $$ChoreRecordsTableTableManager get choreRecords =>
      $$ChoreRecordsTableTableManager(_db.attachedDatabase, _db.choreRecords);
}

mixin _$CategoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $InstallmentPlansTable get installmentPlans =>
      attachedDatabase.installmentPlans;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  CategoryDaoManager get managers => CategoryDaoManager(this);
}

class CategoryDaoManager {
  final _$CategoryDaoMixin _db;
  CategoryDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$InstallmentPlansTableTableManager get installmentPlans =>
      $$InstallmentPlansTableTableManager(
        _db.attachedDatabase,
        _db.installmentPlans,
      );
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}
