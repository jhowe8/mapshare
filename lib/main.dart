import 'package:flutter/material.dart';
import 'root_page.dart';
import 'auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Howe Crafty',
        theme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Color.fromRGBO(61, 90, 128, 1),
            backgroundColor: Color.fromRGBO(41, 50, 65, 1),
            accentColor: Color.fromRGBO(238, 108, 77, 1),

            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.accent),

            fontFamily: 'Helvetica',

            textTheme: TextTheme(
                headline: TextStyle(fontSize: 60.0, fontWeight: FontWeight.bold),
                title: TextStyle(fontSize: 30.0),
                button: TextStyle(
                    color: Colors.green, // This is not working.
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold
                )
            )
        ),
        home: new RootPage(auth: new Auth())
    );
  }
}