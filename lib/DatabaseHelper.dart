import 'package:debt_tracking_app/helper_models.dart';
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
        "name" TEXT NOT NULL
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
    List<Map<String, dynamic>> results = await db.query(_usersTable);
    await Future.delayed(const Duration(seconds: 1));
    return results.map((e) => User.fromMap(e)).toList();
  }

  Future<User> fetchUser(int id) async {
    Database db = await instance.database;
    var result = await db.query(_usersTable, where: 'id = ?', whereArgs: [id]);
    return User.fromMap(result[0]);
  }

  Future<int> update(User user) async {
    Database db = await instance.database;
    return await db.insert(_usersTable, user.toMap());
  }

  Future<User> createUser(String name) async {
    Database db = await instance.database;
    await Future.delayed(const Duration(seconds: 1));
    int id = await db.insert(_usersTable, {'name': name});
    return User(id: id, name: name);
  }

  Future<int> fetchUserBalance(int userId) async {
    await Future.delayed(const Duration(seconds: 1));
    return 1000;
  }

  Future<List<Debt>> fetchUserDebts(int userId) async {
    Database db = await instance.database;
    var res = await db.rawQuery('''
      SELECT
        $_debtsTable.*
      FROM debtors
      LEFT JOIN $_debtsTable ON $_debtsTable.id=$_debtorsTable.debtId
      WHERE userId = ?
      ;''', [userId]);
    return res.map((e) => Debt.fromMap(e)).toList();
  }

  Future<DebtViewData> fetchDebtViewData(int debtId) async {
    Database db = await instance.database;
    var res = await db.rawQuery('''
      SELECT 
        title as debtTitle, 
        description as debtDescription, 
        date as debtDate, 
        amount, 
        $_usersTable.* 
      FROM $_debtsTable 
      LEFT JOIN $_debtsTable ON $_debtsTable.id=$_debtorsTable.debtId 
      LEFT JOIN $_usersTable ON $_debtorsTable.userId=$_usersTable.id 
      WHERE debts.id=?;''', [debtId]);

    Debt debt = Debt.fromMap({
      'id': debtId,
      'title': res.first['debtTitle'],
      'description': res.first['debtDescription'],
      'date': res.first['debtDate']
    });
    
    List<DebtorUser> debtorUsers = res.map((e) => DebtorUser(
        amount: e['amount'] as int, 
        user: User.fromMap({
          'id': e['id'],
          'name': e['name']
        })
      )).toList();

      return DebtViewData(debt: debt, debtors: debtorUsers);
  }

  Future<List<Debt>> fetchDebts() async {
    Database db = await instance.database;
    var res = await db.query(_debtsTable);
    return res.map((e) => Debt.fromMap(e)).toList();
  }

  Future<double> fetchUserDebtTotal({required int userId, required int debtId}) async {
    Database db = await instance.database;
    var res = await db.query(_debtorsTable, where: 'userId = ? AND debtId = ?', whereArgs: [userId, debtId]);
    var amount = res[0]['amount'] as int;
    return amount/100;
  }

  Future<double> fetchDebtTotal({required int debtId}) async {
    Database db = await instance.database;
    var res = await db.query(_debtorsTable, where: 'debtId = ?', whereArgs: [debtId]);
    var amountsInt = res.map((e) => e['amount'] as int);
    int totalInt = 0;
    for (var amount in amountsInt) {
      totalInt += amount;
    }
    return totalInt/100;
  }

  Future<Debt> createDebt({required String title, String? description, required DateTime date, required Map<int, double> userAmounts}) async {
    Database db = await instance.database;

    await Future.delayed(const Duration(seconds: 3));

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
          'amount': (e.value*100).round()
        });
      }

      return Debt(id: debtId, title: title, date: date);
    });
  }

  Future<Payment> createPayment({required int userId, required double amount, String? description, required DateTime date}) async {
    Database db = await instance.database;

    await Future.delayed(const Duration(seconds: 3));

    var id = await db.insert(_paymentsTable, {
      "userId": userId,
      "amount": (amount*100).round(),
      "description": description,
      "date": date.toIso8601String()
    });

    return Payment(
      id: id,
      userId: userId,
      amount: (amount*100).round(),
      description: description,
      date: date
    );
  }
}