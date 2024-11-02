import 'package:flutter_background/flutter_background.dart';

class BackgroundExecute {
  // 初始化並啟動後台執行
  Future<bool> initializeBackground() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "應用正在前景服務中運行",
      notificationText: "應用正在持續掃描藍牙設備。",
      notificationImportance: AndroidNotificationImportance.max, //通知重要性級別
      notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'),
    );
    bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
    if (success) {
      await FlutterBackground.enableBackgroundExecution();
    }
    return success;
  }

  // 停止後台執行
  Future<void> stopBackgroundExecute() async {
    if (await FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
  }
}