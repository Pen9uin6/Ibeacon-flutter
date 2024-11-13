import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test/database.dart' as db;
import 'package:get/get.dart';
import 'package:test/pages/home.dart';

class MissingEventService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final double missingThreshold = 3; //遺失臨界距離(m)
  final Map<String, int> _missingCounts = {};
  List<db.Beacon> registeredBeacons = [];

  MissingEventService() {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher'); // 確保通知圖標存在於 `@mipmap` 中
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    _notificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: _onSelectNotification);
  }

  // 更新已註冊的 Beacon 列表
  void updateRegisteredBeacons(List<db.Beacon> beacons) {
    registeredBeacons = beacons;
  }

// 檢查物品是否遺失
  void checkIfItemIsMissing(List<Map<String, dynamic>> scannedBeacons) {
    Set<String> scannedBeaconIds = scannedBeacons.map((b) => b['uuid'] as String).toSet();

    // 檢查每一個已註冊的 Beacon
    for (var beacon in registeredBeacons) {
      if(beacon.uuid != null) {
        String beaconId = beacon.uuid;

        if (scannedBeaconIds.contains(beaconId)) {
          // 如果 Beacon 有掃描到
          var scannedBeacon = scannedBeacons.firstWhere((b) => b['uuid'] == beaconId);
          double distance = scannedBeacon['distance'];
          _checkDistance(beaconId, beacon.item, distance);
        } else {
          // 如果 Beacon 沒有掃描到，計算為信號消失
          _incrementMissingCount(beaconId, beacon.item);
        }
      }
    }
  }

  // 檢查距離是否超過臨界值
  void _checkDistance(String beaconId, String item, double distance) {
    if (distance > missingThreshold) {
      _incrementMissingCount(beaconId, item);
    } else {
      // 如果距離正常，重置計數
      _missingCounts[beaconId] = 0;
    }
  }

  // 增加遺失計數，如果達到 3 次則發送通知
  void _incrementMissingCount(String beaconId, String item) {
    _missingCounts[beaconId] = (_missingCounts[beaconId] ?? 0) + 1;
    print('Beacon $beaconId 超過閾值或信號消失, 當前次數: ${_missingCounts[beaconId]}');

    if (_missingCounts[beaconId] == 3) {
      _sendMissingNotification(beaconId, item);
      print('$item 遺失');
    }
  }

  // 發送物品遺失通知
  Future<void> _sendMissingNotification(String beaconId, String item) async {
    await showNotification(
      id: beaconId.hashCode,
      title: '物品遺失警告',
      body: '物品 "$item" 不見了。',
      payload: item,
    );
  }

  // 顯示通知
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    return _notificationsPlugin.show(
      id,
      title,
      body,
      await _notificationDetails(),
      payload: payload,
    );
  }

  // 設置通知的詳細信息
  Future<NotificationDetails> _notificationDetails() async {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'missing_item_channel',
        'Missing Item',
        channelDescription: 'Notifications for missing items',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      ),
    );
  }

  // 處理通知點擊事件
  void _onSelectNotification(NotificationResponse notificationResponse) {
    String? payload = notificationResponse.payload;
    if (payload != null) {
      print('通知被選擇: $payload');
      // 可以在這裡加入需要的額外操作，例如跳轉或顯示提示
    }
  }

  void dispose() {
    _missingCounts.clear();
  }
}
