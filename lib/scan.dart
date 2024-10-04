import 'dart:async';
import 'dart:math';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:test/database.dart' as db;

class ScanService {
  final StreamController<Map<String, dynamic>> _beaconStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get beaconStream => _beaconStreamController.stream;
  List<int> rssiList = [];
  List<db.Beacon> registeredBeacons = [];

  Future<void> startScanning() async {
    print("初始化掃描...");
    await flutterBeacon.initializeAndCheckScanning;
    final regions = <Region>[Region(identifier: 'com.beacon')];

    registeredBeacons = await db.BeaconDB.getBeacons();
    print("註冊 Beacons: $registeredBeacons");

    flutterBeacon.ranging(regions).listen((result) async {
      print("掃描結果: $result");
      for (var beacon in result.beacons) {
        final beaconId = beacon.proximityUUID;
        final rssi = beacon.rssi ?? 0;

        addRssiValue(rssi);
        final distance = calculateDistanceFromSmoothedRssi();

        final db.Beacon? registeredBeacon = registeredBeacons.firstWhere(
              (regBeacon) => regBeacon.uuid == beaconId,
          orElse: () => db.Beacon(),
        );

        if (registeredBeacon != null && registeredBeacon.uuid != null) {
          print("找到已註冊的 Beacon: ${registeredBeacon.item}, 距離: $distance");
          _beaconStreamController.add({
            'itemName': registeredBeacon.item,
            'uuid': beaconId,
            'distance': distance,
            'home': registeredBeacon.home,
          });
        }
      }
    });
  }

  void addRssiValue(int rssi) {
    if (rssi != 0) {
      rssiList.add(rssi);
      if (rssiList.length > 5) rssiList.removeAt(0);
    }
  }

  double getSmoothedRssi() {
    if (rssiList.isEmpty) return 0;
    List<int> sortedRssi = List.from(rssiList)..sort();
    int discardCount = (sortedRssi.length * 0.1).round();
    List<int> filteredRssi = sortedRssi.sublist(discardCount, sortedRssi.length - discardCount);
    return filteredRssi.reduce((a, b) => a + b) / filteredRssi.length;
  }

  double calculateDistanceFromSmoothedRssi() {
    double smoothedRssi = getSmoothedRssi();
    const int txPower = -59;
    return pow(10, (txPower - smoothedRssi) / (10 * 4)).toDouble();
  }

  void dispose() {
    _beaconStreamController.close();
  }
}
