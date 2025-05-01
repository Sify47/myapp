import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'brands.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE brands(
        id INTEGER PRIMARY KEY,
        name TEXT
      )
    ''');

    // Insert sample data
    await db.insert('brands', {'name': 'McDonalds'});
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    final db = await database;
    return await db.query('brands');
  }
}
