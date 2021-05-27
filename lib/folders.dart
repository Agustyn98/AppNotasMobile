import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/folderModel.dart';
import 'package:app_notas/notes.dart';
import 'package:app_notas/Database/dbHandler.dart';

class foldersApp extends StatefulWidget {
  const foldersApp({Key key}) : super(key: key);

  @override
  _foldersAppState createState() => _foldersAppState();
}

class _foldersAppState extends State<foldersApp> {
  final rowStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

  DB db = DB();

  Widget _buildRow(Folder folder) {
    return ListTile(
      onLongPress: () {
        _optionsDialog(folder);
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => notesApp(
                    folderId: folder.id,
                    folderName: folder.name,
                  )),
        );
      },
      leading: Icon(
        Icons.folder_open_rounded,
        color: Colors.yellow,
      ),
      title: Text(
        folder.name,
        style: rowStyle,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSortPreferences();
  }

  void _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortBy = (prefs.getString('sortFolders') ?? 'dateAsc');
    });
  }

  void _changeSortPreferences(String value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sortBy = value;
      prefs.setString('sortFolders', value);
    });
  }

  String _sortBy = 'dateAsc';
  Widget _showList(BuildContext context) {
    var future;
    if (_sortBy == 'dateAsc')
      future = db.getFoldersByIdAsc();
    else if (_sortBy == 'dateDesc')
      future = db.getFoldersByIdDesc();
    else
      future = db.getFoldersByName();

    return FutureBuilder(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<List<Folder>> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.length <= 0)
            return Center(
              child: Text(
                "Add a folder",
                style: TextStyle(fontSize: 22),
              ),
            );
          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data.length, //folders.lenght
            itemBuilder: (BuildContext context, int index) {
              return _buildRow(snapshot.data[index]); //folders[index]
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(
              thickness: 4,
            ),
          );
        } else {
          //return Center(child: Text("No folders" , style: TextStyle(color: Colors.white, fontSize: 30),),);
          return Center(
            child: Text(
              "Add a folder",
              style: TextStyle(fontSize: 26),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Folders"),
        actions: [
          IconButton(
              icon: Icon(
                Icons.sort,
              ),
              onPressed: _sortOptionsDialog),
        ],
      ),
      body: FutureBuilder(
        //build an object according to what I received from a Future<> snapshot
        future: db.initializeDB(), //what I want to get asynchronously
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          //snapshot: what I got
          if (snapshot.connectionState == ConnectionState.done)
            return _showList(context);
          else
            return Text("Cannot access DB");
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Folder",
        child: Icon(Icons.add),
        onPressed: _addFolderDialog,
      ),
    );
  }

  _addFolderDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                child: Text("Add a new folder", style: TextStyle(fontSize: 20),),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
              child: TextField(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(3),
                ),
                style: TextStyle(fontSize: 20),
                autofocus: true,
                onSubmitted: (text) {
                  if (text.isNotEmpty) {
                    setState(() {
                      var folder = Folder.addNew(text);
                      db.insertFolder(folder);
                      Navigator.pop(context);
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            )
          ],
        );
      },
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
                    _changeSortPreferences('dateAsc');
                  },
                  child: Text("Date ascending",),
                style: ButtonStyle(backgroundColor: _sortBy=='dateAsc'? MaterialStateProperty.all(Colors.green) : MaterialStateProperty.all(Colors.blue)),
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _changeSortPreferences('dateDesc');
                  },
                  style: ButtonStyle(backgroundColor: _sortBy=='dateDesc'? MaterialStateProperty.all(Colors.green) : MaterialStateProperty.all(Colors.blue)),
                  child: Text("Date descending")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _changeSortPreferences('name');
                  },
                  style: ButtonStyle(backgroundColor: _sortBy=='name'? MaterialStateProperty.all(Colors.green) : MaterialStateProperty.all(Colors.blue)),
                  child: Text("Name")),
            ],
          );
        });
  }

  _optionsDialog(Folder folder) {
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
                  folder.name,
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ))),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _changeNameDialog(folder);
                },
                child: Text("Change name")),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteDialog(folder.id);
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: Duration(seconds: 4) ,content: Text("Deleted folder and its notes",style: TextStyle(fontSize: 16))));
                    db.deleteFolder(id);
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

  _changeNameDialog(Folder folder) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          children: [
            TextField(
              decoration: InputDecoration(
                icon: Icon(Icons.drive_file_rename_outline),
              ),
              autofocus: true,
              onSubmitted: (text) {
                if (text.isNotEmpty) {
                  setState(() {
                    db.updateFolder(Folder(folder.id, text));
                    Navigator.pop(context);
                  });
                } else {
                  Navigator.pop(context);
                }
              },
            )
          ],
        );
      },
    );
  }
}
