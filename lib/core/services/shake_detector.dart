import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final VoidCallback onShake;
  final double threshold;
  final int cooldownMs;

  StreamSubscription? _subscription;
  DateTime _lastShake = DateTime(0);

  ShakeDetector({
    required this.onShake,
    this.threshold = 15.0,
    this.cooldownMs = 1000,
  });

  void start() {
    _subscription = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final gForce = (magnitude - 9.8).abs();

      if (gForce > threshold) {
        final now = DateTime.now();
        final msSinceLast = now.difference(_lastShake).inMilliseconds;
        if (msSinceLast > cooldownMs) {
          _lastShake = now;
          onShake();
        }
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
