import 'package:flutter/material.dart';
import "edit_beacon.dart";
import 'package:test/db.dart';

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

  // Read All Todos & rebuild UI
  void getList() async {
    final list = await BeaconDB.getBeacons();
    setState(() {
      _BeaconsList = list;
    });
  }

  // Add Beacon to DB
  void onAddBeacon(int home, String name, Beacon beacon) async {
    final newBeacon = Beacon(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        home: home);
    await BeaconDB.addBeacon(newBeacon);
    getList();
  }

  // Press Add Button
  void onAdd() {
    Navigator.push<void>(
        context,
        MaterialPageRoute(
            builder: (context) =>
                EditPage(beacon: Beacon(), onSave: onAddBeacon)));
  }

  // Update Checkbox val of Beacon
  void onChangeCheckbox(val, beacon) async {
    final updateBeacon =
        Beacon(id: beacon.id, name: beacon.name, home: val ? 1 : 0);
    await BeaconDB.updateBeacon(updateBeacon);
    getList();
  }

  // Update Beacon
  void onEditBeacon(name, beacon) async {
    final updateBeacon = Beacon(
      id: beacon.id,
      name: name,
      home: beacon.home,
    );
    await BeaconDB.updateBeacon(updateBeacon);
    getList();
  }

  // Delete Beacon
  void onDeleteBeacon(beacon) async {
    await BeaconDB.deleteBeacon(beacon.id);
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

  // State control
  @override
  void initState() {
    super.initState();
    getList();
  }

  @override
  Widget build(BuildContext context) {
    final homeBeacons = _BeaconsList.where((b) => b.home == 1).toList();
    final nothomeBeacons = _BeaconsList.where((b) => b.home == 0).toList();

    return Scaffold(
      body: Column(children: <Widget>[
        Expanded(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Home',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...homeBeacons.map((beacon) {
                return ListTile(
                  leading: Checkbox(
                    value: beacon.home == 1,
                    onChanged: (value) => onChangeCheckbox(value, beacon),
                  ),
                  title: Text(
                    beacon.name,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        decoration: TextDecoration.lineThrough),
                  ),
                  trailing: PopupMenuButton<ExtraAction>(
                    onSelected: (action) =>
                        onSelectExtraAction(context, action, beacon),
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
              ...nothomeBeacons.map((beacon) {
                return ListTile(
                  leading: Checkbox(
                    value: beacon.home == 1,
                    onChanged: (value) => onChangeCheckbox(value, beacon),
                  ),
                  title: Text(
                    beacon.name,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  trailing: PopupMenuButton<ExtraAction>(
                    onSelected: (action) =>
                        onSelectExtraAction(context, action, beacon),
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
