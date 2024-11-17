import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:test/database.dart' as db;
import 'package:get/get.dart';
import 'package:test/pages/home.dart';

class MissingEventService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final double missingThreshold = 1; //遺失臨界距離(m)
  final Map<String, int> _missingCounts = {};
  List<db.Beacon> registeredBeacons = [];
  final RxList<db.Beacon> _BeaconsList;

  MissingEventService(this._BeaconsList) {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher'); // 確保通知圖標存在於 `@mipmap` 中
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onSelectNotification);
  }

  // 更新已註冊的 Beacon 列表
  void updateRegisteredBeacons(List<db.Beacon> beacons) {
    registeredBeacons = beacons;
  }

// 檢查物品是否遺失
  void checkIfItemIsMissing(List<Map<String, dynamic>> scannedBeacons) {
    Set<String> scannedBeaconIds = scannedBeacons.map((b) => b['uuid'] as String).toSet();

    // Beacon全部遺失 全體+1並退出
    if (scannedBeaconIds.isEmpty) {
      for (var beacon in registeredBeacons) {
        _incrementMissingCount(beacon.uuid, beacon.item);
      }
      return;
    }

    // 檢查每一個已註冊的 Beacon
    for (var beacon in registeredBeacons) {

      if (scannedBeaconIds.contains(beacon.uuid)) {
        // 如果 Beacon 有掃描到
        var scannedBeacon = scannedBeacons.firstWhere((b) => b['uuid'] == beacon.uuid);
        double distance = scannedBeacon['distance'];
        // 檢查距離是否超過臨界值
        if (distance > missingThreshold) {
          _incrementMissingCount(beacon.uuid, beacon.item);
        }
        else {
          // 如果距離正常，重置計數
          _missingCounts[beacon.uuid] = 0;
          _updateBeaconMissingStatus(beacon.uuid, 0);
        }
      }
      else {
        // 如果 Beacon 沒有掃描到，計算為信號消失
        _incrementMissingCount(beacon.uuid, beacon.item);
      }
    }
  }

  // 增加遺失計數，如果達到 3 次則發送通知
  void _incrementMissingCount(String beaconId, String item) {
    _missingCounts[beaconId] = (_missingCounts[beaconId] ?? 0) + 1;
    print('Beacon $beaconId 超過閾值或信號消失, 當前次數: ${_missingCounts[beaconId]}');

    if (_missingCounts[beaconId] == 3) {
      _sendMissingNotification(beaconId, item);
      _updateBeaconMissingStatus(beaconId, 1);
      print('$item 遺失');

    }
  }

  // 更新 Beacon 的 isMissing 屬性
  Future<void> _updateBeaconMissingStatus(String beaconId, int isMissing) async {
    db.Beacon? beacon = await db.BeaconDB.getBeaconByUUID(beaconId);
    if (beacon != null) {
      if (beacon.isMissing != isMissing) {
        beacon = beacon.copyWith(isMissing: isMissing);
        await db.BeaconDB.update(beacon);

        // 找到對應的 Beacon 並更新 RxList
        final index = _BeaconsList.indexWhere((b) => b.uuid == beaconId);
        if (index != -1) {
          _BeaconsList[index] = beacon; // 更新單個 Beacon
        }

        print('Beacon $beaconId 的 isMissing 狀態已更新為 $isMissing');
      }
      if (Get.isRegistered<ScanPage>()) {
        Get.find<ScanPage>().refreshCallback();
      }
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

      // Get.toNamed('pages/searching', arguments: {
      //   'itemName': payload,
      //   'beaconId': payload, // 假設 payload 同時包含 beaconId
      // });

      Get.offAllNamed('pages/home'); // 移除所有頁面並導航到主頁
    }
  }

  void dispose() {
    _missingCounts.clear();
  }
}
