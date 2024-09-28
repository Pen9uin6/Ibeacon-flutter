import "package:flutter/material.dart";
import "package:test/pages/home.dart";
import "package:test/pages/login.dart";
import "package:test/pages/beacon_list.dart";
import "package:test/routes.dart";

void main() => runApp(myApp());

class myApp extends StatelessWidget {
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
    );
  }
}
