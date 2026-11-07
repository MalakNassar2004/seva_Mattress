import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

enum NetSpeed { checking, offline, slow, medium, fast }

class SplashController extends GetxController {
  /// First route after the splash (login or home).
  static const String nextRoute = AppRoutes.login;

  /// Lightweight URL used to measure connection latency (returns 204).
  static const String _probeUrl = 'https://www.gstatic.com/generate_204';

  final speed = NetSpeed.checking.obs;
  final latencyMs = 0.obs;

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    speed.value = NetSpeed.checking;
    final started = DateTime.now();
    final ms = await _measureLatency();
    latencyMs.value = ms;

    if (ms < 0) {
      speed.value = NetSpeed.offline;
      return; // stays on the splash, user can retry
    }

    // The splash stays longer on slower connections.
    late final Duration minShow;
    if (ms < 250) {
      speed.value = NetSpeed.fast;
      minShow = const Duration(milliseconds: 2200);
    } else if (ms < 700) {
      speed.value = NetSpeed.medium;
      minShow = const Duration(milliseconds: 3000);
    } else {
      speed.value = NetSpeed.slow;
      minShow = const Duration(milliseconds: 4200);
    }

    final elapsed = DateTime.now().difference(started);
    if (elapsed < minShow) await Future.delayed(minShow - elapsed);
    Get.offAllNamed(nextRoute);
  }

  /// Returns latency in ms, or -1 when offline.
  Future<int> _measureLatency() async {
    final samples = <int>[];
    for (var i = 0; i < 2; i++) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4);
      final sw = Stopwatch()..start();
      try {
        final req = await client.getUrl(Uri.parse(_probeUrl));
        final res = await req.close().timeout(const Duration(seconds: 4));
        await res.drain();
        sw.stop();
        samples.add(sw.elapsedMilliseconds);
      } catch (_) {
        // counted as a failed sample
      } finally {
        client.close(force: true);
      }
    }
    if (samples.isEmpty) return -1;
    return samples.reduce((a, b) => a + b) ~/ samples.length;
  }

  Future<void> retry() => _start();
}