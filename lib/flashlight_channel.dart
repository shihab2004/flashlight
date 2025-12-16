import 'package:flutter/services.dart';

class FlashlightChannel {
  FlashlightChannel._();

  static const MethodChannel _channel = MethodChannel('flashlight');

  static Future<bool> isTorchAvailable() async {
    final result = await _channel.invokeMethod<bool>('isTorchAvailable');
    return result ?? false;
  }

  static Future<void> setTorch(bool enabled) async {
    await _channel.invokeMethod<void>('setTorch', <String, dynamic>{
      'enabled': enabled,
    });
  }
}
