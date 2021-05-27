class Folder{
  int id;
  String name;

  Folder(int id, String name){
    this.id = id;
    this.name = name;
  }

  Folder.addNew(String name){
    this.name = name;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

}