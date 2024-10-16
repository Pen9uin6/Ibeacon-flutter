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

  void onSaveButtonPressed() {
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
                  Navigator.of(context).pop(); // 返回主畫面
                },
                child: const Text('確認'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    itemController.text = widget.beacon.item;
    uuidController.text = widget.beacon.uuid ?? '';
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
        title: const Text('Add a Beacon'),
        actions: [
          IconButton(
            onPressed: onSaveButtonPressed,
            icon: const Icon(Icons.save),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: itemController,
                decoration: const InputDecoration(
                  labelText: 'item:',
                  hintText: 'Enter the name of item',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              TextFormField(
                controller: uuidController,
                decoration: const InputDecoration(
                  labelText: 'iBeacon UUID:',
                  hintText: 'Enter the UUID of iBeacon',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: door,
                    onChanged: (bool? value) {
                      setState(() {
                        door = value ?? false;
                      });
                    },
                  ),
                  const Text('Mark as Home'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
