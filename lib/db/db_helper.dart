import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/order.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'food_runner.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurant TEXT NOT NULL,
            item TEXT NOT NULL,
            notes TEXT,
            status TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertOrder(Order order) async {
    final database = await db;
    return await database.insert('orders', order.toMap());
  }

  Future<List<Order>> getOrders() async {
    final database = await db;
    final result = await database.query(
      'orders',
      orderBy: 'timestamp DESC',
    );
    return result.map((e) => Order.fromMap(e)).toList();
  }

  Future<int> updateOrder(Order order) async {
    final database = await db;
    return await database.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> deleteOrder(int id) async {
    final database = await db;
    return await database.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
