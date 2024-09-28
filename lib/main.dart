import "package:flutter/material.dart";
import "package:test/pages/home.dart";
import "package:test/pages/login.dart";
import "package:test/routes.dart";
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

//void main() => runApp(myApp());
Future main() async {
// Initialize FFI
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;
  runApp(myApp());
}

class myApp extends StatelessWidget {
  const myApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "test",
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      routes: {
        GitmeRebornRoutes.login: (context) => LoginPage(),
        GitmeRebornRoutes.home: (context) => MainPage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case GitmeRebornRoutes.root:
            return MaterialPageRoute(
              builder: (context) => MainPage(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => MainPage(),
            );
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
