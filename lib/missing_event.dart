import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class MissingEventService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final double missingThreshold = 1;
  final Map<String, int> _missingCounts = {};

  MissingEventService() {
    _initializeNotifications();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    _notificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: _onSelectNotification);
  }

// 檢查物品是否遺失
  void checkIfItemIsMissing(Map<String, dynamic> beacon) {
    String beaconId = beacon['uuid'];
    double distance = beacon['distance'] ?? double.infinity;

    if (distance > missingThreshold) {
      _missingCounts[beaconId] = (_missingCounts[beaconId] ?? 0) + 1;
      print('Beacon $beaconId 超過閾值, 當前次數: ${_missingCounts[beaconId]}');

      if (_missingCounts[beaconId] == 3) {
        _sendMissingNotification(beacon);
      }
    } else {
      print('Beacon $beaconId 距離恢復正常, 重置計數');
      _missingCounts[beaconId] = 0;
    }
  }

  Future<void> _sendMissingNotification(Map<String, dynamic> beacon) async {
    String beaconId = beacon['uuid'];

    if (Get.context != null && Get.isSnackbarOpen == false) {
      // 如果在前景，顯示應用內通知
      Get.snackbar(
        '物品遺失警告',
        '您的物品 "$beaconId" 可能已經遺失。',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );
    } else {
      // 發送系統通知
      const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'missing_item_channel',
        'Missing Item',
        channelDescription: 'Notifications for missing items',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
      await _notificationsPlugin.show(
        0,
        '物品遺失警告',
        '您的物品 "$beaconId" 可能已經遺失。',
        platformChannelSpecifics,
        payload: beaconId,
      );
    }

    // 通知發送後重置計數
    _missingCounts[beaconId] = 0;
  }

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
