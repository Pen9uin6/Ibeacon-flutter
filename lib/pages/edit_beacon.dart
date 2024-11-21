import 'package:flutter/material.dart';
import 'package:test/database.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key, required this.beacon, required this.onSave});

  final Beacon beacon;
  final Function onSave;

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final itemController = TextEditingController();
  final uuidController = TextEditingController();
  bool door = false;

  void onSaveButtonPressed() async {
    if (itemController.text == '' || uuidController.text == '') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Center(
          child: Text(
            '物品名稱和 UUID 不得為空',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ));
    } else {
      // 檢查資料庫是否已有相同的 UUID 或物品名稱
      final existingBeaconByUUID =
          await BeaconDB.getBeaconByUUID(uuidController.text);
      final existingBeaconByName =
          await BeaconDB.getBeaconByName(itemController.text);

      if (existingBeaconByUUID != null || existingBeaconByName != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.orange,
          content: Center(
            child: Text(
              '相同的 UUID 或物品名稱已存在於資料庫中',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ));
      } else {
        widget.onSave(door ? 1 : 0, itemController.text, uuidController.text,
            widget.beacon);

        debugPrint(
            '${door.toString()}, ${itemController.text}, ${uuidController.text}, ${widget.beacon}');

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('儲存成功'),
              content: const Text('物品名稱和 UUID 已成功儲存。'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 關閉對話框
                    Navigator.of(context).pop(); // 關閉對話框
                  },
                  child: const Text('確認'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    itemController.text = widget.beacon.item;
    uuidController.text = widget.beacon.uuid;
    door = widget.beacon.door == 1;
  }

  @override
  void dispose() {
    itemController.dispose();
    uuidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加新 Beacon'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: onSaveButtonPressed,
            icon: const Icon(Icons.save),
          )
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '編輯 Beacon 資料',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: itemController,
                decoration: const InputDecoration(
                  labelText: '物品名稱',
                  labelStyle: TextStyle(color: Colors.black),
                  hintText: '請輸入物品名稱',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: uuidController,
                decoration: const InputDecoration(
                  labelText: 'iBeacon UUID',
                  labelStyle: TextStyle(color: Colors.black),
                  hintText: '請輸入 Beacon 的 UUID',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: door,
                    activeColor: Colors.teal,
                    onChanged: (bool? value) {
                      setState(() {
                        door = value ?? false;
                      });
                    },
                  ),
                  const Text(
                    '標記為 "門"',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
