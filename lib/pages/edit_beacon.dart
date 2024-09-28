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
      widget.onSave(itemController.text, widget.beacon);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    itemController.text = widget.beacon.name;
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
        title: const Text('add a beacon'),
        actions: [
          IconButton(
            onPressed: onSaveButtonPressed,
            icon: const Icon(Icons.save),
          )
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: TextFormField(
            controller: itemController,
            obscureText: false,
            decoration: const InputDecoration(
                labelText: 'Beacon:', hintText: 'Enter a beacon name'),
          ),
        ),
      ),
    );
  }
}
