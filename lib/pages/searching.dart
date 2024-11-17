import 'package:flutter/material.dart';
import 'dart:async';

class SearchingPage extends StatefulWidget {
  final String itemName; // 物件名稱
  final String beaconId; // 目標 Beacon 的 UUID
  final List<Map<String, dynamic>> scannedBeacons; // 初始掃描結果
  final Stream<List<Map<String, dynamic>>> beaconStream; // Beacon 資料流

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

  double distance = 0.0; // 預設距離為 0.0
  bool hasSignal = false; // 是否有信號

  @override
  void initState() {
    super.initState();

    print("傳入的資料:");
    print("Item Name: ${widget.itemName}");
    print("Beacon ID: ${widget.beaconId}");
    print("Scanned Beacons: ${widget.scannedBeacons}");
    print("Beacon Stream: ${widget.beaconStream}");

    // 初始化時從掃描結果中找到目標 Beacon
    final initialBeacon = widget.scannedBeacons.firstWhere(
          (beacon) => beacon['uuid'] == widget.beaconId,
      orElse: () => <String, dynamic>{}, // 如果沒找到，返回空 Map
    );

    if (initialBeacon.isNotEmpty && initialBeacon['distance'] != null) {
      distance = (initialBeacon['distance'] as num).toDouble();
      hasSignal = true;
    } else {
      distance = 0.0; // 當初始沒有信號時，距離設為 0.0
      hasSignal = false;
    }

    // 監聽 Beacon 資料流更新
    _subscription = widget.beaconStream.listen((scannedBeacons) {
      final targetBeacon = scannedBeacons.firstWhere(
            (beacon) => beacon['uuid'] == widget.beaconId,
        orElse: () => <String, dynamic>{}, // 如果沒找到，返回空 Map
      );

      setState(() {
        if (targetBeacon.isNotEmpty && targetBeacon['distance'] != null) {
          distance = (targetBeacon['distance'] as num).toDouble();
          hasSignal = true;
        } else {
          distance = 0.0; // 當信號丟失時設為 0.0
          hasSignal = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel(); // 確保取消資料流監聽
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = hasSignal
        ? '距離: ${distance.toStringAsFixed(2)} 公尺' // 僅當有信號時顯示距離
        : '失去信號'; // 無信號時不顯示距離

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
              textAlign: TextAlign.center,
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
