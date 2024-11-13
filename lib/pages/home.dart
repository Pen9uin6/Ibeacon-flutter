import 'package:flutter/material.dart';
import "edit_beacon.dart";
import 'package:test/database.dart';
import 'package:test/background.dart';
import 'package:test/scan.dart';
import 'package:test/requirement_state_controller.dart';
import 'package:get/get.dart';
import 'dart:async';

// 主頁面
class MainPage extends StatefulWidget {
  MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final BackgroundExecute backgroundExecute = Get.put(BackgroundExecute());
  // final ScanService scanService = Get.put(ScanService(), permanent: true);
  ScanService? scanService;
  final RequirementStateController controller =
      Get.put(RequirementStateController());
  late TabController _tabController;
  StreamSubscription<List<Map<String, dynamic>>>? _scanSubscription;

  List<Beacon> _BeaconsList = [];
  List<Map<String, dynamic>> _scannedBeacons = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    getList();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addObserver(this); // 監聽應用狀態
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除狀態監聽
    _stopBeaconScanning(); // 停止掃描
    super.dispose();
  }

  // 監聽 Tab 切換
  void _handleTabChange() {
    if (_tabController.index == 0) {
      getList(); // 當切換到 Home 時重新加載 Beacon 列表
    }
  }

  // 讀取所有 Beacons 並重建 UI
  void getList() async {
    final list = await BeaconDB.getBeacons();
    setState(() {
      _BeaconsList = list;
      print("從資料庫獲取的 Beacons: $_BeaconsList");
    });
  }

  // 開始掃描 Beacon
  void _startBeaconScanning() async {
    bool success = await backgroundExecute.initializeBackground();
    setState(() {
      _isScanning = true;
      scanService = ScanService();
    }); // 更新掃描按鈕的狀態
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '掃描已啟用並支援後台運行' : '掃描啟動失敗')),
    );
    await scanService?.scanRegisteredBeacons(_BeaconsList); // 開始掃描
    _scanSubscription = scanService?.beaconStream.listen((scannedBeacons) {
      setState(() {
        _scannedBeacons = scannedBeacons;
        print("掃描到的已註冊 Beacons: $_scannedBeacons");
      });
    });
  }

  // 停止掃描 Beacon
  void _stopBeaconScanning() async {
    setState(() {
      _isScanning = false;
      _scannedBeacons.clear();
    }); // 更新掃描按鈕的狀態
    _scanSubscription?.cancel(); // 取消掃描訂閱
    scanService?.dispose();
    await backgroundExecute.stopBackgroundExecute();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('掃描已停止')),
    );
  }

  // 添加 Beacon 到資料庫
  void onAddBeacon(int door, String item, String uuid, Beacon beacon) async {
    final newBeacon = Beacon(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      uuid: uuid,
      item: item,
      door: door,
    );
    await BeaconDB.insert(newBeacon);
    getList();
  }

// 按下添加按鈕
  void onAdd() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPage(
          beacon: Beacon(id: '', uuid: '', item: '', door: 0),
          onSave: onAddBeacon,
        ),
      ),
    );
    getList();
  }

  // 根據 UUID 搜尋 Beacon 並更新距離
  Beacon? _findBeaconByUUID(String uuid) {
    return _BeaconsList.firstWhere(
      (beacon) => beacon.uuid == uuid,
      orElse: () =>
          Beacon(id: '', uuid: '', item: '', door: 0), // 回傳一個空的 Beacon
    );
  }

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
              icon: Icon(
                  _isScanning ? Icons.stop : Icons.play_arrow), // 啟用後台掃描的按鈕
              onPressed: () {
                _isScanning ? _stopBeaconScanning() : _startBeaconScanning();
              },
            )
          ],
        ),
        body: TabBarView(
          children: <Widget>[
            HomePage(_scannedBeacons, _findBeaconByUUID),
            ManagePage(_BeaconsList, getList),
          ],
        ),
        drawer: Drawer(
          //  child: ListView(
          //   padding: EdgeInsets.zero,

          //   children: <Widget>[
          //     const DrawerHeader(
          //       decoration: BoxDecoration(
          //         color: Colors.blueGrey,
          //       ),
          //       child: Text("User Name"),
          //   ]
          child: Column(
            verticalDirection: VerticalDirection.down,
            children: <Widget>[
              ListTile(
                title: const Text("User Name"),
                subtitle: const Text("123123"),
                tileColor: Colors.blueGrey,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
                subtitleTextStyle: TextStyle(
                  color: const Color.fromARGB(255, 228, 217, 217),
                  fontSize: 16.0,
                ),
                minTileHeight: 60.0,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                titleAlignment: ListTileTitleAlignment.center,
              ),
              // const DrawerHeader(
              //   decoration: BoxDecoration(
              //     color: Colors.blueGrey,
              //   ),
              //   child: Text("User Name"),
              // ),
              // UserAccountsDrawerHeader(
              //   accountName: const Text("User Name"),
              //   accountEmail: null,
              //   currentAccountPicture: null,
              //   // currentAccountPicture: CircleAvatar(
              //   //   backgroundColor: Colors.white,
              //   //   child: Text(
              //   //     "U",
              //   //     style: TextStyle(fontSize: 40.0),
              //   //   ),
              //   // ),
              //   margin: const EdgeInsets.only(bottom: 0.0),
              //   decoration: BoxDecoration(
              //     color: Colors.blueGrey,
              //   ),
              // ),
              ListTile(
                title: const Text("Sign out"),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/", (route) => false);
                },
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                title: const Text("Home"),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/", (route) => false);
                },
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: onAdd,
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> _scannedBeacons;
  final Beacon? Function(String uuid) _findBeaconByUUID;

  HomePage(this._scannedBeacons, this._findBeaconByUUID, {super.key});

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
                  subtitle:
                      Text('距離: ${beacon['distance'].toStringAsFixed(2)} m'),
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
                  subtitle:
                      Text('距離: ${beacon['distance'].toStringAsFixed(2)} m'),
                );
              }).toList(),
            ],
          ),
        ),
      ]),
    );
  }
}

// define ExtraActions (Update or Delete)
enum ExtraAction { edit, delete, toggleDoor }

class ManagePage extends StatefulWidget {
  final List<Beacon> beaconsList;
  final VoidCallback refresh;

  ManagePage(this.beaconsList, this.refresh, {super.key});

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

  @override
  void didUpdateWidget(covariant ManagePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.beaconsList != oldWidget.beaconsList) {
      setState(() {
        _BeaconsList = widget.beaconsList;
      });
    }
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
                  Beacon updatedBeacon =
                      beacon.copyWith(item: renameController.text);
                  await BeaconDB.update(updatedBeacon);
                  getList();
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

  // is/isnt the door one
  void _toggleDoorStatus(Beacon beacon) async {
    Beacon updatedBeacon = beacon.copyWith(door: beacon.door == 1 ? 0 : 1);
    await BeaconDB.update(updatedBeacon);
    getList();
  }

  // Delete Beacon
  void onDeleteBeacon(beacon) async {
    await BeaconDB.delete(beacon.id);
    getList();
  }

  void onSelectExtraAction(
      BuildContext context, ExtraAction action, Beacon beacon) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Manage Registered Beacons',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                onSelected: (action) =>
                    onSelectExtraAction(context, action, beacon),
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
    );
  }
}
