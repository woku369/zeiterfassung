import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/tracked_location.dart';
import '../models/work_type.dart';
import '../models/employer.dart';
import '../providers/location_provider.dart';
import '../providers/employer_provider.dart';
import '../services/geofencing_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  bool _tracking = GeofencingService.instance.isTracking;

  Future<void> _toggleTracking(List<TrackedLocation> locations) async {
    if (_tracking) {
      await GeofencingService.instance.stopTracking();
      setState(() => _tracking = false);
    } else {
      final started = await GeofencingService.instance.startTracking(locations);
      setState(() => _tracking = started);
      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('GPS-Berechtigung fehlt. Bitte in Systemeinstellungen aktivieren.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Standorte'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _TrackingChip(
              active: _tracking,
              onTap: () => _toggleTracking(lp.activeLocations),
            ),
          ),
        ],
      ),
      body: lp.locations.isEmpty
          ? _EmptyState(onAdd: () => _showLocationDialog(context, null))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: lp.locations.length,
              itemBuilder: (ctx, i) => _LocationCard(
                location: lp.locations[i],
                onEdit: () => _showLocationDialog(ctx, lp.locations[i]),
                onDelete: () => _confirmDelete(ctx, lp.locations[i]),
                onToggle: () async {
                  await lp.toggleActive(lp.locations[i]);
                  if (_tracking) {
                    GeofencingService.instance.updateLocations(lp.activeLocations);
                  }
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationDialog(context, null),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Standort hinzufügen'),
      ),
    );
  }

  Future<void> _showLocationDialog(
      BuildContext context, TrackedLocation? existing) async {
    final lp = context.read<LocationProvider>();
    final result = await showDialog<_LocationFormResult>(
      context: context,
      builder: (_) => _LocationDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;
    if (existing == null) {
      await lp.add(
        name: result.name,
        latitude: result.latitude,
        longitude: result.longitude,
        radiusMeters: result.radiusMeters,
        workType: result.workType,
        employerId: result.employerId,
        defaultKm: result.defaultKm,
      );
    } else {
      await lp.update(existing.copyWith(
        name: result.name,
        latitude: result.latitude,
        longitude: result.longitude,
        radiusMeters: result.radiusMeters,
        workType: result.workType,
        employerId: result.employerId,
        defaultKm: result.defaultKm,
      ));
    }
    if (_tracking) {
      GeofencingService.instance.updateLocations(lp.activeLocations);
    }
  }

  Future<void> _confirmDelete(BuildContext context, TrackedLocation loc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Standort löschen'),
        content: Text('"${loc.name}" wirklich löschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<LocationProvider>().delete(loc.id);
    }
  }
}

class _TrackingChip extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _TrackingChip({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        active ? Icons.gps_fixed : Icons.gps_not_fixed,
        size: 16,
        color: active ? Colors.green : null,
      ),
      label: Text(active ? 'Aktiv' : 'Inaktiv'),
      onPressed: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Keine Standorte definiert',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Standort hinzufügen'),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final TrackedLocation location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _LocationCard({
    required this.location,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final employers = context.read<EmployerProvider>().employers;
    final employer = location.employerId == null
        ? null
        : employers.firstWhere((e) => e.id == location.employerId,
            orElse: () => employers.first);
    final employerLabel = employer == null ? 'Alle Arbeitgeber' : employer.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.location_on_outlined,
          color: location.isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
        title: Text(location.name),
        subtitle: Text(
          '${location.workType.label} · ${location.radiusMeters.toInt()} m · $employerLabel'
          '${location.defaultKm != null ? ' · ${location.defaultKm!.toStringAsFixed(0)} km' : ''}\n'
          '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: location.isActive, onChanged: (_) => onToggle()),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                PopupMenuItem(value: 'delete', child: Text('Löschen')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class _LocationFormResult {
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final WorkType workType;
  final String? employerId;
  final double? defaultKm;

  _LocationFormResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.workType,
    this.employerId,
    this.defaultKm,
  });
}

class _LocationDialog extends StatefulWidget {
  final TrackedLocation? existing;
  const _LocationDialog({this.existing});

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _radiusCtrl;
  late final TextEditingController _kmCtrl;
  late WorkType _workType;
  String? _employerId; // null = alle Arbeitgeber
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _latCtrl = TextEditingController(
        text: e != null ? e.latitude.toStringAsFixed(6) : '');
    _lngCtrl = TextEditingController(
        text: e != null ? e.longitude.toStringAsFixed(6) : '');
    _radiusCtrl =
        TextEditingController(text: (e?.radiusMeters ?? 200.0).toInt().toString());
    _kmCtrl = TextEditingController(
        text: e?.defaultKm != null ? e!.defaultKm!.toStringAsFixed(0) : '');
    _workType = e?.workType ?? WorkType.offsite;
    _employerId = e?.employerId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    _kmCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentPosition() async {
    setState(() => _loadingGps = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _latCtrl.text = pos.latitude.toStringAsFixed(6);
      _lngCtrl.text = pos.longitude.toStringAsFixed(6);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS nicht verfügbar')));
      }
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.'));
    final lng = double.tryParse(_lngCtrl.text.replaceAll(',', '.'));
    final radius =
        double.tryParse(_radiusCtrl.text.replaceAll(',', '.')) ?? 200.0;

    if (name.isEmpty || lat == null || lng == null) return;

    final km = double.tryParse(_kmCtrl.text.replaceAll(',', '.'));
    Navigator.pop(
      context,
      _LocationFormResult(
        name: name,
        latitude: lat,
        longitude: lng,
        radiusMeters: radius,
        workType: _workType,
        employerId: _employerId,
        defaultKm: (km != null && km > 0) ? km : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employers = context.read<EmployerProvider>().employers;
    return AlertDialog(
      title: Text(
          widget.existing == null ? 'Standort hinzufügen' : 'Standort bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Name (z. B. Gurk)', border: OutlineInputBorder()),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                        labelText: 'Breitengrad', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(
                        labelText: 'Längengrad', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadingGps ? null : _useCurrentPosition,
              icon: _loadingGps
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, size: 18),
              label: const Text('Aktuelle Position verwenden'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _radiusCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Radius',
                border: OutlineInputBorder(),
                suffixText: 'm',
                helperText: 'Empfohlen: 100–500 m',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _kmCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Standard-km bei Auto-Einstempeln (optional)',
                border: OutlineInputBorder(),
                suffixText: 'km',
                helperText: 'Hin- & Rückfahrt, z. B. 78 für Labegg ↔ Gurk',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<WorkType>(
              value: _workType,
              decoration: const InputDecoration(
                  labelText: 'Arbeitstyp', border: OutlineInputBorder()),
              items: WorkType.values
                  .map((w) => DropdownMenuItem(
                      value: w, child: Text(w.label)))
                  .toList(),
              onChanged: (v) => setState(() => _workType = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _employerId,
              decoration: const InputDecoration(
                labelText: 'Arbeitgeber',
                border: OutlineInputBorder(),
                helperText: 'Alle = wird für jeden Arbeitgeber überwacht',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Alle Arbeitgeber'),
                ),
                ...employers.map((e) => DropdownMenuItem<String?>(
                      value: e.id,
                      child: Text(e.name),
                    )),
              ],
              onChanged: (v) => setState(() => _employerId = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen')),
        FilledButton(onPressed: _submit, child: const Text('Speichern')),
      ],
    );
  }
}
