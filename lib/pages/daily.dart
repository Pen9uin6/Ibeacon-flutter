// daily.dart
import 'package:flutter/material.dart';

class DailyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("日常提醒設置"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "每日提醒",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text("請設定您想要的日常提醒："),
            SizedBox(height: 16.0),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text("早晨提醒"),
              subtitle: Text("每天早上 8:00 提醒攜帶重要物品"),
              trailing: Switch(value: true, onChanged: (bool value) {}),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text("午餐提醒"),
              subtitle: Text("每天中午 12:00 提醒攜帶餐具"),
              trailing: Switch(value: false, onChanged: (bool value) {}),
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text("晚間提醒"),
              subtitle: Text("每天晚上 7:00 提醒準備明天的物品"),
              trailing: Switch(value: true, onChanged: (bool value) {}),
            ),
          ],
        ),
      ),
    );
  }
}
