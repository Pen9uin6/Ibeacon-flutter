import 'package:flutter/material.dart';
import 'dart:async';

class SearchingPage extends StatefulWidget {
  final String itemName;
  final String beaconId;
  final List<Map<String, dynamic>> scannedBeacons;
  final Stream<List<Map<String, dynamic>>> beaconStream;

  const SearchingPage({
    super.key,
    required this.itemName,
    required this.beaconId,
    required this.scannedBeacons,
    required this.beaconStream,
  });

  @override
  _SearchingPageState createState() => _SearchingPageState();
}

class _SearchingPageState extends State<SearchingPage> {
  late StreamSubscription<List<Map<String, dynamic>>> _subscription;

  double? distance;
  bool hasSignal = false;

  @override
  void initState() {
    super.initState();

    // 初始化時從掃描結果中找到目標 Beacon
    final initialBeacon = widget.scannedBeacons.firstWhere(
          (beacon) => beacon['uuid'] == widget.beaconId,
      orElse: () => <String, dynamic>{},
    );

    if (initialBeacon.isNotEmpty && initialBeacon['distance'] != null) {
      distance = initialBeacon['distance'] is num
          ? (initialBeacon['distance'] as num).toDouble()
          : null;
      hasSignal = distance != null;
    }

    // 監聽 Beacon 資料流更新
    _subscription = widget.beaconStream.listen((scannedBeacons) {
      final targetBeacon = scannedBeacons.firstWhere(
            (beacon) => beacon['uuid'] == widget.beaconId,
        orElse: () => <String, dynamic>{},
      );

      if (targetBeacon.isNotEmpty && targetBeacon['distance'] != null) {
        setState(() {
          distance = (targetBeacon['distance'] as num).toDouble();
          hasSignal = true;
        });
      } else {
        setState(() {
          distance = null;
          hasSignal = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = hasSignal && distance != null
        ? '距離: ${distance!.toStringAsFixed(2)} 公尺'
        : '失去信號，請嘗試靠近物件或檢查電池狀態';

    return Scaffold(
      appBar: AppBar(
        title: Text('搜尋 ${widget.itemName}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSignal ? Icons.location_searching : Icons.error_outline,
              size: 100,
              color: hasSignal ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24,
                color: hasSignal ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '物件名稱: ${widget.itemName}\nUUID: ${widget.beaconId}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
