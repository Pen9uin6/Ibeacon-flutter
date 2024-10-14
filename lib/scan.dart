import 'dart:async';
import 'dart:math';
import 'package:flutter_beacon/flutter_beacon.dart';

class ScanService {
  final StreamController<List<Map<String, dynamic>>> _beaconStreamController =
  StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get beaconStream =>
      _beaconStreamController.stream;

  Map<String, List<double>> beaconRssiMap = {};

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
        final rssi = beacon.rssi?.toDouble() ?? 0;

        if (rssi != 0) {
          addRssiValue(beaconId, rssi); // 將 RSSI 添加到對應 Beacon 的 RSSI 列表中

          // 濾波器處理RSSI
          double refinedRssi = Average(beaconId); // 計算平均值
          final distance = calculateDistanceFromRssi(refinedRssi);

          scannedBeacons.add({
            'uuid': beaconId,
            'distance': distance,
            'rssi': refinedRssi,
          });
        }
      }
      _beaconStreamController.add(scannedBeacons);
    });
  }

  // 增加 RSSI 值
  void addRssiValue(String beaconId, double rssi) {
    if (rssi != 0) {
      if (!beaconRssiMap.containsKey(beaconId)) {
        beaconRssiMap[beaconId] = [];
      }
      beaconRssiMap[beaconId]!.add(rssi);
      if (beaconRssiMap[beaconId]!.length > 10) {
        beaconRssiMap[beaconId]!.removeAt(0); // 存最近10個RSSI
      }
    }
  }

  // 平均 RSSI
  double Average(String beaconId) {
    if (beaconRssiMap[beaconId] == null || beaconRssiMap[beaconId]!.isEmpty) {
      return 0;
    }
    List<double> rssiList = beaconRssiMap[beaconId]!;
    return rssiList.reduce((a, b) => a + b) / rssiList.length;
  }

  // 卡爾曼濾波器參數
  double _kalmanRssi = 0;
  double _kalmanP = 1;
  double _kalmanR = 0.05; // 噪聲協方差 (越大表系統對變化越靈敏 0.01 ~ 1)
  double _kalmanQ = 0.05; // 測量協方差 (越小代表對測量的信用度越高 0.1 ~ 10)

  // 卡爾曼濾波器
  double KalmanFilter(double rssi) {
    _kalmanP = _kalmanP + _kalmanQ;
    double K = _kalmanP / (_kalmanP + _kalmanR);
    _kalmanRssi = _kalmanRssi + K * (rssi - _kalmanRssi);
    _kalmanP = (1 - K) * _kalmanP;
    return _kalmanRssi;
  }

  // 指數加權移動平均濾波器參數
  double emaRssi = 0.0;
  double alpha = 0.2; // 平滑因子 0~1

  // 指數加權移動平均濾波器
  double exponentialMovingAverageFilter(double rssi) {
    emaRssi = alpha * rssi + (1 - alpha) * emaRssi;
    return emaRssi;
  }

  // 根據 RSSI 計算距離
  double calculateDistanceFromRssi(double rssi) {
    const int txPower = -59; // 發射功率
    double n = 3.5; // 環境損耗因子
    return pow(10, (txPower - rssi) / (10 * n)).toDouble();
  }

  void dispose() {
    _beaconStreamController.close();
  }
}
