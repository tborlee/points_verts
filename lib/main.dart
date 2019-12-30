import 'package:flutter/material.dart';
import 'package:points_verts/walk_list.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        buttonTheme: ButtonThemeData(
            buttonColor: Colors.green,
            splashColor: Colors.greenAccent,
            textTheme: ButtonTextTheme.primary),
      ),
      darkTheme:
          ThemeData(brightness: Brightness.dark, primarySwatch: Colors.green),
      home: WalkList(),
    );
  }
}
