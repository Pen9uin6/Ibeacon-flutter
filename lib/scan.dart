import 'dart:async';
import 'dart:math';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:test/missing_event.dart';
import 'package:test/database.dart' as db;

class ScanService {
  late final StreamController<List<Map<String, dynamic>>> _beaconStreamController;
  final MissingEventService _missingEventService;
  StreamSubscription? _scanSubscription;

  ScanService(): _missingEventService = MissingEventService() {
    _beaconStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  }

  Stream<List<Map<String, dynamic>>> get beaconStream => _beaconStreamController.stream;

  //Map<String, List<double>> beaconRssiMap = {};
  Map<String, double> emaRssiMap = {};

  // 掃描已註冊beacon
  Future<void>scanRegisteredBeacons(List<db.Beacon> registeredBeacons) async {
    print("初始化掃描已註冊的 Beacon......");
    try {
      await flutterBeacon.initializeAndCheckScanning;
    } catch (e) {
      print("初始化失敗: $e");
      return;
    }

    // 設置掃描區域
    final regions = <Region>[Region(identifier: 'com.beacon')];
    await _scanSubscription?.cancel();

    // 開始掃描並監聽掃描結果
    _scanSubscription = flutterBeacon.ranging(regions).listen((result) {
      List<Map<String, dynamic>> scannedBeacons = [];
      for (var beacon in result.beacons) {
        final beaconId = beacon.proximityUUID;
        final rssi = beacon.rssi.toDouble() ?? 0;
        final distance = beacon.accuracy; // 使用 flutter_beacon 提供的距離模型

        if (distance != null && distance > 0){
          // 濾波器處理RSSI
          // double refinedRssi = exponentialMovingAverageFilter(beaconId, rssi); //EMA計算
          // final distance = calculateDistanceFromRssi(refinedRssi);

          // 檢查該 Beacon 是否在已註冊的 Beacon 中
          if (registeredBeacons.any((b) => b.uuid == beaconId)) {
            scannedBeacons.add({
              'uuid': beaconId,
              'distance': distance,
              'rssi': rssi,
            });
            _missingEventService.checkIfItemIsMissing({
              'uuid': beaconId,
              'distance': distance,
              'item': registeredBeacons.firstWhere((b) => b.uuid == beaconId).item,
            });
          }
        }
      }
      _beaconStreamController?.add(scannedBeacons);
    });
  }

  // 掃描全部beacon
  Future<void> startScanning() async {
    print("初始化掃描所有 Beacon...");
    try {
      await flutterBeacon.initializeAndCheckScanning;
    } catch (e) {
      print("初始化失敗: $e");
      return;
    }

    // 設置掃描區域
    final regions = <Region>[Region(identifier: 'com.beacon')];
    await _scanSubscription?.cancel();

    // 開始掃描並監聽掃描結果
    _scanSubscription = flutterBeacon.ranging(regions).listen((result) {
      List<Map<String, dynamic>> scannedBeacons = [];
      for (var beacon in result.beacons) {
        final beaconId = beacon.proximityUUID;
        final rssi = beacon.rssi.toDouble() ?? 0;
        final distance = beacon.accuracy; // 使用 flutter_beacon 提供的距離模型

        if (distance != null && distance > 0) {
          // addRssiValue(beaconId, rssi); // 將 RSSI 添加到對應 Beacon 的 RSSI 列表中

          // 濾波器處理RSSI
          // double refinedRssi = exponentialMovingAverageFilter(beaconId, rssi); //EMA計算
          // final distance = calculateDistanceFromRssi(refinedRssi);

          scannedBeacons.add({
            'uuid': beaconId,
            'distance': distance,
            'rssi': rssi,
          });
        }
      }
      _beaconStreamController?.add(scannedBeacons);
    });
  }

  // 停止掃描
  Future<void> stopScanning() async {
    await _scanSubscription?.cancel(); // 正確取消訂閱
    _scanSubscription = null; // 重置訂閱
    if (!_beaconStreamController.isClosed) {
      _beaconStreamController.close(); // 關閉流控制器
    }
  }

  // // 指數加權移動平均濾波器參數
  // double emaRssi = 0.0;
  // double alpha = 0.2; // 平滑因子 0~1
  //
  // double exponentialMovingAverageFilter(String beaconId, double rssi) {
  //   if (!emaRssiMap.containsKey(beaconId)) {
  //     // 如果沒有舊的值，直接使用當前的 RSSI 作為初始值
  //     emaRssiMap[beaconId] = rssi;
  //   } else {
  //     // 更新 EMA RSSI
  //     emaRssiMap[beaconId] =
  //         alpha * rssi + (1 - alpha) * emaRssiMap[beaconId]!;
  //   }
  //   return emaRssiMap[beaconId]!;
  // }
  //
  // // 根據 RSSI 計算距離
  // double calculateDistanceFromRssi(double rssi) {
  //   const int txPower = -59; // 發射功率
  //   double n = 3; // 環境損耗因子
  //   return pow(10, (txPower - rssi) / (10 * n)).toDouble();
  // }

  void dispose() {
    stopScanning();
    _beaconStreamController.close();
  }
}
