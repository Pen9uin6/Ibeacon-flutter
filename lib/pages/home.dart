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
              Tab(text: "Others"),
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
            BeaconList(),
            const Text("Others"),
          ],
        ),
      ),
    );
  }
}


// define ExtraActions (Update or Delete)
enum ExtraAction { edit, delete }

class BeaconList extends StatefulWidget {
  const BeaconList({super.key});
  @override
  _BeaconListState createState() => _BeaconListState();
}

class _BeaconListState extends State<BeaconList> with WidgetsBindingObserver {
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
      _onWillPop(); // 問是否下次關閉是否啟動背景掃描
      print("應用回到前景，停止背景服務");
      backgroundExecute.stopBackgroundExecute();
      if (!_isScanning) {
        _startBeaconScanning(); // 確保掃描正常進行
      }
    }
  }

  Future<bool> _onWillPop() async {
    bool enableBackground = await _showBackgroundEnableDialog();
    if (enableBackground) {
      await backgroundExecute.initializeBackground(); // 啟動後台掃描
    } else {
      backgroundExecute.stopBackgroundExecute(); // 停止後台掃描
    }
    return true; // 允許退出應用
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

  // Show dialog to ask user if they want to enable background scanning
  Future<bool> _showBackgroundEnableDialog() async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("啟用後台掃描"),
          content: Text("是否希望下次退出app後繼續進行掃描？"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("否"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("是"),
            ),
          ],
        );
      },
    ) ??
        false;
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

  // Select from ExtraActions (Update or Delete)
  void onSelectExtraAction(context, action, beacon) {
    switch (action) {
      case ExtraAction.edit:
        Navigator.push<void>(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    EditPage(beacon: beacon, onSave: onEditBeacon),
                fullscreenDialog: true));
        break;

      case ExtraAction.delete:
        onDeleteBeacon(beacon);
        break;

      default:
        print('error!!');
    }
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
                  trailing: PopupMenuButton<ExtraAction>(
                    onSelected: (action) =>
                        onSelectExtraAction(context, action, dbBeacon),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: ExtraAction.edit, child: Icon(Icons.edit)),
                      PopupMenuItem(
                          value: ExtraAction.delete, child: Icon(Icons.delete))
                    ],
                  ),
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
                  trailing: PopupMenuButton<ExtraAction>(
                    onSelected: (action) =>
                        onSelectExtraAction(context, action, dbBeacon),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: ExtraAction.edit, child: Icon(Icons.edit)),
                      PopupMenuItem(
                          value: ExtraAction.delete, child: Icon(Icons.delete))
                    ],
                  ),
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
