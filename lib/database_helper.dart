import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

class DatabaseHelper {
  static const _databaseName = 'database.db';
  static const _databaseVersion = 1;
  
  static const _usersTable = 'users';
  static const _debtsTable = 'debts';
  static const _debtorsTable = 'debtors';
  static const _paymentsTable = 'payments';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE "$_usersTable" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "name" TEXT NOT NULL,
        "avatar" BLOB
      );''');

    await db.execute('''
      CREATE TABLE "$_debtsTable" (
        "id"	INTEGER PRIMARY KEY AUTOINCREMENT,
        "title"	TEXT NOT NULL,
        "description" TEXT,
        "date" TEXT NOT NULL
      );''');

    await db.execute('''
      CREATE TABLE "$_debtorsTable" (
        "debtId"	INTEGER,
        "userId"	INTEGER,
        "amount"	INTEGER NOT NULL,
        FOREIGN KEY("debtId") REFERENCES "$_debtsTable"("id"),
        FOREIGN KEY("userId") REFERENCES "$_usersTable"("id"),
        PRIMARY KEY("debtId","userId")
      );''');
    
    await db.execute('''
      CREATE TABLE "$_paymentsTable" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "userId" INTEGER,
        "description" TEXT,
        "amount" INTEGER NOT NULL,
        "date" TEXT NOT NULL,
        FOREIGN KEY("userId") REFERENCES "$_usersTable"("id")
      );''');
  }

  Future<List<User>> fetchAllUsers() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> results = await db.query(_usersTable, orderBy: 'name');
    if (kDebugMode) Future.delayed(const Duration(seconds: 1));
    return results.map((e) => User.fromMap(e)).toList();
  }

  Future<User> updateUser(User user) async {
    Database db = await instance.database;
    await db.insert(_usersTable, user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return user;
  }

  Future<List<Payment>> fetchAllPayments() async {
    Database db = await instance.database;
    var res = await db.query(_paymentsTable);
    if (kDebugMode) Future.delayed(const Duration(seconds: 1));
    return res.map((e) => Payment.fromMap(e)).toList();
  }

  Future<Payment> updatePayment(Payment payment) async {
    Database db = await instance.database;
    await db.insert(_paymentsTable, payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return payment;
  }

  Future<User> createUser(String name, Uint8List? avatar) async {
    Database db = await instance.database;
    if (kDebugMode) Future.delayed(const Duration(seconds: 1));
    int id = await db.insert(_usersTable, {'name': name, 'avatar': avatar});
    return User(id: id, name: name, avatar: avatar);
  }

  Future<List<Debtor>> fetchAllDebtors() async {
    Database db = await instance.database;
    var res = await db.query(_debtorsTable);
    return res.map((e) => Debtor.fromMap(e)).toList();
  }

  Future<List<Debt>> fetchAllDebts() async {
    Database db = await instance.database;
    if (kDebugMode) await Future.delayed(const Duration(seconds: 1));
    var res = await db.query(_debtsTable, orderBy: 'date ASC, id DESC');
    return res.map((e) => Debt.fromMap(e)).toList();
  }

  Future<void> removePayment(int paymentId) async {
    Database db = await instance.database;
    if (kDebugMode) await Future.delayed(const Duration(seconds: 1));
    await db.delete(_paymentsTable, where: 'id = ?', whereArgs: [paymentId]);
  }

  Future<void> removeDebt(int debtId) async {
    Database db = await instance.database;
    if (kDebugMode) await Future.delayed(const Duration(seconds: 1));
    await db.transaction((txn) async {
      await txn.delete(_debtorsTable, where: 'debtId = ?', whereArgs: [debtId]);
      await txn.delete(_debtsTable, where: 'id = ?', whereArgs: [debtId]);
    });
  }

  Future<Debt> updateDebt(Debt debt, Map<int, int> userAmounts) async {
    Database db = await instance.database;
    if (kDebugMode) await Future.delayed(const Duration(seconds: 1));
    await db.transaction((txn) async {
      await txn.insert(_debtsTable, debt.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(_debtorsTable, where: 'debtId = ?', whereArgs: [debt.id]);
      for (var e in userAmounts.entries) {
        await txn.insert(_debtorsTable, {
          'debtId': debt.id,
          'userId': e.key,
          'amount': e.value
        });
      }
    });
    return debt;
  }

  /*

  Future<UserBalance> fetchUserBalance(int userId) async {
    Database db = await instance.database;
    await Future.delayed(const Duration(seconds: 1));

    var res = await db.rawQuery('''
      SELECT id, sum(amount) AS paid, sum(owed) AS owed
      FROM (
        SELECT u.id, coalesce(sum(p.amount), 0) AS amount, NULL AS owed FROM $_usersTable AS u LEFT JOIN $_paymentsTable AS p ON u.id=p.userId WHERE u.id = ?
        UNION ALL
        SELECT u.id, NULL, coalesce(sum(d.amount), 0) FROM $_usersTable AS u LEFT JOIN $_debtorsTable AS d ON u.id=d.userId WHERE u.id = ?
      );''', [userId, userId]);

    return UserBalance(owed: res[0]['owed'] as int, paid: res[0]['paid'] as int);
  }

  Future<List<dynamic>> fetchUserHistory(int userId) async {
    Database db = await instance.database;
    var payments = (await db.query(_paymentsTable, orderBy: 'date DESC, id DESC', where: 'userId = ?', whereArgs: [userId])).map((e) => Payment.fromMap(e)).toList();

    var debts = (await db.rawQuery('''
      SELECT $_debtsTable.*
      FROM $_debtsTable
      INNER JOIN $_debtorsTable
      ON $_debtsTable.id=$_debtorsTable.debtId
      WHERE $_debtorsTable.userId = ?
      ORDER BY date ASC, id DESC
    ''', [userId])).map((e) => Debt.fromMap(e)).toList();

    List<dynamic> combined = [...payments, ...debts];
    
    combined.sort((a, b) => a.date.compareTo(b.date));

    if (kDebugMode) await Future.delayed(const Duration(seconds: 2));
    return combined;
  }

  Future<List<DebtorUser>> fetchDebtors(int debtId) async {
    Database db = await instance.database;
    var res = await db.rawQuery('''
      SELECT $_usersTable.*, amount
      FROM $_debtorsTable
      LEFT JOIN $_usersTable ON $_usersTable.id=$_debtorsTable.userId
      WHERE debtId = ?;''', [debtId]
    );
    
    List<DebtorUser> debtorUsers = res.map((e) => DebtorUser(
        amount: e['amount'] as int, 
        user: User.fromMap(e)
      )).toList();

      return debtorUsers;
  }

  Future<double> fetchUserDebtTotal({required int userId, required int debtId}) async {
    Database db = await instance.database;
    var res = await db.query(_debtorsTable, where: 'userId = ? AND debtId = ?', whereArgs: [userId, debtId]);
    var amount = res[0]['amount'] as int;
    return amount/100;
  }

  Future<double> fetchDebtTotal({required int debtId}) async {
    Database db = await instance.database;
    var res = await db.rawQuery('''
      SELECT sum(amount) AS total
      FROM $_debtorsTable
      WHERE $_debtorsTable.debtId = ?
    ''', [debtId]);

    int totalInt = res[0]['total'] as dynamic;
    return totalInt/100;
  }
  */

  Future<Debt> createDebt({required String title, String? description, required DateTime date, required Map<int, int> userAmounts}) async {
    Database db = await instance.database;

    if (kDebugMode) Future.delayed(const Duration(seconds: 3));

    return await db.transaction((txn) async {
      var debtId = await txn.insert(_debtsTable, {
        'title': title,
        'description': description,
        'date': date.toIso8601String()
      });

      for (var e in userAmounts.entries) {
        await txn.insert(_debtorsTable, {
          'debtId': debtId,
          'userId': e.key,
          'amount': e.value
        });
      }

      return Debt(id: debtId, title: title, description: description, date: date);
    });
  }

  Future<Payment> createPayment({required int userId, required int amount, String? description, required DateTime date}) async {
    Database db = await instance.database;

    if (kDebugMode) Future.delayed(const Duration(seconds: 3));

    var id = await db.insert(_paymentsTable, {
      "userId": userId,
      "amount": amount,
      "description": description,
      "date": date.toIso8601String()
    });

    return Payment(
      id: id,
      userId: userId,
      amount: amount,
      description: description,
      date: date
    );
  }
}