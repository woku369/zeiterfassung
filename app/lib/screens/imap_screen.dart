import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/imap_config.dart';
import '../database/database_helper.dart';
import '../services/imap_service.dart';

class ImapScreen extends StatefulWidget {
  const ImapScreen({super.key});

  @override
  State<ImapScreen> createState() => _ImapScreenState();
}

class _ImapScreenState extends State<ImapScreen> {
  ImapConfig? _config;
  bool _loading = true;
  bool _syncing = false;
  ImapSyncResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await DatabaseHelper.instance.getImapConfig();
    setState(() {
      _config = cfg;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('E-Mail-Sortierung (IMAP)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InfoCard(),
                const SizedBox(height: 12),
                if (_config == null)
                  _SetupCard(onSetup: () => _showConfigDialog(null))
                else ...[
                  _ConfigCard(
                    config: _config!,
                    onEdit: () => _showConfigDialog(_config),
                    onDelete: _confirmDelete,
                  ),
                  const SizedBox(height: 12),
                  _AddressCard(
                    config: _config!,
                    onUpdate: _saveConfig,
                  ),
                  const SizedBox(height: 12),
                  _KeywordCard(
                    config: _config!,
                    onUpdate: _saveConfig,
                  ),
                  const SizedBox(height: 12),
                  _SyncCard(
                    config: _config!,
                    syncing: _syncing,
                    lastResult: _lastResult,
                    onSync: _runSync,
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _showConfigDialog(ImapConfig? existing) async {
    final result = await showDialog<ImapConfig>(
      context: context,
      builder: (_) => _ConfigDialog(existing: existing),
    );
    if (result == null) return;
    await _saveConfig(result);
  }

  Future<void> _saveConfig(ImapConfig cfg) async {
    await DatabaseHelper.instance.saveImapConfig(cfg);
    setState(() => _config = cfg);
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('IMAP-Konfiguration löschen'),
        content: const Text('Alle IMAP-Einstellungen wirklich entfernen?'),
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
    if (ok == true && _config != null) {
      await DatabaseHelper.instance.deleteImapConfig(_config!.id);
      setState(() {
        _config = null;
        _lastResult = null;
      });
    }
  }

  Future<void> _runSync() async {
    if (_config == null || _syncing) return;
    setState(() => _syncing = true);
    final result = await ImapService.instance.sync(_config!);
    if (mounted) setState(() {
      _syncing = false;
      _lastResult = result;
    });
  }
}

// ── Info card ──────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Text('Wie es funktioniert',
                style: Theme.of(context).textTheme.labelLarge),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Die App verbindet sich mit deinem IMAP-Konto und verschiebt '
            'E-Mails von/an definierten Adressen in eigene Ordner.\n\n'
            '• Posteingang → Zielordner (z. B. „Gurktaler")\n'
            '• Gesendete → Zielordner (z. B. „Gurktaler/Gesendet")\n\n'
            'Zeitstempel gesendeter Mails werden als Aktivitätshinweise '
            'gespeichert.',
            style: TextStyle(fontSize: 13),
          ),
        ]),
      ),
    );
  }
}

// ── Setup card ────────────────────────────────────────────────────────────

class _SetupCard extends StatelessWidget {
  final VoidCallback onSetup;
  const _SetupCard({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.mail_outline),
        title: const Text('IMAP-Konto einrichten'),
        subtitle: const Text('Konto hinzufügen um E-Mails automatisch zu sortieren'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onSetup,
      ),
    );
  }
}

// ── Config card ───────────────────────────────────────────────────────────

class _ConfigCard extends StatelessWidget {
  final ImapConfig config;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ConfigCard({
    required this.config,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: Text(config.host),
          subtitle: Text(
              'Port ${config.port} · ${config.useSsl ? 'SSL' : 'kein SSL'}\n${config.username}'),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
              PopupMenuItem(value: 'delete', child: Text('Entfernen')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FolderRow(
                  label: 'Posteingang →',
                  folder: config.inboxTargetFolder),
              const SizedBox(height: 4),
              _FolderRow(
                  label: 'Gesendet →',
                  folder: config.sentTargetFolder),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FolderRow extends StatelessWidget {
  final String label;
  final String folder;
  const _FolderRow({required this.label, required this.folder});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(width: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(folder, style: const TextStyle(fontSize: 12)),
      ),
    ]);
  }
}

// ── Address card ──────────────────────────────────────────────────────────

class _AddressCard extends StatefulWidget {
  final ImapConfig config;
  final Future<void> Function(ImapConfig) onUpdate;

