import 'package:flutter/material.dart';
import "edit_beacon.dart";
import 'package:test/database.dart';
import 'package:test/background.dart';
import 'package:test/scan.dart';
import 'package:test/pages/searching.dart';
import 'package:test/requirement_state_controller.dart';
import 'package:get/get.dart';
import 'dart:async';

// 主頁面
class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final BackgroundExecute backgroundExecute = Get.put(BackgroundExecute());
  // final ScanService scanService = Get.put(ScanService(), permanent: true);
  late ScanService scanService;
  final RequirementStateController controller = Get.put(RequirementStateController());
  late TabController _tabController;
  StreamSubscription<List<Map<String, dynamic>>>? _scanSubscription;

  RxList<Beacon> _BeaconsList = <Beacon>[].obs;
  List<Map<String, dynamic>> _scannedBeacons = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    getList();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addObserver(this); // 監聽應用狀態

    if (!Get.isRegistered<ScanService>()) {
      scanService = Get.put(ScanService(_BeaconsList), permanent: true);
    } else {
      scanService = Get.find<ScanService>();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 移除狀態監聽
    _stopBeaconScanning(); // 停止掃描
    _scanSubscription?.cancel(); // 確保取消所有掃描訂閱

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
    _BeaconsList.assignAll(list); // 直接更新 RxList
    print("從資料庫獲取的 Beacons: $_BeaconsList");
    // setState(() {
    //   _BeaconsList = list;
    //   print("從資料庫獲取的 Beacons: $_BeaconsList");
    // });
  }

  // 開始掃描 Beacon
  void _startBeaconScanning() async {
    getList();
    bool success = await backgroundExecute.initializeBackground();

    setState(() {
      _isScanning = true;
    }); // 更新掃描按鈕的狀態
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '掃描已啟用並支援後台運行' : '掃描啟動失敗')),
    );
    _scanSubscription = scanService.beaconStream.listen((scannedBeacons) {
      setState(() {
        _scannedBeacons = scannedBeacons;
        print("掃描到的已註冊 Beacons: $_scannedBeacons");
      });
    });
    await scanService.scanRegisteredBeacons(_BeaconsList, getList); // 開始掃描
  }

  // 停止掃描 Beacon
  void _stopBeaconScanning() async {
    setState(() {
      _isScanning = false;
      _scannedBeacons.clear();
    }); // 更新掃描按鈕的狀態
    _scanSubscription?.cancel();
    _scanSubscription = null;
    await scanService.stopScanning();
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
      isMissing: 0,
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
          beacon: Beacon(id: '', uuid: '', item: '', door: 0, isMissing: 0),
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
          Beacon(id: '', uuid: '', item: '', door: 0, isMissing: 0), // 回傳一個空的 Beacon
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
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            indicatorColor: Colors.white,
            tabs: <Widget>[
              Tab(text: "裝置掃描"),
              Tab(text: "裝置管理"),
            ],
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                _isScanning ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                _isScanning ? _stopBeaconScanning() : _startBeaconScanning();
              },
            )
          ],
          backgroundColor: Colors.teal,
        ),
        body: TabBarView(
          children: <Widget>[
            ScanPage(
              _scannedBeacons,
              _BeaconsList,
              _isScanning,
              _findBeaconByUUID,
              getList,
              scanService,
            ),
            ManagePage(_BeaconsList, getList),
          ],
        ),
        drawer: Drawer(
          child: Column(
            verticalDirection: VerticalDirection.down,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: const Text("謝昕燁",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                accountEmail: null,
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    "謝",
                    style: TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.teal,
                ),
              ),
              // ListTile(
              //   leading: Icon(Icons.notifications, color: Colors.teal),
              //   title: const Text("日常提醒"),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => DailyPage()),
              //     );
              //   },
              // ),
              // ListTile(
              //   leading: Icon(Icons.group, color: Colors.teal),
              //   title: const Text("我的群組"),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => GroupPage()),
              //     );
              //   },
              // ),
              Spacer(),
              Divider(),
              ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text("登出"),
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
          backgroundColor: Colors.teal,
        ),
      ),
    );
  }
}

class ScanPage extends StatefulWidget {
  final List<Map<String, dynamic>> _scannedBeacons;
  final RxList<Beacon> _BeaconsList;
  final bool isScanning;
  final Beacon? Function(String uuid) _findBeaconByUUID;
  final VoidCallback refreshCallback;
  final ScanService scanService;

