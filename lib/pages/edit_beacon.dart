import 'package:flutter/material.dart';
import 'package:test/db.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key, required this.beacon, required this.onSave});

  final Beacon beacon;
  final Function onSave;

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final itemController = TextEditingController();
  bool home = false;

  void onSaveButtonPressed() {
    if (itemController.text == '') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        content: Center(
          child: Text(
            '不得為空',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ));
    } else {
      widget.onSave(home ? 1 : 0, itemController.text, widget.beacon);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    itemController.text = widget.beacon.name;
    home = widget.beacon.home == 1;
  }

  @override
  void dispose() {
    itemController.dispose();
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
                  labelText: 'Beacon:',
                  hintText: 'Enter a beacon name',
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: home,
                    onChanged: (bool? value) {
                      setState(() {
                        home = value ?? false;
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
