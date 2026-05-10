import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bluetooth_service.dart';

class BluetoothTripScreen extends StatefulWidget {
  const BluetoothTripScreen({super.key});

  @override
  State<BluetoothTripScreen> createState() => _BluetoothTripScreenState();
}

class _BluetoothTripScreenState extends State<BluetoothTripScreen> {
  static const _btChannel = MethodChannel('zeiterfassung/bluetooth');

  List<Map<String, String>> _paired = [];
  Set<String> _selected = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final watchlist = await BluetoothTripService.loadWatchlist();
      final raw = await _btChannel.invokeMethod<List>('getPairedDevices');
      final devices = (raw ?? [])
          .cast<Map>()
          .map((m) => {'name': m['name'] as String, 'address': m['address'] as String})
          .toList();
      setState(() {
        _paired = devices;
        _selected = watchlist.toSet();
        _loading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    await BluetoothTripService.saveWatchlist(_selected.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gespeichert')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth – Fahrtenbuch'),
        actions: [
          if (!_loading && _error == null)
            TextButton(onPressed: _save, child: const Text('Speichern')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _paired.isEmpty
                  ? const _EmptyView()
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            'Fahrtaufzeichnung startet automatisch sobald eines '
                            'der gewählten Geräte verbindet, und endet beim Trennen.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _paired.length,
                            itemBuilder: (_, i) {
                              final d = _paired[i];
                              final addr = d['address']!;
                              return CheckboxListTile(
                                title: Text(d['name']!),
                                subtitle: Text(addr,
                                    style: const TextStyle(fontSize: 11)),
                                secondary: const Icon(Icons.bluetooth),
                                value: _selected.contains(addr),
                                onChanged: (v) => setState(() {
                                  if (v == true)
                                    _selected.add(addr);
                                  else
                                    _selected.remove(addr);
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 48),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_searching,
              size: 56,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          const Text('Keine gekoppelten Bluetooth-Geräte gefunden.'),
          const SizedBox(height: 8),
          Text(
            'Gerät zuerst in den Android-Bluetooth-Einstellungen koppeln.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
