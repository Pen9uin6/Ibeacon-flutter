import 'dart:async';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:test/missing_event.dart';
import 'package:test/database.dart' as db;
import 'package:get/get.dart';

class ScanService {
  late final StreamController<List<Map<String, dynamic>>> _beaconStreamController;
  final MissingEventService _missingEventService;
  final Map<String, double> lastDistances = {}; // 記錄所有 Beacon 的最後距離
  final Map<String, int> _signalLossCounters = {}; // 信號丟失計數器
  static const int maxSignalLossCount = 3; // 最大信號丟失次數
  StreamSubscription? _scanSubscription;
  bool startMissingChecking = false;

  static const double doorThresholdDistance = 1.0; // 門的距離閾值(m)

  ScanService(RxList<db.Beacon> sharedBeaconsList)
      : _missingEventService = MissingEventService(sharedBeaconsList) {
    _beaconStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  }

  Stream<List<Map<String, dynamic>>> get beaconStream => _beaconStreamController.stream;

  Future<void> scanRegisteredBeacons(
      RxList<db.Beacon> registeredBeacons, void Function() getList) async {
    print("初始化掃描已註冊的 Beacon...");
    try {
      await flutterBeacon.initializeAndCheckScanning;
    } catch (e) {
      print("初始化失敗: $e");
      return;
    }

    int distanceCheckingCounter = 0; // 距離條件計數器(防意外達成條件)
    int undetectCounter = 0; // 失去信號計數器(房短時間失去信號)
    await _missingEventService.resetAllBeaconsMissingStatus(registeredBeacons);
    _missingEventService.updateRegisteredBeacons(registeredBeacons);

    final regions = <Region>[Region(identifier: 'com.beacon')];

    _scanSubscription = flutterBeacon.ranging(regions).listen((result) {
      getList();
      _missingEventService.updateRegisteredBeacons(registeredBeacons);
      List<Map<String, dynamic>> scannedBeacons = [];
      bool anyDoorWithinThreshold = false; // 是否有任一門距離小於閥值
      bool allDoorsLostSignal = true; // 是否所有門信號丟失

      for (var beacon in result.beacons) {
        final beaconId = beacon.proximityUUID;
        final distance = beacon.accuracy;

        if (distance > 0) {
          final registeredBeacon = registeredBeacons.firstWhereOrNull((b) => b.uuid == beaconId);
          if (registeredBeacon != null) {
            scannedBeacons.add({'uuid': beaconId, 'distance': distance});

            // 更新最後距離
            lastDistances[beaconId] = distance;
            _signalLossCounters[beaconId] = 0; // 重置丟失計數

            if (registeredBeacon.door == 1) {
              allDoorsLostSignal = false; // 至少有一個門信號存在
              if (distance < doorThresholdDistance) {
                anyDoorWithinThreshold = true; // 有一個門距離小於閥值
              }
            }
          }
        }
      }

      // 處理信號丟失的 Beacons
      for (var beacon in registeredBeacons) {
        if (!scannedBeacons.any((b) => b['uuid'] == beacon.uuid)) {
          _signalLossCounters[beacon.uuid] = (_signalLossCounters[beacon.uuid] ?? 0) + 1;
          if (_signalLossCounters[beacon.uuid]! < maxSignalLossCount) {
            // 短暫信號丟失，使用最後距離
            scannedBeacons.add({
              'uuid': beacon.uuid,
              'distance': lastDistances[beacon.uuid] ?? 0.0,
            });
            print("Beacon ${beacon.uuid} 短暫信號丟失，最後距離: ${lastDistances[beacon.uuid] ?? 'N/A'}");
          }
        }
      }

      // 如果所有門信號丟失或任一門距離小於閥值，啟動遺失檢測
      if (allDoorsLostSignal) {
        undetectCounter++;
        print("失去全部門訊號 次數:${undetectCounter}");
      }
      if (anyDoorWithinThreshold) {
        distanceCheckingCounter++;
        print("任一門距離小於閥值 次數:${distanceCheckingCounter}");
      }
      if (distanceCheckingCounter > 3 || undetectCounter > 3){
        print("啟動遺失檢測");
        startMissingChecking = true;
        _missingEventService.checkIfItemIsMissing(scannedBeacons);
      }
      _beaconStreamController.add(scannedBeacons);
    });
  }

  Future<void> stopScanning() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    startMissingChecking = false;
    lastDistances.clear();
    _signalLossCounters.clear();
  }

  void dispose() {
    stopScanning();
    _beaconStreamController.close();
  }
}
