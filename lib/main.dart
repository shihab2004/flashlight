import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'flashlight_channel.dart';

void main() {
  runApp(const FlashlightApp());
}

class FlashlightApp extends StatelessWidget {
  const FlashlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    final darkScheme =
        ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: Colors.amber.shade400,
          tertiary: Colors.amber.shade400,
        );

    return MaterialApp(
      title: 'Flashlight LED',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: darkScheme.secondary,
            foregroundColor: darkScheme.onSecondary,
          ),
        ),
      ),
      home: const FlashlightHomePage(),
    );
  }
}

class FlashlightHomePage extends StatefulWidget {
  const FlashlightHomePage({super.key});

  @override
  State<FlashlightHomePage> createState() => _FlashlightHomePageState();
}

class _FlashlightHomePageState extends State<FlashlightHomePage>
    with SingleTickerProviderStateMixin {
  bool _isOn = false;
  bool _isAvailable = false;
  bool _isBusy = false;
  String? _error;

  late final AnimationController _waves;

  late final Future<String> _versionText;

  @override
  void initState() {
    super.initState();
    _waves = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _versionText = _loadVersionText();
    _init();
  }

  void _syncWaves() {
    if (_isOn) {
      if (!_waves.isAnimating) {
        _waves.repeat();
      }
    } else {
      if (_waves.isAnimating) {
        _waves.stop();
      }
      _waves.value = 0;
    }
  }

  Future<String> _loadVersionText() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = info.buildNumber.trim();
      if (build.isEmpty) {
        return 'Version: ${info.version}';
      }
      return 'Version: ${info.version}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _init() async {
    if (!mounted) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });

    bool? available;
    Object? error;
    try {
      available = await FlashlightChannel.isTorchAvailable();
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (available != null) {
        _isAvailable = available!;
      }
      if (error != null) {
        _error = error.toString();
      }
    });
  }

  Future<void> _toggle() async {
    if (_isBusy || !_isAvailable) return;

    final next = !_isOn;
    if (!mounted) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });

    Object? error;
    bool didSwitch = false;
    try {
      await FlashlightChannel.setTorch(next);
      didSwitch = true;
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (didSwitch) {
        _isOn = next;
        _syncWaves();
      }
      if (error != null) {
        _error = error.toString();
      }
    });
  }

  @override
  void dispose() {
    // Best-effort: turn off torch when leaving.
    if (_isOn) {
      FlashlightChannel.setTorch(false);
    }

    _waves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = _isOn ? 'Turn Off' : 'Turn On';
    final statusText = _isAvailable
        ? (_isOn ? 'Flashlight is ON' : 'Flashlight is OFF')
        : 'Flashlight not available';

    final background = Color.lerp(
      cs.surface,
      cs.primary.withOpacity(0.10),
      _isOn ? 1 : 0,
    )!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashlight LED'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        color: background,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _isOn ? 1 : 0),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, child) {
                    final ringColor = Color.lerp(
                      cs.surfaceContainerHighest,
                      cs.secondary.withOpacity(0.22),
                      t,
                    )!;

                    final glowColor = cs.secondary.withOpacity(0.28 * t);

                    return AnimatedScale(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      scale: _isOn ? 1.0 : 0.95,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _LightWaves(
                            visible: _isOn,
                            progress: _waves,
                            color: cs.secondary,
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (_isBusy || !_isAvailable)
                                  ? null
                                  : _toggle,
                              customBorder: const CircleBorder(),
                              child: Semantics(
                                button: true,
                                enabled: !_isBusy && _isAvailable,
                                label: _isOn
                                    ? 'Turn flashlight off'
                                    : 'Turn flashlight on',
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ringColor,
                                    boxShadow: [
                                      if (t > 0)
                                        BoxShadow(
                                          color: glowColor,
                                          blurRadius: 34 * t,
                                          spreadRadius: 2 * t,
                                        ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    child: Icon(
                                      _isOn
                                          ? Icons.flashlight_on
                                          : Icons.flashlight_off,
                                      key: ValueKey(_isOn),
                                      size: 72,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    statusText,
                    key: ValueKey(statusText),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: 240,
                  height: 56,
                  child: FilledButton(
                    onPressed: (_isBusy || !_isAvailable) ? null : _toggle,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(label, key: ValueKey(label)),
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                FutureBuilder<String>(
                  future: _versionText,
                  builder: (context, snapshot) {
                    final text = snapshot.data?.trim() ?? '';
                    if (text.isEmpty) return const SizedBox.shrink();

                    return Text(
                      text,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LightWaves extends StatelessWidget {
  const _LightWaves({
    required this.visible,
    required this.progress,
    required this.color,
  });

  final bool visible;
  final Animation<double> progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: visible ? 1 : 0.98,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: progress,
            builder: (context, child) {
              return CustomPaint(
                painter: _LightWavesPainter(
                  progress: progress.value,
                  color: color,
                ),
                child: const SizedBox(width: 210, height: 210),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LightWavesPainter extends CustomPainter {
  _LightWavesPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final shortest = size.shortestSide;
    final baseRadius = shortest * 0.34;
    final maxExtra = shortest * 0.14;
    const waveCount = 3;

    for (var i = 0; i < waveCount; i++) {
      final phase = i / waveCount;
      var t = progress - phase;
      if (t < 0) t += 1;

      // t: 0..1 (moving outward). Fade out as it expands.
      final fade = (1 - t).clamp(0.0, 1.0);
      final radius = baseRadius + (maxExtra * t);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0 + (2.0 * fade)
        ..color = color.withOpacity(0.35 * fade);

      final rect = Rect.fromCircle(center: c, radius: radius);
      // Right side arc (like ")")
      canvas.drawArc(rect, -0.45 * math.pi, 0.90 * math.pi, false, paint);
      // Left side arc (like "(")
      canvas.drawArc(
        rect,
        (math.pi - 0.45 * math.pi),
        0.90 * math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LightWavesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
