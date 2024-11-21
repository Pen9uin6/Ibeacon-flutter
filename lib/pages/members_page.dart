import 'package:flutter/material.dart';
import 'scan_page_demo.dart';

class MembersPage extends StatelessWidget {
  final String groupName;

  MembersPage({required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$groupName 成員"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "成員列表",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            _buildMemberCard(context, "老爸", Icons.man),
            _buildMemberCard(context, "老媽", Icons.woman),
            _buildMemberCard(context, "老妹", Icons.child_care),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, String name, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: Icon(Icons.arrow_forward, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanPageDemo(memberName: name),
            ),
          );
        },
      ),
    );
  }
}
