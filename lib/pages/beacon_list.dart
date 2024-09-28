import 'package:flutter/material.dart';
import "package:test/pages/edit_beacon.dart";
import 'package:test/DB.dart';

// define ExtraActions (Update or Delete)
enum ExtraAction { edit, delete }

class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  List<Todo> _todosList = [Todo(name: 'Todo', done: 0)];

  // Read All Todos & rebuild UI
  void getList() async {
    // 未完成
  }

  // Add todo to DB
  void onAddTodo(String name, Todo todo) async {
    // 未完成
    getList();
  }

  // Press Add Button
  void onAdd() {
    Navigator.push<void>(
        context,
        MaterialPageRoute(
            builder: (context) => EditPage(todo: Todo(), onSave: onAddTodo)));
  }

  // Update Checkbox val of todo
  void onChangeCheckbox(val, todo) async {
    // 未完成
    getList();
  }

  // Update todo
  void onEditTodo(name, todo) async {
    // 未完成
    getList();
  }

  // Delete todo
  void onDeleteTodo(todo) async {
    // 未完成
    getList();
  }

  // Select from ExtraActions (Update or Delete)
  void onSelectExtraAction(context, action, todo) {
    switch (action) {
      case ExtraAction.edit:
        Navigator.push<void>(
            context,
            MaterialPageRoute(
                builder: (context) => EditPage(todo: todo, onSave: onEditTodo),
                fullscreenDialog: true));
        break;

      case ExtraAction.delete:
        onDeleteTodo(todo);

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
    return Scaffold(
      appBar: AppBar(title: const Text('TodoList')),
      body: Column(children: <Widget>[
        Expanded(
            child: ListView(
          children: _todosList.map((todo) {
            return ListTile(
              leading: Checkbox(
                value: todo.done == 1,
                onChanged: (value) => onChangeCheckbox(value, todo),
              ),
              title: Text(
                todo.name,
                style: TextStyle(
                    color: todo.done == 1 //
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.primary,
                    decoration: todo.done == 1 //
                        ? TextDecoration.lineThrough
                        : null),
              ),
              trailing: PopupMenuButton<ExtraAction>(
                onSelected: (action) =>
                    onSelectExtraAction(context, action, todo),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: ExtraAction.edit, child: Icon(Icons.edit)),
                  PopupMenuItem(
                      value: ExtraAction.delete, child: Icon(Icons.delete))
                ],
              ),
            );
          }).toList(),
        )),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
