import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stocksnap/models/item.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path, 'stocksnap.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            sku TEXT,
            barcode TEXT,
            quantity INTEGER DEFAULT 0,
            cost_price REAL DEFAULT 0,
            sell_price REAL DEFAULT 0,
            photo_path TEXT,
            category TEXT,
            min_quantity INTEGER DEFAULT 0,
            notes TEXT,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertItem(Item item) async {
    try {
      final db = await database;
      return await db.insert(
        'items',
        item.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<int> updateItem(Item item) async {
    try {
      final db = await database;
      return await db.update(
        'items',
        item.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [item.id],
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<int> deleteItem(int id) async {
    try {
      final db = await database;
      return await db.delete('items', where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Item>> getAllItems() async {
    try {
      final db = await database;
      final maps = await db.query('items', orderBy: 'updated_at DESC');
      return maps.map(Item.fromMap).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<Item?> getItemByBarcode(String barcode) async {
    try {
      final db = await database;
      final maps = await db.query(
        'items',
        where: 'barcode = ?',
        whereArgs: [barcode],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Item.fromMap(maps.first);
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Item>> searchItems(String query) async {
    try {
      final db = await database;
      final q = '%${query.trim()}%';
      final maps = await db.query(
        'items',
        where: 'name LIKE ? OR sku LIKE ? OR barcode LIKE ?',
        whereArgs: [q, q, q],
        orderBy: 'updated_at DESC',
      );
      return maps.map(Item.fromMap).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Item>> getLowStockItems() async {
    try {
      final db = await database;
      final maps = await db.query(
        'items',
        where: 'quantity <= min_quantity AND min_quantity > 0',
        orderBy: 'quantity ASC',
      );
      return maps.map(Item.fromMap).toList();
    } catch (_) {
      rethrow;
    }
  }
}
