import 'package:flutter/material.dart';
import 'package:test/DB.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key, required this.todo, required this.onSave});

  final Todo todo;
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
            '待辦事項不得為空',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ));
    } else {
      widget.onSave(itemController.text, widget.todo);
      Navigator.pop(context);
    }
  }

  @override
  void initState() {
    super.initState();
    itemController.text = widget.todo.name;
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
        title: const Text('add a todo'),
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
          child: TextField(
            controller: itemController,
            obscureText: false,
            decoration:
                const InputDecoration(labelText: 'Todo:', hintText: '買牛奶'),
          ),
        ),
      ),
    );
  }
}
