import 'package:flutter/material.dart';
import 'package:app_notas/folders.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppNotas',
      theme: ThemeData.dark(),
      home: foldersApp(),

    );
  }
}

