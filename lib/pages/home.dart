import 'package:flutter/material.dart';
import "edit_beacon.dart";
import 'package:test/database.dart';
import 'package:test/scan.dart';

// 主頁面
class MainPage extends StatelessWidget {
  const MainPage({super.key});

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
              icon: const Icon(Icons.search),
              onPressed: () {},
            )
          ],
        ),
        body: TabBarView(
          children: <Widget>[
            BeaconList(),
            const Text("Others"),
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

// define ExtraActions (Update or Delete)
enum ExtraAction { edit, delete }

class BeaconList extends StatefulWidget {
  const BeaconList({super.key});

  @override
  _BeaconListState createState() => _BeaconListState();
}

class _BeaconListState extends State<BeaconList> {
  List<Beacon> _BeaconsList = [];
  List<Map<String, dynamic>> _scannedBeacons = []; // 存掃描到的已配對 Beacon
  final ScanService _scanService = ScanService(); // 初始化

  @override
  void initState() {
    super.initState();
    getList();
    _startBeaconScanning(); // 開掃beacon
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
    _scanService.startScanning();
    _scanService.beaconStream.listen((scannedBeacons) {
      setState(() {
        _scannedBeacons = scannedBeacons; // 更新掃描到的 Beacons
        print("掃描到的 Beacons: $_scannedBeacons");
      });
    });
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
                  // leading: Checkbox(
                  //   value: dbBeacon?.door == 1,
                  //   onChanged: (value) => onChangeCheckbox(value, dbBeacon),
                  // ),
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
                  // leading: Checkbox(
                  //   value: dbBeacon?.door == 1,
                  //   onChanged: (value) => onChangeCheckbox(value, dbBeacon),
                  // ),
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