  const _AddressCard({required this.config, required this.onUpdate});

  @override
  State<_AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<_AddressCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _addAddress() async {
    final addr = _ctrl.text.trim().toLowerCase();
    if (addr.isEmpty || !addr.contains('@')) return;
    if (widget.config.watchAddresses.contains(addr)) {
      _ctrl.clear();
      return;
    }
    final updated = widget.config.copyWith(
      watchAddresses: [...widget.config.watchAddresses, addr],
    );
    await widget.onUpdate(updated);
    _ctrl.clear();
  }

  Future<void> _removeAddress(String addr) async {
    final updated = widget.config.copyWith(
      watchAddresses:
          widget.config.watchAddresses.where((a) => a != addr).toList(),
    );
    await widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Überwachte Adressen',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            const Text(
              'E-Mails von/an diesen Adressen werden in die Zielordner verschoben.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'name@beispiel.at',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addAddress(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                  onPressed: _addAddress, child: const Text('Hinzufügen')),
            ]),
            if (widget.config.watchAddresses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.config.watchAddresses
                    .map((addr) => Chip(
                          label: Text(addr, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeAddress(addr),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Keyword card ──────────────────────────────────────────────────────────

class _KeywordCard extends StatefulWidget {
  final ImapConfig config;
  final Future<void> Function(ImapConfig) onUpdate;

  const _KeywordCard({required this.config, required this.onUpdate});

  @override
  State<_KeywordCard> createState() => _KeywordCardState();
}

class _KeywordCardState extends State<_KeywordCard> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _addKeyword() async {
    final kw = _ctrl.text.trim().toLowerCase();
    if (kw.isEmpty) return;
    if (widget.config.subjectKeywords.contains(kw)) {
      _ctrl.clear();
      return;
    }
    final updated = widget.config.copyWith(
      subjectKeywords: [...widget.config.subjectKeywords, kw],
    );
    await widget.onUpdate(updated);
    _ctrl.clear();
  }

  Future<void> _removeKeyword(String kw) async {
    final updated = widget.config.copyWith(
      subjectKeywords:
          widget.config.subjectKeywords.where((k) => k != kw).toList(),
    );
    await widget.onUpdate(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Betreff-Schlüsselwörter',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            const Text(
              'Mails deren Betreff ein Schlüsselwort enthält werden sortiert – '
              'auch Re:/Fwd:-Antworten im Thread.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'z. B. gurktaler, etiketten',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.none,
                  onSubmitted: (_) => _addKeyword(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                  onPressed: _addKeyword, child: const Text('Hinzufügen')),
            ]),
            if (widget.config.subjectKeywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.config.subjectKeywords
                    .map((kw) => Chip(
                          label:
                              Text(kw, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _removeKeyword(kw),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sync card ─────────────────────────────────────────────────────────────

class _SyncCard extends StatelessWidget {
  final ImapConfig config;
  final bool syncing;
  final ImapSyncResult? lastResult;
  final VoidCallback onSync;

  const _SyncCard({
    required this.config,
    required this.syncing,
    required this.lastResult,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Synchronisierung',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            if (lastResult != null) ...[
              if (lastResult!.hasError)
                _ResultRow(
                    icon: Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    text: 'Fehler: ${lastResult!.error}')
              else ...[
                _ResultRow(
                    icon: Icons.move_to_inbox_outlined,
                    color: Colors.green,
                    text:
                        '${lastResult!.movedToInbox} Mail(s) → ${config.inboxTargetFolder}'),
                _ResultRow(
                    icon: Icons.send_outlined,
                    color: Colors.green,
                    text:
                        '${lastResult!.movedToSent} Mail(s) → ${config.sentTargetFolder}'),
                if (lastResult!.activityTimestamps.isNotEmpty)
                  _ResultRow(
                      icon: Icons.access_time,
                      color: Colors.blue,
                      text:
                          '${lastResult!.activityTimestamps.length} Aktivitätszeitstempel erfasst'),
              ],
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: syncing ? null : onSync,
              icon: syncing
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              label: Text(syncing ? 'Synchronisiere…' : 'Jetzt synchronisieren'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _ResultRow(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }
}

// ── Config dialog ──────────────────────────────────────────────────────────

class _ConfigDialog extends StatefulWidget {
  final ImapConfig? existing;
  const _ConfigDialog({this.existing});

  @override
  State<_ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<_ConfigDialog> {
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _inboxCtrl;
  late final TextEditingController _sentCtrl;
  late bool _useSsl;
  bool _obscurePass = true;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _hostCtrl = TextEditingController(text: e?.host ?? '');
    _portCtrl =
        TextEditingController(text: (e?.port ?? 993).toString());
    _userCtrl = TextEditingController(text: e?.username ?? '');
    _passCtrl = TextEditingController(text: e?.password ?? '');
    _inboxCtrl =
        TextEditingController(text: e?.inboxTargetFolder ?? 'Gurktaler');
    _sentCtrl = TextEditingController(
        text: e?.sentTargetFolder ?? 'Gurktaler/Gesendet');
    _useSsl = e?.useSsl ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _hostCtrl, _portCtrl, _userCtrl, _passCtrl, _inboxCtrl, _sentCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  ImapConfig _buildConfig() => ImapConfig(
        id: widget.existing?.id ?? const Uuid().v4(),
        host: _hostCtrl.text.trim(),
        port: int.tryParse(_portCtrl.text) ?? 993,
        useSsl: _useSsl,
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        inboxTargetFolder: _inboxCtrl.text.trim().isEmpty
            ? 'Gurktaler'
            : _inboxCtrl.text.trim(),
        sentTargetFolder: _sentCtrl.text.trim().isEmpty
            ? 'Gurktaler/Gesendet'
            : _sentCtrl.text.trim(),
        watchAddresses: widget.existing?.watchAddresses ?? [],
      );

  Future<void> _testConnection() async {
    if (_hostCtrl.text.trim().isEmpty || _userCtrl.text.trim().isEmpty) return;
    setState(() => _testing = true);
    final error = await ImapService.instance.testConnection(_buildConfig());
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error == null ? 'Verbindung erfolgreich' : 'Fehler: $error'),
      backgroundColor: error == null ? Colors.green : Theme.of(context).colorScheme.error,
    ));
  }

  void _submit() {
    if (_hostCtrl.text.trim().isEmpty || _userCtrl.text.trim().isEmpty) return;
    Navigator.pop(context, _buildConfig());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null
          ? 'IMAP-Konto einrichten'
          : 'IMAP-Konto bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _hostCtrl,
              decoration: const InputDecoration(
                  labelText: 'IMAP-Server (z. B. mail.example.at)',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _portCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Port', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: SwitchListTile(
                  title: const Text('SSL'),
                  value: _useSsl,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() {
                    _useSsl = v;
                    if (v && _portCtrl.text == '143') _portCtrl.text = '993';
                    if (!v && _portCtrl.text == '993') _portCtrl.text = '143';
                  }),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                  labelText: 'Benutzername / E-Mail',
                  border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passCtrl,
              decoration: InputDecoration(
                labelText: 'Passwort',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              obscureText: _obscurePass,
            ),
            const Divider(height: 24),
            TextField(
              controller: _inboxCtrl,
              decoration: const InputDecoration(
                labelText: 'Zielordner Posteingang',
                border: OutlineInputBorder(),
                helperText: 'Wird automatisch erstellt',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _sentCtrl,
              decoration: const InputDecoration(
                labelText: 'Zielordner Gesendet',
                border: OutlineInputBorder(),
                helperText: 'Unterordner mit / trennen',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen')),
        TextButton(
          onPressed: _testing ? null : _testConnection,
          child: _testing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Testen'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Speichern')),
      ],
    );
  }
}
