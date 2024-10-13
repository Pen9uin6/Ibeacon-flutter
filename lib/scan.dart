import 'dart:async';
import 'dart:math';
import 'package:flutter_beacon/flutter_beacon.dart';

class ScanService {
  final StreamController<List<Map<String, dynamic>>> _beaconStreamController =
  StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get beaconStream =>
      _beaconStreamController.stream;

  List<double> rssiList = []; // 改為 List<double>

  // 初始化並開始掃描 Beacon
  Future<void> startScanning() async {
    print("初始化掃描...");
    try {
      await flutterBeacon.initializeAndCheckScanning;
    } catch (e) {
      print("初始化失敗: $e");
      return;
    }

    // 設置掃描區域
    final regions = <Region>[Region(identifier: 'com.beacon')];

    // 開始掃描並監聽掃描結果
    flutterBeacon.ranging(regions).listen((result) {
      List<Map<String, dynamic>> scannedBeacons = [];
      for (var beacon in result.beacons) {
        final beaconId = beacon.proximityUUID;
        final rssi = beacon.rssi?.toDouble() ?? 0; // 轉換為 double 類型

        if (rssi != 0) {
          addRssiValue(rssi); // 添加到 RSSI 列表中
          final distance = calculateDistanceFromSmoothedRssi();

          scannedBeacons.add({
            'uuid': beaconId,
            'distance': distance,
            'rssi': rssi,
          });
        }
      }
      _beaconStreamController.add(scannedBeacons); // 傳送掃描到的 Beacons
    });
  }

  // 增加 RSSI 值並計算距離
  void addRssiValue(double rssi) {
    if (rssi != 0) {
      rssiList.add(rssi);
      if (rssiList.length > 5) rssiList.removeAt(0); // 保持最近的 5 個 RSSI 值
    }
  }

  double getSmoothedRssi() {
    if (rssiList.isEmpty) return 0;
    List<double> sortedRssi = List<double>.from(rssiList)..sort(); // 使用 List<double>
    int discardCount = (sortedRssi.length * 0.1).round(); // 丟棄 10% 的數據以消除異常值
    List<double> filteredRssi =
    sortedRssi.sublist(discardCount, sortedRssi.length - discardCount);
    return filteredRssi.reduce((a, b) => a + b) / filteredRssi.length;
  }

  double calculateDistanceFromSmoothedRssi() {
    double smoothedRssi = getSmoothedRssi();
    const int txPower = -59; // 發射功率
    return pow(10, (txPower - smoothedRssi) / (10 * 4)).toDouble();
  }

  void dispose() {
    _beaconStreamController.close();
  }
}
