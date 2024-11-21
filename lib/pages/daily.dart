import 'package:flutter/material.dart';

class DailyPage extends StatefulWidget {
  @override
  _DailyPageState createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  // 寫死的提醒數據
  final List<Map<String, dynamic>> reminders = [
    {"id": 1, "title": "早晨提醒", "time": "08:00 AM", "enabled": true},
    {"id": 2, "title": "午間提醒", "time": "12:00 PM", "enabled": false},
    {"id": 3, "title": "晚間提醒", "time": "6:00 PM", "enabled": true},
  ];

  // 開關狀態切換
  void _toggleReminder(int id, bool value) {
    setState(() {
      final reminder = reminders.firstWhere((r) => r['id'] == id);
      reminder['enabled'] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("日常提醒"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "提醒列表",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.notifications,
                          color: reminder['enabled']
                              ? Colors.teal
                              : Colors.grey),
                      title: Text(
                        reminder['title'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("時間: ${reminder['time']}"),
                      trailing: Switch(
                        value: reminder['enabled'],
                        onChanged: (value) {
                          _toggleReminder(reminder['id'], value);
                        },
                        activeColor: Colors.teal,
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
