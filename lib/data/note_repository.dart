import 'package:sqflite/sqflite.dart';
import '../models/note.dart';
import 'database_helper.dart';

class NoteRepository {
  NoteRepository._();
  static final NoteRepository instance = NoteRepository._();

  Future<Note> insert(Note note) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert(DatabaseHelper.notesTable, note.toMap());
    return note..id = id;
  }

  Future<Note?> getById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      DatabaseHelper.notesTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Note>> getAll({int? limit, int? offset}) async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      DatabaseHelper.notesTable,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<int> update(Note note) async {
    if (note.id == null) throw ArgumentError('Note id required for update');
    final db = await DatabaseHelper.instance.database;
    return db.update(
      DatabaseHelper.notesTable,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(
      DatabaseHelper.notesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> count() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${DatabaseHelper.notesTable}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
