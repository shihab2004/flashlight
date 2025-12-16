import 'package:flutter/material.dart';

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
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final available = await FlashlightChannel.isTorchAvailable();
      if (!mounted) return;
      setState(() {
        _isAvailable = available;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _toggle() async {
    if (_isBusy || !_isAvailable) return;

    final next = !_isOn;
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await FlashlightChannel.setTorch(next);
      if (!mounted) return;
      setState(() {
        _isOn = next;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
    }
  }

  @override
  void dispose() {
    // Best-effort: turn off torch when leaving.
    FlashlightChannel.setTorch(false);
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                            _isOn ? Icons.flashlight_on : Icons.flashlight_off,
                            key: ValueKey(_isOn),
                            size: 72,
                            color: cs.onSurface,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