  ScanPage(
      this._scannedBeacons,
      this._BeaconsList,
      this.isScanning,
      this._findBeaconByUUID,
      this.refreshCallback,
      this.scanService,
      {super.key,}
      );

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late ScanService? scanService;

  @override
  void initState() {
    super.initState();
    scanService = widget.scanService;
  }


  @override
  Widget build(BuildContext context) {
    if (!widget.isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '啟動掃描以查看裝置資訊',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      );
    }

    return Obx(() {
      final doorBeacons = widget._scannedBeacons
          .where((b) =>
      widget._findBeaconByUUID(b['uuid'] as String)?.door == 1 &&
          widget._findBeaconByUUID(b['uuid'] as String)?.isMissing == 0)
          .toList();
      final itemBeacons = widget._scannedBeacons
          .where((b) =>
      widget._findBeaconByUUID(b['uuid'] as String)?.door == 0 &&
          widget._findBeaconByUUID(b['uuid'] as String)?.isMissing == 0)
          .toList();
      final missingBeacons = widget._BeaconsList
          .where((b) => b.door == 0 && b.isMissing == 1)
          .toList();

      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBeaconSection('Beacons - 門', doorBeacons, Colors.blue),
              const Divider(),
              _buildBeaconSection('Beacons - 物品', itemBeacons, Colors.green),
              const Divider(),
              _buildBeaconSection('Beacons - 遺失物品', missingBeacons, Colors.red),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBeaconSection(
      String title, List<dynamic> beacons, Color color) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8.0),
          ...beacons.map((beacon) {
            final Beacon? dbBeacon =
            beacon is Map? widget._findBeaconByUUID(beacon['uuid'])
                : beacon is Beacon? beacon: null;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: Icon(
                  title == 'Beacons - 門'
                      ? Icons.door_front_door
                      : title == 'Beacons - 物品'
                      ? Icons.local_offer
                      : Icons.help_outline,
                  color: title == 'Beacons - 遺失物品' ? Colors.red : color,
                ),
                title: Text(dbBeacon?.item ?? 'Unknown', style:const TextStyle(fontWeight: FontWeight.bold),),
                subtitle: title == 'Beacons - 遺失物品'
                    ? null // 移除遺失物品區域的距離顯示
                    : Text(
                  'Distance: ${beacon is Beacon ? 'N/A' : beacon['distance']?.toStringAsFixed(2) ?? 'N/A'} m',),
                trailing: title == 'Beacons - 遺失物品'
                    ? ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchingPage(
                          itemName: dbBeacon?.item ?? '',
                          beaconId: dbBeacon?.uuid ?? '',
                          scannedBeacons: widget._scannedBeacons,
                          beaconStream: widget.scanService.beaconStream,
                        ),
                      ),
                    );
                  },
                  child: const Text('尋找'),
                )
                    : null,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}


// define ExtraActions (Update or Delete)
enum ExtraAction { edit, delete, toggleDoor }

class ManagePage extends StatefulWidget {
  final List<Beacon> beaconsList;
  final VoidCallback refresh;

  ManagePage(
      this.beaconsList,
      this.refresh,
      {super.key});

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
          title: const Text("重新命名 Beacon"),
          content: TextField(
            controller: renameController,
            decoration: const InputDecoration(
              labelStyle: TextStyle(color: Colors.black),
              labelText: "輸入新的名稱",
              hintStyle: TextStyle(color: Colors.grey),
              hintText: "新的名稱",
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
                  beacon.item = renameController.text;
                  await BeaconDB.update(beacon);
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
    beacon.door = beacon.door == 1 ? 0 : 1;
    await BeaconDB.update(beacon);
    Future.delayed(Duration(milliseconds: 500), () {
      getList();
    });
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "已註冊的 Beacon",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: _BeaconsList.length,
                itemBuilder: (context, index) {
                  final beacon = _BeaconsList[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(
                        beacon.door == 1
                            ? Icons.door_front_door
                            : Icons.local_offer,
                        color: beacon.door == 1 ? Colors.blue : Colors.green,
                      ),
                      title: Text(beacon.item,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('UUID: ${beacon.uuid}'),
                      trailing: PopupMenuButton<ExtraAction>(
                        onSelected: (action) =>
                            onSelectExtraAction(context, action, beacon),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: ExtraAction.edit,
                            child: Text('重新命名'),
                          ),
                          const PopupMenuItem(
                            value: ExtraAction.toggleDoor,
                            child: Text('標記為"門"'),
                          ),
                          const PopupMenuItem(
                            value: ExtraAction.delete,
                            child: Text('刪除'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
