import 'package:flutter_background/flutter_background.dart';
import 'package:test/scan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundExecute {
  final ScanService _scanService = ScanService();

  //初始化並開始後台掃描
  Future<bool> initializeBackground() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "應用後台運行中",
      notificationText: "應用正在後台運行以保持功能可用",
      notificationImportance: AndroidNotificationImportance.high,
      notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'),
    );

    //初始化後臺執行環境
    bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
    if (success) {
      print("app於後臺繼續執行");
      await FlutterBackground.enableBackgroundExecution();
      await _scanService.startScanning(); // 開掃

      // 監聽掃描到的 Beacon
      _scanService.beaconStream.listen((scannedBeacons) {
        for (var beacon in scannedBeacons) {
          print("後台掃描到的 Beacon: UUID=${beacon['uuid']}, 距離=${beacon['distance']} 米, RSSI=${beacon['rssi']}");
        }
      });

      // 記錄後台掃描狀態
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_background_scanning', true);
    }
    else{
      print("後臺啟動失敗");
    }
    return success;
  }

  Future<void> stopBackgroundScanning() async {
    try {
      if (FlutterBackground.isBackgroundExecutionEnabled) {
        bool disabled = await FlutterBackground.disableBackgroundExecution();
        if (disabled) {
          print("後台掃描已成功停止");
        } else {
          print("後台掃描停止失敗");
        }
      }

      // 停止掃描
      _scanService.dispose();
      print("掃描已停止");

      // 更新後台掃描狀態
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_background_scanning', false);
    } catch (e) {
      print("停止背景掃描時發生錯誤: $e");
    }
  }
  Stream<List<Map<String, dynamic>>> get beaconStream => _scanService.beaconStream;
}
