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
      title: 'Flashlight',
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
    final label = _isOn ? 'Turn Off' : 'Turn On';
    final statusText = _isAvailable
        ? (_isOn ? 'Flashlight is ON' : 'Flashlight is OFF')
        : 'Flashlight not available';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashlight'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusText,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: 220,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isBusy || !_isAvailable) ? null : _toggle,
                  child: _isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
