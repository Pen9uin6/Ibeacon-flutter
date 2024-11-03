import "package:flutter/material.dart";
import "package:test/pages/home.dart";
import "package:test/pages/login.dart";
import "package:test/routes.dart";
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:permission_handler/permission_handler.dart';

//void main() => runApp(myApp());
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
// Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
// request the bluetooth permission
  await _checkBlueInfo();
  runApp(myApp());
}

Future<void> _checkBlueInfo() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise
  ].request();
  print(statuses[Permission.bluetoothConnect]);
  print(statuses[Permission.bluetoothScan]);
  print(statuses[Permission.bluetoothAdvertise]);
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
