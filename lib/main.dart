import "package:flutter/material.dart";
import "package:test/pages/home.dart";
import "package:test/pages/login.dart";
import "package:test/routes.dart";
import 'package:test/background_execute.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

//void main() => runApp(myApp());
Future main() async {
// Initialize FFI
  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;
  runApp(myApp());

  // 在應用啟動時檢查後台掃描狀態
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isBackgroundScanning = prefs.getBool('is_background_scanning') ?? false;
  if (isBackgroundScanning) {
    BackgroundExecute backgroundExecute = BackgroundExecute();
    await backgroundExecute.initializeBackground(); // 恢復後台掃描
  }
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
