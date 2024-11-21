import 'package:flutter/material.dart';
import 'members_page.dart';

class GroupPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("我的群組"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "群組列表",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            _buildGroupCard(context, "家裡", "成員：老爸、老媽、老妹...", Colors.blue),
            _buildGroupCard(context, "朋友", "成員：小明、小紅、小華...", Colors.green),
            _buildGroupCard(context, "公司", "成員：主管、同事A、同事B...", Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(
      BuildContext context, String title, String subtitle, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(Icons.group, color: Colors.white),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MembersPage(groupName: title),
            ),
          );
        },
      ),
    );
  }
}
