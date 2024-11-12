import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MissingEventService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final double missingThreshold = 1.5; //遺失臨界距離(m)
  final Map<String, int> _missingCounts = {};

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

  // 檢查物品是否遺失
  void checkIfItemIsMissing(Map<String, dynamic> beacon) {
    if (beacon['uuid'] == null || beacon['item'] == null) {
      print('UUID is null or empty');
      return;
    }
    String beaconId = beacon['uuid'] as String;
    String item = beacon['item'];
    double distance = beacon['distance'] ?? double.infinity;

    if (distance > missingThreshold) {
      _missingCounts[beaconId] = (_missingCounts[beaconId] ?? 0) + 1;
      print('Beacon $beaconId 超過閾值, 當前次數: ${_missingCounts[beaconId]}');

      if (_missingCounts[beaconId] == 3) {
        //超過三次發送通知
        _sendMissingNotification(item);
        print('$item 遺失' );
      }
    } else {
      print('Beacon $beaconId 距離正常');
      _missingCounts[beaconId] = 0;
    }
  }

  // 發送物品遺失通知
  Future<void> _sendMissingNotification(String item) async {
    await showNotification(
      id: 0,
      title: '物品遺失警告',
      body: '物品 "$item" 不見了。',
      payload: item,
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
