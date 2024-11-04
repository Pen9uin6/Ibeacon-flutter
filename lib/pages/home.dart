import 'package:flutter/material.dart';
import "edit_beacon.dart";
import 'package:test/database.dart';
import 'package:test/background.dart';
import 'package:test/scan.dart';
import 'package:test/requirement_state_controller.dart';
import 'package:get/get.dart';

// 主頁面
class MainPage extends StatelessWidget {
  MainPage({super.key});
  final BackgroundExecute backgroundExecute = Get.put(BackgroundExecute());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0.0,
          title: const TabBar(
            labelPadding: EdgeInsets.zero,
            tabs: <Widget>[
              Tab(text: "Home"),
              Tab(text: "Manage"),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.play_arrow), // 啟用後台掃描的按鈕
              onPressed: () async {
                bool success = await backgroundExecute.initializeBackground();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('後台掃描已啟用')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('後台掃描啟動失敗')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.stop), // 停止後台掃描的按鈕
              onPressed: () async {
                await backgroundExecute.stopBackgroundExecute();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('後台掃描已停止')),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: <Widget>[
            HomePage(),
            ManagePage(),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                ),
                child: Text("User Name"),
              ),
              ListTile(
                title: const Text("Sign out"),
                onTap: () {
                  Navigator.pushReplacementNamed(context, "/login");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  List<Beacon> _BeaconsList = [];
  List<Map<String, dynamic>> _scannedBeacons = []; // 存掃描到的已配對 Beacon
  final ScanService _scanService = ScanService(); // 初始化
  final controller = Get.put(RequirementStateController());
  final BackgroundExecute backgroundExecute = Get.find<BackgroundExecute>();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 監聽應用狀態
    getList();
    _startBeaconScanning(); // 開始掃描

    // 監聽 RequirementStateController 狀態變化
    controller.bluetoothState.listen((state) {
      _checkAllRequirements();
    });
    controller.authorizationStatus.listen((status) {
      _checkAllRequirements();
    });
    controller.locationService.listen((enabled) {
      _checkAllRequirements();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除狀態監聽
    _stopBeaconScanning(); // 停止掃描
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // 應用進入背景
      // do nothing
    } else if (state == AppLifecycleState.resumed) {
      // 應用回到前景，停止前景服務並繼續正常掃描
      print("應用回到前景，停止背景服務");
      backgroundExecute.stopBackgroundExecute();
      if (!_isScanning) {
        _startBeaconScanning(); // 確保掃描正常進行
      }
    }
  }

  // 檢查所有要求的狀態
  void _checkAllRequirements() async {
    if (controller.bluetoothEnabled &&
        controller.authorizationStatusOk &&
        controller.locationServiceEnabled) {
      print('所有需求均滿足，開始掃描');
      _startBeaconScanning();
    } else {
      print('需求未滿足，暫停掃描');
      _stopBeaconScanning();
    }
  }

  // Read All Todos & rebuild UI
  void getList() async {
    final list = await BeaconDB.getBeacons();
    setState(() {
      _BeaconsList = list;
      print("從資料庫獲取的 Beacons: $_BeaconsList");
    });
  }

  // Start scanning the Beacon
  void _startBeaconScanning() {
    if (!_isScanning) {
      _scanService.startScanning();
      _scanService.beaconStream.listen((scannedBeacons) {
        setState(() {
          _scannedBeacons = scannedBeacons.where((scannedBeacon) {
            return _BeaconsList.any((beacon) =>
            beacon.uuid == scannedBeacon['uuid']);
          }).toList();
          print("掃描到的 Beacons: $_scannedBeacons");
        });
      });
      _isScanning = true;
    }
  }

  // Stop scanning the Beacon
  void _stopBeaconScanning() {
    if (_isScanning) {
      _scanService.dispose();
      _isScanning = false;
    }
  }

  // Search the Beacon according UUID and update the distance
  Beacon? _findBeaconByUUID(String uuid) {
    return _BeaconsList.firstWhere(
          (beacon) => beacon.uuid == uuid,
      orElse: () => Beacon(id: '', uuid: '', item: '', door: 0), // 回傳一個空的 Beacon
    );
  }

  // Add Beacon to DB
  void onAddBeacon(int door, String item, String uuid, Beacon beacon) async {
    final newBeacon = Beacon(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        uuid: uuid,
        item: item,
        door: door);
    await BeaconDB.insert(newBeacon);
    getList();
  }

  // Press Add Button
  void onAdd() {
    Navigator.push<void>(
        context,
        MaterialPageRoute(
            builder: (context) => EditPage(
                beacon: Beacon(id: '', uuid: '', item: '', door: 0),
                onSave: onAddBeacon)));
  }

  // Update Checkbox val of Beacon
  void onChangeCheckbox(val, beacon) async {
    final updateBeacon =
    Beacon(id: beacon.id, item: beacon.name, door: val ? 1 : 0);
    await BeaconDB.update(updateBeacon);
    getList();
  }

  @override
  Widget build(BuildContext context) {
    final homeBeacons = _scannedBeacons
        .where((b) => _findBeaconByUUID(b['uuid'])?.door == 1)
        .toList();
    final nothomeBeacons = _scannedBeacons
        .where((b) => _findBeaconByUUID(b['uuid'])?.door == 0)
        .toList();

    return Scaffold(
      body: Column(children: <Widget>[
        Expanded(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Door',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              // 顯示 Door 區域的 Beacons
              ...homeBeacons.map((beacon) {
                final Beacon? dbBeacon = _findBeaconByUUID(beacon['uuid']);
                return ListTile(
                  title: Text('${dbBeacon?.item}'),
                  subtitle: Text(
                      '距離: ${beacon['distance'].toStringAsFixed(2)} m'),
                );
              }).toList(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Items',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              // 顯示 Items 區域的 Beacons
              ...nothomeBeacons.map((beacon) {
                final Beacon? dbBeacon = _findBeaconByUUID(beacon['uuid']);
                return ListTile(
                  title: Text('${dbBeacon?.item}'),
                  subtitle: Text(
                      '距離: ${beacon['distance'].toStringAsFixed(2)} m'),
                );
              }).toList(),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// define ExtraActions (Update or Delete)
enum ExtraAction { edit, delete, toggleDoor }

class ManagePage extends StatefulWidget {
  ManagePage({super.key});

  @override
  _ManagePageState createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> with WidgetsBindingObserver {
  List<Beacon> _BeaconsList = [];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getList();
  }

  // Read All Todos & rebuild UI
  void getList() async {
    final list = await BeaconDB.getBeacons();
    setState(() {
      _BeaconsList = list;
    });
  }
  // Rename the Beacon
  void _renameBeacon(Beacon beacon) async {
    TextEditingController renameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rename the Beacon"),
          content: TextField(
            controller: renameController,
            decoration: const InputDecoration(
              labelText: "Enter new name",
              hintText: "New Beacon Name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (renameController.text.isNotEmpty) {
                  Beacon updatedBeacon = beacon.copyWith(item: renameController.text);
                  _updateBeacon(updatedBeacon);
                }
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _toggleDoorStatus(Beacon beacon) async {
    Beacon updatedBeacon = beacon.copyWith(door: beacon.door == 1 ? 0 : 1);
    _updateBeacon(updatedBeacon);
  }

  void _updateBeacon(Beacon beacon) async {
    await BeaconDB.update(beacon);
    getList();
  }

  void onSelectExtraAction(BuildContext context, ExtraAction action, Beacon beacon) {
    switch (action) {
      case ExtraAction.edit:
        _renameBeacon(beacon); // 彈出視窗以重新命名
        break;

      case ExtraAction.toggleDoor:
        _toggleDoorStatus(beacon); // 切換 door 狀態
        break;

      case ExtraAction.delete:
        onDeleteBeacon(beacon); // 刪除 Beacon
        break;

      default:
        print('Unexpected action!');
    }
  }

  // Add Beacon to DB
  void onAddBeacon(int door, String item, String uuid, Beacon beacon) async {
    final newBeacon = Beacon(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        uuid: uuid,
        item: item,
        door: door);
    await BeaconDB.insert(newBeacon);
    getList();
  }

  // Press Add Button
  void onAdd() {
    Navigator.push<void>(
        context,
        MaterialPageRoute(
            builder: (context) =>
                EditPage(
                    beacon: Beacon(id: '', uuid: '', item: '', door: 0),
                    onSave: onAddBeacon)));
  }

  // Update Checkbox val of Beacon
  void onChangeCheckbox(val, beacon) async {
    final updateBeacon =
    Beacon(id: beacon.id, item: beacon.name, door: val ? 1 : 0);
    await BeaconDB.update(updateBeacon);
    getList();
  }

  // Update Beacon
  void onEditBeacon(int door, String item, String uuid, beacon) async {
    final updateBeacon = Beacon(
      id: beacon.id,
      uuid: uuid,
      item: item,
      door: door,
    );
    await BeaconDB.update(updateBeacon);
    getList();
  }

  // Delete Beacon
  void onDeleteBeacon(beacon) async {
    await BeaconDB.delete(beacon.id);
    getList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Registered Beacons'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'All Beacons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._BeaconsList.map((beacon) {
            return ListTile(
              title: Text(beacon.item),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UUID: ${beacon.uuid}'),
                  Text('Door: ${beacon.door == 1 ? "Yes" : "No"}'),
                ],
              ),
              trailing: PopupMenuButton<ExtraAction>(
                onSelected: (action) => onSelectExtraAction(context, action, beacon),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ExtraAction.edit,
                    child: Text('Rename the Beacon'),
                  ),
                  const PopupMenuItem(
                    value: ExtraAction.toggleDoor,
                    child: Text('Toggle Door Status'),
                  ),
                  const PopupMenuItem(
                    value: ExtraAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}