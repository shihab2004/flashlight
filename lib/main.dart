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
    return MaterialApp(
      title: 'Flashlight LED',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.light,
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

class _FlashlightHomePageState extends State<FlashlightHomePage> {
  bool _isOn = false;
  bool _isAvailable = false;
  bool _isBusy = false;
  String? _error;

  late final Future<String> _versionText;

  @override
  void initState() {
    super.initState();
    _versionText = _loadVersionText();
    _init();
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
                      cs.primary.withOpacity(0.22),
                      t,
                    )!;

                    return AnimatedScale(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      scale: _isOn ? 1.0 : 0.95,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (_isBusy || !_isAvailable) ? null : _toggle,
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
