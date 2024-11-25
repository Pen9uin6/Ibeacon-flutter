import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class SearchingPage extends StatefulWidget {
  final String itemName;
  final String beaconId;
  final List<Map<String, dynamic>> scannedBeacons;
  final Stream<List<Map<String, dynamic>>> beaconStream;

  SearchingPage({
    super.key,
    required this.itemName,
    required this.beaconId,
    required this.scannedBeacons,
    required this.beaconStream,
  });

  @override
  _SearchingPageState createState() => _SearchingPageState();
}

class _SearchingPageState extends State<SearchingPage>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<List<Map<String, dynamic>>> _subscription;
  final AudioPlayer _player = AudioPlayer();
  late AnimationController _controller;
  late Animation<double> _iconScale;
  double distance = 0.0;
  bool hasSignal = false;
  Timer? _soundTimer;

  @override
  void initState() {
    super.initState();

    // 初始化動畫控制器
    _controller = AnimationController(
      duration: const Duration(seconds: 1), // 預設為 1 秒
      vsync: this,
    );

    // 圖標縮放動畫
    _iconScale = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // 初始化時找到目標 Beacon
    final initialBeacon = widget.scannedBeacons.firstWhere(
          (beacon) => beacon['uuid'] == widget.beaconId,
      orElse: () => <String, dynamic>{},
    );

    if (initialBeacon.isNotEmpty && initialBeacon['distance'] != null) {
      distance = (initialBeacon['distance'] as num).toDouble();
      hasSignal = true;
      _startSoundAndAnimation();
    } else {
      distance = 0.0;
      hasSignal = false;
    }

    // 監聽 Beacon 資料流更新
    _subscription = widget.beaconStream.listen((scannedBeacons) {
      final targetBeacon = scannedBeacons.firstWhere(
            (beacon) => beacon['uuid'] == widget.beaconId,
        orElse: () => <String, dynamic>{},
      );

      setState(() {
        if (targetBeacon.isNotEmpty && targetBeacon['distance'] != null) {
          distance = (targetBeacon['distance'] as num).toDouble();
          hasSignal = true;
          _startSoundAndAnimation();
        } else {
          distance = 0.0;
          hasSignal = false;
          _stopSoundAndAnimation();
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _stopSoundAndAnimation();
    _controller.dispose();
    super.dispose();
  }

  void _startSoundAndAnimation() {
    _stopSoundAndAnimation();
    final interval = _calculateInterval(distance);
    if (interval != null) {
      _controller.duration = interval;
      _controller.repeat(reverse: true);

      _soundTimer = Timer.periodic(interval, (_) {
        _player.play(AssetSource('sound_effects/searching.wav')).catchError((e) {
          print("音效播放失敗: $e");
        });
      });
    }
  }

  void _stopSoundAndAnimation() {
    _soundTimer?.cancel();
    _soundTimer = null;
    _controller.stop();
    _controller.reset();
  }

  Duration? _calculateInterval(double distance) {
    if (distance <= 0) return null;
    if (distance < 1) {
      return const Duration(milliseconds: 300);
    } else if (distance < 3) {
      return const Duration(milliseconds: 500);
    } else if (distance < 5) {
      return const Duration(seconds: 1);
    } else {
      return const Duration(seconds: 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = hasSignal
        ? '距離: ${distance.toStringAsFixed(2)} 公尺'
        : '失去信號';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('搜尋 ${widget.itemName}'),
            backgroundColor: Colors.teal,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: _iconScale.value,
                  child: Icon(
                    hasSignal
                        ? Icons.location_searching
                        : Icons.error_outline,
                    size: 100,
                    color: hasSignal ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: hasSignal ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '物件名稱: ${widget.itemName}\nUUID: ${widget.beaconId}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
