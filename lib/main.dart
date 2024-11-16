import "package:flutter/material.dart";
import "package:test/pages/home.dart";
import "package:test/pages/login.dart";
import "package:test/pages/welcome.dart";
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
    Permission.bluetoothAdvertise,
    Permission.location,
  ].request();
  bool allPermissionsGranted =
      statuses.values.every((status) => status.isGranted);

  if (!allPermissionsGranted) {
    print('缺少藍牙權限');
    return;
  }
  print(statuses[Permission.bluetooth]);
  print(statuses[Permission.bluetoothConnect]);
  print(statuses[Permission.bluetoothScan]);
  print(statuses[Permission.bluetoothAdvertise]);
  print(statuses[Permission.location]);
}

class myApp extends StatelessWidget {
  const myApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "物品守護精靈",
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      routes: {
        GitmeRebornRoutes.login: (context) => LoginPage(),
        GitmeRebornRoutes.home: (context) => HomePage(),
        GitmeRebornRoutes.welcome: (context) => WelcomePage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case GitmeRebornRoutes.root:
            return MaterialPageRoute(
              builder: (context) => WelcomePage(),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => HomePage(),
            );
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
