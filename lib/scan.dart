import 'dart:async';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:test/missing_event.dart';
import 'package:test/database.dart' as db;
import 'package:get/get.dart';

class ScanService {
  late final StreamController<List<Map<String, dynamic>>> _beaconStreamController;
  final MissingEventService _missingEventService;
  StreamSubscription? _scanSubscription;
  bool startMissingChecking = false;

  static const double doorThresholdDistance = 1.0; // 門的距離閾值(m)

  ScanService(RxList<db.Beacon> sharedBeaconsList): _missingEventService = MissingEventService(sharedBeaconsList) {
    _beaconStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  }

  Stream<List<Map<String, dynamic>>> get beaconStream => _beaconStreamController.stream;

  // 掃描已註冊beacon
  Future<void>scanRegisteredBeacons(RxList<db.Beacon> registeredBeacons, void Function() getList) async {
    print("初始化掃描已註冊的 Beacon......");
    try {
      await flutterBeacon.initializeAndCheckScanning;
    } catch (e) {
      print("初始化失敗: $e");
      return;
    }

    int DistanceCheckingCounter = 0; // 距離條件計數器(防意外達成條件)
    int UndetectCounter = 0; // 失去信號計數器(房短時間失去信號)
    await _missingEventService.resetAllBeaconsMissingStatus(registeredBeacons);  // 重置所有已註冊 Beacon 的狀態
    _missingEventService.updateRegisteredBeacons(registeredBeacons);     // 更新已註冊的 Beacon 列表

    // 設置掃描區域
    final regions = <Region>[Region(identifier: 'com.beacon')];

    // 開始掃描並監聽掃描結果
    _scanSubscription = flutterBeacon.ranging(regions).listen((result) {
      getList();
      _missingEventService.updateRegisteredBeacons(registeredBeacons);
      List<Map<String, dynamic>> scannedBeacons = [];
      bool doorBeaconDetected = false;

      for (var beacon in result.beacons) {
        final beaconId = beacon.proximityUUID;
        final rssi = beacon.rssi.toDouble();
        final distance = beacon.accuracy;

        if (distance > 0){
          // 檢查該 Beacon 是否在已註冊的 Beacon 中
          final registeredBeacon = registeredBeacons.firstWhereOrNull((b) => b.uuid == beaconId);
          if (registeredBeacon != null) {
            scannedBeacons.add({
              'uuid': beaconId,
              'distance': distance,
              'rssi': rssi,
            });

            // 判斷是否為 "door beacon" 並且距離小於閾值
            if (registeredBeacon.door == 1){
              doorBeaconDetected = true;
              if (distance < doorThresholdDistance && !startMissingChecking) {
                DistanceCheckingCounter++;
                print("與door距離小於閥值, 當前次數:${DistanceCheckingCounter}");
                if(DistanceCheckingCounter > 3){ // 距離小於閥值超過三次啟動檢查
                  print("使用者即將出門，啟動遺失檢測");
                  startMissingChecking = true;
                }
              }
            }
          }
        }
      }
      // 如果沒有發現 door beacon，則啟動遺失檢測（失去信號）
      if (!doorBeaconDetected && !startMissingChecking) {
        UndetectCounter++;
        print("door信號丟失, 當前次數:${UndetectCounter}");
        if(UndetectCounter > 3){ // 失去信號超過三次啟動檢查
          print("未檢測到門的信號，啟動遺失檢測");
          doorBeaconDetected = false;
          startMissingChecking = true;
        }
      }
      // 發送掃描到的 Beacon 資料
      _beaconStreamController.add(scannedBeacons);
      // 如果啟動了遺失檢測，進行檢測
      if (startMissingChecking) {
        _missingEventService.checkIfItemIsMissing(scannedBeacons);
      }
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
        final distance = beacon.accuracy;

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
    startMissingChecking = false;
  }

  void dispose() {
    stopScanning();
    _beaconStreamController.close();
  }
}
