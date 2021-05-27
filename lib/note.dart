import 'package:app_notas/models/noteModel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'Database/dbHandler.dart';
import 'models/folderModel.dart';

// Define a custom Form widget.
class noteApp extends StatefulWidget {

  final bool isNew;
  final Note note;

  const noteApp({Key key, this.isNew, this.note})
      : super(key: key);

  @override
  _noteAppState createState() => _noteAppState();
}

class _noteAppState extends State<noteApp> {
  DB db = DB();
  final myController = TextEditingController();


  @override
  void initState(){
    super.initState();
    _loadFontSize();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  int _currentSliderValue = 20;

  void _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentSliderValue = (prefs.getInt('font') ?? 20);
    });
  }

  void _changeCounter(int value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentSliderValue = value;
      prefs.setInt('font', _currentSliderValue);
    });
  }



  @override
  Widget build(BuildContext context) {
    db.initializeDB();
    if (widget.note.text != null && widget.note.text.isNotEmpty) {
      myController.text = widget.note.text;
      myController.selection = TextSelection.fromPosition(TextPosition(offset: myController.text.length));

    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Note'),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black26,
              ),
              child: Center(child: Text("Options",style: TextStyle(color: Colors.white, fontSize: 26),)),
            ),
            ListTile(
              leading: Icon(Icons.format_size),
              title: Text('Font size:', style: TextStyle(fontSize: 20),),
            ),
            ListTile(
              title: Container(
                width: 50,
                height: 20,
                child: Slider(
                  value: _currentSliderValue.toDouble(),
                  min: 10,
                  max: 30,
                  divisions: 10,
                  label: _currentSliderValue.round().toString(),
                  onChanged: (double value){
                      _changeCounter(value.toInt());
                  },
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('Details', style: TextStyle(fontSize: 20),),
              onTap: (){_detailsDialog(widget.note);},
            ),
            ListTile(
              leading: Icon(Icons.rule_folder_rounded),
              title: Text('Change folder',style: TextStyle(fontSize: 20)),
              onTap: (){_changeFolderDialog(widget.note.id);},
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete', style: TextStyle(fontSize: 20),),
              onTap: (){_deleteDialog(widget.note.id);},
            ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Copy text', style: TextStyle(fontSize: 20),),
              onTap: (){ _copyToClipboard();},
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
          ),
          onChanged:(text){ _saveNote(); },
          autofocus: true,
          controller: myController,
          style: TextStyle(fontSize: _currentSliderValue.toDouble()),
          keyboardType: TextInputType.multiline,
          maxLines: null,
          minLines: 40,
        ),
      ),
    );
  }

  _saveNote(){
    if (widget.isNew) {
      Note updatedNote = Note.addNew(
          myController.text, null, DateTime.now().toString(), null);
      db.updateLastNote(updatedNote);
    } else {
      Note updatedNote =
      Note(widget.note.id, myController.text, null, DateTime.now().toString(), -1);
      db.updateNoteText(updatedNote);
    }
  }


  _copyToClipboard(){

    Clipboard.setData(new ClipboardData(text: myController.text)).then((_){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: Duration(seconds: 6),content: Text("Copied to clipboard")));
    });

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
                  if(widget.isNew)
                    db.deleteLastNote();
                  else
                    db.deleteNote(id);

                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
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
                  child: Text("Note id: ${note.id}",style: TextStyle(fontSize: 18),)),
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

  _changeFolderDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: db.getFoldersByIdAsc(),
          builder: (BuildContext context,
              AsyncSnapshot<List<Folder>> snapshot) {

            if(snapshot.hasData) {

              var folders = snapshot.data;

              return SimpleDialog(
                contentPadding: EdgeInsets.all(10),
                children: [
                  Center(child: Text("Move to folder:",style: TextStyle(fontSize: 22),),),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 10, 0, 15),
                    child: DropdownButton<Folder>(
                      isExpanded: true,
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

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: Duration(seconds: 6) ,content: Text("Moved to '$folderName'",style: TextStyle(fontSize: 16))));
                          db.updateNoteFolder(id, newValue.id);
                          Navigator.pop(context);

                        });
                      },
                    ),
                  ),
                  ElevatedButton(onPressed: (){
                    Navigator.pop(context);
                  }, child: Center(child: Text("Cancel"),)),
                ],
              );
            }else{
              return Text("");
            }
          },

        );
      },
    );
  }

}
