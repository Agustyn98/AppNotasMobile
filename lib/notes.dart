import 'package:app_notas/models/noteModel.dart';
import 'package:flutter/material.dart';
import 'package:app_notas/note.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Database/dbHandler.dart';
import 'models/folderModel.dart';

class notesApp extends StatefulWidget {
  final int folderId;
  final String folderName;

  const notesApp({Key key, this.folderId, this.folderName}) : super(key: key);

  @override
  _notesAppState createState() => _notesAppState();
}

class _notesAppState extends State<notesApp> {
  final rowStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);

  DB db = DB();

   _getFirstLine(String text) {
    String newText = "";
    int length = text.length;
    if(length <= 1)
      return text;
    if(text[0] == '\r' || text[0] == '\n') {
      for (int i = 0; i < length; i++) {
        if (text[i] == '\r' || text[i] == '\n') {
          newText = text.substring(i + 1, length);

        } else {
          return newText;
        }
      }
    }else{
      return text;
    }
  }

  Widget _buildRow(Note note) {
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => noteApp(
                    note: note,
                    isNew: false,
                  )),
        ).then((value) => _refreshPage());
      },
      onLongPress: () {
        _optionsDialog(note);
      },
      title: Text(
        _getFirstLine(note.text),
        style: rowStyle,
        maxLines: 1,
      ),
    );
  }

  _refreshPage() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadSortPreferences();
  }

  bool searchFlag = false;
  String searchText;

  int _sortBy = 1;

  void _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortBy = (prefs.getInt('sortNotes') ?? 1);
    });
  }

  void _changeSortPreferences(int value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortBy = value;
      prefs.setInt('sortNotes', value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.folderName),
        actions: [
          IconButton(
              icon: Icon(
                Icons.sort,
              ),
              onPressed: _sortOptionsDialog),
        ],
      ),
      body: Column(
        children: [
          Material(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
                child: TextField(
                  onSubmitted: (search) {
                    setState(() {
                      if (search.isEmpty) {
                        searchFlag = false;
                        searchText = search;
                      } else {
                        searchFlag = true;
                        searchText = search;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(13),
                    border: OutlineInputBorder(),
                    labelText: 'Search...',
                  ),
                ),
              )),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(7),
              child: Card(
                child: FutureBuilder(
                  future: db.initializeDB(),
                  builder:
                      (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return FutureBuilder(
                        future: searchFlag
                            ? db.searchNotes(searchText, widget.folderId)
                            : db.getNotesByFolderOrdered(
                                widget.folderId, _sortBy),
                        builder: (BuildContext context,
                            AsyncSnapshot<List<Note>> snapshot) {
                          if (snapshot.hasData) {
                            if (snapshot.data.length <= 0)
                              return Center(
                                child: Text(
                                  "Add a note",
                                  style: TextStyle(fontSize: 22),
                                ),
                              );
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                              itemCount: snapshot.data.length,
                              itemBuilder: (BuildContext context, int index) {
                                return _buildRow(snapshot.data[index]);
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(
                                thickness: 2,
                              ),
                            );
                          } else {
                            return Text("");
                          }
                        },
                      );
                    } else {
                      return Text("");
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        tooltip: "Add note",
        onPressed: () {
          Note newNote = Note.addNew("", DateTime.now().toString(),
              DateTime.now().toString(), widget.folderId);
          db.insertNote(newNote);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => noteApp(note: newNote, isNew: true)),
          ).then((value) => _refreshPage());
        },
      ),
    );
  }

  _sortOptionsDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(10),
            children: [
              Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(
                    child: Text(
                      "Sort By:",
                      style: TextStyle(fontSize: 22),
                    ),
                  )),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _changeSortPreferences(DB.CREATED_ASC);
                  },
                  style: ButtonStyle(backgroundColor: _sortBy==1 ? MaterialStateProperty.all(Colors.green) : MaterialStateProperty.all(Colors.blue)),
                  child: Text("Date created ascending")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _changeSortPreferences(DB.CREATED_DESC);
                  },
                  style: ButtonStyle(backgroundColor: _sortBy==2 ? MaterialStateProperty.all(Colors.green) : MaterialStateProperty.all(Colors.blue)),
                  child: Text("Date created descending")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _changeSortPreferences(DB.MODIFIED_ASC);
                  },
                  style: ButtonStyle(backgroundColor: _sortBy==3 ? MaterialStateProperty.all(Colors.green) : MaterialStateProperty.all(Colors.blue)),
                  child: Text("Date modified ascending")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _changeSortPreferences(DB.MODIFIED_DESC);
                  },
                  style: ButtonStyle(backgroundColor: _sortBy==4 ? MaterialStateProperty.all(Colors.green) : MaterialStateProperty.all(Colors.blue)),
                  child: Text("Date modified descending")),
            ],
          );
        });
  }

  _optionsDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.all(10),
          children: [
            Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                    child: Text(
                  "Options:",
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ))),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _detailsDialog(note);
                },
                child: Text("Details")),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _changeFolderDialog(note.id);
                },
                child: Text("Change folder")),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteDialog(note.id);
                },
                child: Text("Delete")),
          ],
        );
      },
    );
  }

  _deleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.all(10),
          children: [
            Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                    child: Text(
                  "Are you sure?",
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ))),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    db.deleteNote(id);
                    Navigator.pop(context);
                  });
                },
                child: Text("Yes")),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel")),
          ],
        );
      },
    );
  }

  _detailsDialog(Note note) {
    String dateCreated = note.dateCreated.substring(0, 16);
    String dateModified = note.dateModified.substring(0, 16);
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          contentPadding: EdgeInsets.all(10),
          children: [
            Padding(
                padding: EdgeInsets.all(3),
                child: Center(
                    child: Text(
                  "Date created:  $dateCreated\nLast modified: $dateModified",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ))),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 1, 0, 8),
              child: Center(
                  child: Text(
                "Note id: ${note.id}",
                style: TextStyle(fontSize: 18),
              )),
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.arrow_back)),
          ],
        );
      },
    );
  }

  //var currentFolderIndex = itemsIds.indexOf(widget.folderId) ?? 0;
  String dropdownValue;

  _changeFolderDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: db.getFoldersByIdAsc(),
          builder:
              (BuildContext context, AsyncSnapshot<List<Folder>> snapshot) {
            if (snapshot.hasData) {
              var folders = snapshot.data;

              return SimpleDialog(
                contentPadding: EdgeInsets.all(10),
                children: [
                  Center(
                    child: Text(
                      "Move to folder:",
                      style: TextStyle(fontSize: 22),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(
                      child: DropdownButton<Folder>(
                        icon: const Icon(Icons.arrow_downward),
                        iconSize: 24,
                        items: folders
                            .map<DropdownMenuItem<Folder>>((Folder value) {
                          return DropdownMenuItem<Folder>(
                            value: value,
                            child: Text(value.name.length > 25 ? value.name.substring(0,25)+"..." : value.name,),
                          );
                        }).toList(),
                        onChanged: (Folder newValue) {
                          setState(() {
                            var folderName;
                            if(newValue.name.length > 25)
                              folderName = newValue.name.substring(0,25) + "...";
                            else
                              folderName = newValue.name;

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: Duration(seconds: 6),content: Text("Moved to '$folderName'", style: TextStyle(fontSize: 16),)));

                            db.updateNoteFolder(id, newValue.id);
                            Navigator.pop(context);
                          });
                        },
                      ),
                    ),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Center(
                        child: Text("Cancel"),
                      )),
                ],
              );
            } else {
              return Text("");
            }
          },
        );
      },
    );
  }
}
