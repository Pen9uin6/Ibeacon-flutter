import 'dart:async';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:test/missing_event.dart';
import 'package:test/database.dart' as db;
import 'package:get/get.dart';

class ScanService {
  late final StreamController<List<Map<String, dynamic>>> _beaconStreamController;
  final MissingEventService _missingEventService;
  StreamSubscription? _scanSubscription;

  ScanService(RxList<db.Beacon> sharedBeaconsList): _missingEventService = MissingEventService(sharedBeaconsList) {
    _beaconStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  }

  Stream<List<Map<String, dynamic>>> get beaconStream => _beaconStreamController.stream;

  // 掃描已註冊beacon
  Future<void>scanRegisteredBeacons(RxList<db.Beacon> registeredBeacons) async {
    print("初始化掃描已註冊的 Beacon......");
    try {
      await flutterBeacon.initializeAndCheckScanning;
    } catch (e) {
      print("初始化失敗: $e");
      return;
    }

    // 更新已註冊的 Beacon 列表
    _missingEventService.updateRegisteredBeacons(registeredBeacons);

    // 設置掃描區域
    final regions = <Region>[Region(identifier: 'com.beacon')];

    // 開始掃描並監聽掃描結果
    _scanSubscription = flutterBeacon.ranging(regions).listen((result) {
      List<Map<String, dynamic>> scannedBeacons = [];

      for (var beacon in result.beacons) {
        final beaconId = beacon.proximityUUID;
        final rssi = beacon.rssi.toDouble();
        final distance = beacon.accuracy; // 使用 flutter_beacon 提供的距離模型

        if (distance > 0){
          // 檢查該 Beacon 是否在已註冊的 Beacon 中
          if (registeredBeacons.any((b) => b.uuid == beaconId)) {
            scannedBeacons.add({
              'uuid': beaconId,
              'distance': distance,
              'rssi': rssi,
            });;
          }
        }
      }
      _beaconStreamController.add(scannedBeacons);
      _missingEventService.checkIfItemIsMissing(scannedBeacons);
    });
  }

  // 掃描全部beacon
  Future<void> startAllscanning() async {
    print("初始化掃描所有 Beacon...");
    try {
      await flutterBeacon.initializeAndCheckScanning;
    } catch (e) {
      print("初始化失敗: $e");
      return;
    }

    // 設置掃描區域
    final regions = <Region>[Region(identifier: 'com.beacon')];

    // 開始掃描並監聽掃描結果
    _scanSubscription = flutterBeacon.ranging(regions).listen((result) {
      List<Map<String, dynamic>> scannedBeacons = [];
      for (var beacon in result.beacons) {
        final beaconId = beacon.proximityUUID;
        final rssi = beacon.rssi.toDouble();
        final distance = beacon.accuracy; // 使用 flutter_beacon 提供的距離模型

        if (distance > 0) {
          scannedBeacons.add({
            'uuid': beaconId,
            'distance': distance,
            'rssi': rssi,
          });
        }
      }
      _beaconStreamController.add(scannedBeacons);
    });
  }

  // 停止掃描
  Future<void> stopScanning() async {
    await _scanSubscription?.cancel(); // 正確取消訂閱
    _scanSubscription = null; // 重置訂閱
  }

  void dispose() {
    stopScanning();
    _beaconStreamController.close();
  }
}
