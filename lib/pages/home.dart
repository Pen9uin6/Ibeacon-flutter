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
  ScanService? scanService;
  final RequirementStateController controller =
      Get.put(RequirementStateController());
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
    _BeaconsList.assignAll(list); // 直接更新 RxList
    print("從資料庫獲取的 Beacons: $_BeaconsList");
    // setState(() {
    //   _BeaconsList = list;
    //   print("從資料庫獲取的 Beacons: $_BeaconsList");
    // });
  }

  // 開始掃描 Beacon
  void _startBeaconScanning() async {
    bool success = await backgroundExecute.initializeBackground();
    scanService = Get.put(ScanService(_BeaconsList));
    setState(() {
      _isScanning = true;
    }); // 更新掃描按鈕的狀態
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '掃描已啟用並支援後台運行' : '掃描啟動失敗')),
    );
    _scanSubscription = scanService?.beaconStream.listen((scannedBeacons) {
      setState(() {
        _scannedBeacons = scannedBeacons;
        print("掃描到的已註冊 Beacons: $_scannedBeacons");
      });
    });
    await scanService?.scanRegisteredBeacons(_BeaconsList); // 開始掃描
  }

  // 停止掃描 Beacon
  void _stopBeaconScanning() async {
    setState(() {
      _isScanning = false;
      _scannedBeacons.clear();
    }); // 更新掃描按鈕的狀態
    _scanSubscription?.cancel(); // 取消掃描訂閱
    _scanSubscription = null;
    scanService?.stopScanning();
    scanService = null;
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
            tabs: <Widget>[
              Tab(text: "Scan"),
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
            ScanPage(
              _scannedBeacons,
              _BeaconsList,
              _isScanning,
              _findBeaconByUUID,
              getList,
            ),
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

class ScanPage extends StatefulWidget {
  final List<Map<String, dynamic>> _scannedBeacons;
  final RxList<Beacon> _BeaconsList;
  final bool isScanning;
  final Beacon? Function(String uuid) _findBeaconByUUID;
  final VoidCallback refreshCallback;
  final ScanService? scanService;

  ScanPage(
      this._scannedBeacons,
      this._BeaconsList,
      this.isScanning,
      this._findBeaconByUUID,
      this.refreshCallback,
      {this.scanService,super.key,}
      );

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late ScanService? scanService;

  @override
  void initState() {
    super.initState();
    scanService = widget.scanService ?? Get.put(ScanService(widget._BeaconsList));
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (!widget.isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '啟動掃描以檢視裝置資訊',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      );
    }

    // 當 scanService 為 null 時，避免出錯
    if (scanService == null) {
      return Center(
        child: const Text(
          '掃描服務尚未初始化，請啟動掃描',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }
      return Obx((){
        final homeBeacons = widget._scannedBeacons
            .where((b) => widget._findBeaconByUUID(b['uuid'])?.door == 1 && widget._findBeaconByUUID(b['uuid'])?.isMissing == 0)
            .toList();
        final nothomeBeacons = widget._scannedBeacons
            .where((b) => widget._findBeaconByUUID(b['uuid'])?.door == 0 && widget._findBeaconByUUID(b['uuid'])?.isMissing == 0)
            .toList();
        final missingBeacons = widget._BeaconsList
            .where((b) => b.door == 0  && b.isMissing == 1)
            .toList();

        return Scaffold(
          body: Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  children: [
                    //door區
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Door',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...homeBeacons.map((beacon) {
                      final Beacon? dbBeacon =
                      widget._findBeaconByUUID(beacon['uuid']);
                      return ListTile(
                        title: Text('${dbBeacon?.item}'),
                        subtitle: Text(
                            '距離: ${beacon['distance'].toStringAsFixed(2)} m'),
                      );
                    }).toList(),
                    //item區
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Item',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...nothomeBeacons.map((beacon) {
                      final Beacon? dbBeacon =
                      widget._findBeaconByUUID(beacon['uuid']);
                      return ListTile(
                        title: Text('${dbBeacon?.item}'),
                        subtitle: Text(
                            '距離: ${beacon['distance'].toStringAsFixed(2)} m'),
                      );
                    }).toList(),
                    //missing區
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Missing',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    ...missingBeacons.map((beacon) {
                      return ListTile(
                        title: Text(beacon.item),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchingPage(
                                  itemName: beacon.item,
                                  beaconId: beacon.uuid,
                                  scannedBeacons: widget._scannedBeacons,
                                  beaconStream: widget.scanService!.beaconStream,
                                ),
                              ),
                            );
                          },
                          child: const Text('尋物'),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      }
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
          title: const Text("Rename the Beacon"),
          content: TextField(
            controller: renameController,
            decoration: const InputDecoration(
              labelStyle: TextStyle(color: Colors.black),
              labelText: "Enter new name",
              hintStyle: TextStyle(color: Colors.grey),
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
