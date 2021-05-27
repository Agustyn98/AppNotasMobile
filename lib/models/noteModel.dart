class Note{
  int id;
  String text;
  String dateCreated;
  String dateModified;
  int idFolder;

  Note(int id, String text, String dateCreated, String dateModified, int idFolder){
    this.id = id;
    this.text = text;
    this.dateCreated = dateCreated;
    this.dateModified = dateModified;
    this.idFolder = idFolder;
  }

  Note.addNew(String text, String dateCreated, String dateModified, int idFolder){
    this.text = text;
    this.dateCreated = dateCreated;
    this.dateModified = dateModified;
    this.idFolder = idFolder;
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'dateCreated': dateCreated,
      'dateModified':dateModified,
      'idFolder': idFolder,
    };
  }


}