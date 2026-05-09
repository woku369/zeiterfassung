import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_record.dart';
import '../models/time_entry.dart';
import '../models/work_type.dart';
import '../providers/trip_provider.dart';
import 'entry_form_screen.dart';

class TripLogScreen extends StatefulWidget {
  const TripLogScreen({super.key});

  @override
  State<TripLogScreen> createState() => _TripLogScreenState();
}

class _TripLogScreenState extends State<TripLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TripProvider>();
    final trips = prov.trips;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fahrtenbuch'),
        actions: [
          if (trips.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Alle abgeschlossenen löschen',
              onPressed: () => _confirmDeleteAll(context, prov),
            ),
        ],
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text('Noch keine Fahrten aufgezeichnet',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Fahrtenbuch in den Einstellungen aktivieren,\n'
                    'dann ab 15 km/h automatisch aufzeichnen.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: trips.length,
              itemBuilder: (ctx, i) => _TripCard(trip: trips[i]),
            ),
    );
  }

  Future<void> _confirmDeleteAll(
      BuildContext ctx, TripProvider prov) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Alle Fahrten löschen?'),
        content: const Text('Alle abgeschlossenen Fahrten werden gelöscht.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('Löschen')),
        ],
      ),
    );
    if (ok != true) return;
    for (final t in List.of(prov.trips)) {
      if (t.isComplete) await prov.deleteTrip(t.id);
    }
  }
}

class _TripCard extends StatefulWidget {
  final TripRecord trip;
  const _TripCard({required this.trip});

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _resolveAddresses();
  }

  Future<void> _resolveAddresses() async {
    if (widget.trip.startAddress != null && widget.trip.endAddress != null) {
      return;
    }
    if (!widget.trip.isComplete) return;
    setState(() => _resolving = true);
    await context.read<TripProvider>().resolveAddresses(widget.trip);
    if (mounted) setState(() => _resolving = false);
  }

  @override
  Widget build(BuildContext context) {
    final trip = context
        .watch<TripProvider>()
        .trips
        .firstWhere((t) => t.id == widget.trip.id,
            orElse: () => widget.trip);
    final cs = Theme.of(context).colorScheme;
    final isOpen = !trip.isComplete;
    final dateStr = DateFormat('EEE, dd.MM.yyyy', 'de_AT')
        .format(trip.startTime);
    final timeStr =
        '${DateFormat('HH:mm').format(trip.startTime)}'
        '${trip.endTime != null ? ' – ${DateFormat('HH:mm').format(trip.endTime!)}' : ''}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                isOpen
                    ? Icons.directions_car
                    : Icons.directions_car_outlined,
                color: isOpen
                    ? cs.primary
                    : cs.onSurface.withOpacity(0.6),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(dateStr,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (isOpen)
                Chip(
                  label: const Text('Fahrt läuft…'),
                  backgroundColor: cs.primaryContainer,
                  labelStyle:
                      TextStyle(color: cs.onPrimaryContainer, fontSize: 11),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
            ]),
            const SizedBox(height: 6),
            // Addresses
            if (_resolving)
              const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else ...[
              _AddressRow(
                  icon: Icons.trip_origin,
                  label: trip.startAddress ??
                      '${trip.startLat.toStringAsFixed(4)}, '
                          '${trip.startLng.toStringAsFixed(4)}'),
              if (trip.endAddress != null || trip.endLat != null)
                _AddressRow(
                    icon: Icons.place_outlined,
                    label: trip.endAddress ??
                        '${trip.endLat!.toStringAsFixed(4)}, '
                            '${trip.endLng!.toStringAsFixed(4)}'),
            ],
            const SizedBox(height: 6),
            // Stats row
            Row(children: [
              _Stat(Icons.schedule_outlined, timeStr),
              const SizedBox(width: 12),
              _Stat(Icons.straighten_outlined,
                  '${trip.distanceKm.toStringAsFixed(1)} km'),
              if (trip.duration != null) ...[
                const SizedBox(width: 12),
                _Stat(Icons.timer_outlined, trip.durationFormatted),
              ],
              const Spacer(),
              if (!isOpen) ...[
                if (trip.linkedEntryId == null)
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Übernehmen'),
                    onPressed: () => _takeOver(context, trip),
                  )
                else
                  Icon(Icons.check_circle_outline,
                      color: cs.primary, size: 20),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () =>
                      context.read<TripProvider>().deleteTrip(trip.id),
                  tooltip: 'Löschen',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _takeOver(BuildContext ctx, TripRecord trip) async {
    final now = DateTime.now();
    final prefilled = TimeEntry(
      id: const Uuid().v4(),
      date: trip.startTime,
      startTime: trip.startTime,
      endTime: trip.endTime,
      workType: WorkType.offsite,
      dayType: DayType.workday,
      distanceKm: trip.distanceKm,
      note: [
        if (trip.startAddress != null) trip.startAddress!,
        if (trip.endAddress != null) '→ ${trip.endAddress!}',
      ].join(' '),
      createdAt: now,
    );
    final result = await Navigator.of(ctx).push<bool>(
      MaterialPageRoute(
        builder: (_) => EntryFormScreen(entry: prefilled, forceNew: true),
      ),
    );
    if (result == true && ctx.mounted) {
      await ctx.read<TripProvider>().linkEntry(trip.id, 'linked');
    }
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AddressRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Stat(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
