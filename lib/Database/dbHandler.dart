import 'dart:async';
import 'package:app_notas/models/folderModel.dart';
import 'package:app_notas/models/noteModel.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  Database _db;


  initializeDB() async {
    print("DB INIT");

    String path = await getDatabasesPath();
    _db = await openDatabase(
      join(path, 'AppNotas.db'),
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE folders(id INTEGER PRIMARY KEY, name TEXT)",
        );
        await database.execute(
          "CREATE TABLE notes(id INTEGER PRIMARY KEY, text TEXT,dateCreated TEXT,dateModified TEXT, idFolder INTEGER)",
        );
      },
      version: 1,
    );
  }

  Future<void> insertFolder(Folder folder) async {
    print(await _db.insert(
      'folders',
      folder.toMap(),
    ));
  }

  Future<void> insertNote(Note note) async {
    print(await _db.insert(
      'notes',
      note.toMap(),
    ));
  }

  Future<List<Folder>> getFoldersByIdAsc() async {
    final List<Map<String, dynamic>> maps = await _db.query('folders');

    // Convert the List<Map<String, dynamic> into a List<Folder>.
    return List.generate(maps.length, (i) {
      return Folder(maps[i]['id'], maps[i]['name']);
    });
  }

  Future<List<Folder>> getFoldersByIdDesc() async {
    final List<Map<String, dynamic>> maps = await _db.query('folders', orderBy: 'id DESC');

    // Convert the List<Map<String, dynamic> into a List<Folder>.
    return List.generate(maps.length, (i) {
      return Folder(maps[i]['id'], maps[i]['name']);
    });
  }

  Future<List<Folder>> getFoldersByName() async {
    final List<Map<String, dynamic>> maps = await _db.query('folders', orderBy: 'lower(name) ASC');

    // Convert the List<Map<String, dynamic> into a List<Folder>.
    return List.generate(maps.length, (i) {
      return Folder(maps[i]['id'], maps[i]['name']);
    });
  }

  Future<List<Note>> getNotesByFolder(int idFolder) async {
    final List<Map<String, dynamic>> maps =
        await _db.query('notes', where: 'idFolder = $idFolder');

    return List.generate(maps.length, (i) {
      return Note(maps[i]['id'], maps[i]['text'], maps[i]['dateCreated'],
          maps[i]['dateModified'], maps[i]['idFolder']);
    });
  }


  static const int CREATED_ASC = 1, CREATED_DESC = 2, MODIFIED_ASC = 3, MODIFIED_DESC = 4;

  Future<List<Note>> getNotesByFolderOrdered(int idFolder, int orderBy) async {
    String orderByString = 'id asc';
    switch(orderBy){
      case CREATED_ASC:
        orderByString = 'id asc';
        break;
      case CREATED_DESC:
        orderByString = 'id desc';
        break;
      case MODIFIED_ASC:
        orderByString = 'dateModified asc';
        break;
      case MODIFIED_DESC:
        orderByString = 'dateModified desc';
        break;
    }
    final List<Map<String, dynamic>> maps =
    await _db.query('notes', where: 'idFolder = $idFolder', orderBy: orderByString);

    return List.generate(maps.length, (i) {
      return Note(maps[i]['id'], maps[i]['text'], maps[i]['dateCreated'],
          maps[i]['dateModified'], maps[i]['idFolder']);
    });
  }

  Future<void> deleteFolder(int id) async {
    await _db.delete(
      'folders',
      // Use a `where` clause to delete a specific dog.
      where: "id = ?",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );

    await _db.delete(
      'notes',
      // Use a `where` clause to delete a specific dog.
      where: "idFolder = ?",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<void> deleteNote(int id) async {
    await _db.delete(
      'notes',
      // Use a `where` clause to delete a specific dog.
      where: "id = ?",
      // Pass the Dog's id as a whereArg to prevent SQL injection.
      whereArgs: [id],
    );
  }

  Future<void> deleteLastNote() async {
      await _db.rawDelete("DELETE FROM notes WHERE id = (SELECT max(id) FROM notes)");
  }

  Future<void> updateFolder(Folder folder) async {
    await _db.update(
      'folders',
      folder.toMap(),
      // Ensure that the folder has a matching id.
      where: "id = ?",
      // Pass the folder's id as a whereArg to prevent SQL injection.
      whereArgs: [folder.id],
    );
  }

  Future<void> updateNoteFolder(int noteId, int folderId) async {
    await _db.rawUpdate(
        "UPDATE notes SET idFolder = $folderId WHERE id = $noteId");
  }

  Future<void> updateNoteText(Note note) async {
    await _db.rawUpdate(
        "UPDATE notes SET text = '${note.text}', dateModified = '${note.dateModified}'  WHERE id = ${note.id}");
  }

  Future<void> updateLastNote(Note note) async {
    await _db.rawUpdate(
        "UPDATE notes SET text = '${note.text}' , dateModified = '${note.dateModified}' WHERE id = (SELECT max(id) FROM notes)");
  }

  Future<List<Note>> searchNotes(String search, int idFolder) async {
    final List<Map<String, dynamic>> maps = await _db.query('notes',
        where: "text like '%$search%' AND idFolder = $idFolder");

    return List.generate(maps.length, (i) {
      return Note(maps[i]['id'], maps[i]['text'], maps[i]['dateCreated'],
          maps[i]['dateModified'], maps[i]['idFolder']);
    });
  }

  Future<void> closeDB() async {
    await _db.close();
  }
}
