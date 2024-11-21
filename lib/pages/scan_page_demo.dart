import 'package:flutter/material.dart';

class ScanPageDemo extends StatelessWidget {
  final String memberName;

  ScanPageDemo({required this.memberName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("掃描結果 - $memberName"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "掃描結果",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            _buildScanResultCard("錢包", "距離: 1.2 m"),
            _buildScanResultCard("家門鑰匙", "距離: 2.5 m"),
            _buildScanResultCard("手機", "距離: 3.0 m"),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResultCard(String beaconName, String distance) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.bluetooth, color: Colors.white),
        ),
        title: Text(beaconName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(distance),
      ),
    );
  }
}
