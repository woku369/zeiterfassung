// IMAP-Backend ist vorbereitet, aber noch nicht aktiv:
// enough_mail ^2.1.x hat einen Paket-Konflikt mit excel ^4.0.x über
// die archive-Bibliothek. Sobald einer der beiden Pakete ein Update
// liefert, kann die vollständige Implementierung hier eingehängt werden.
// Die gesamte UI (ImapScreen, Konfiguration, Adress-/Schlüsselwortlisten)
// ist bereits fertig und wartet nur auf diese Verbindungsschicht.

import '../models/imap_config.dart';

class ImapSyncResult {
  final int movedToInbox;
  final int movedToSent;
  final List<DateTime> activityTimestamps;
  final String? error;

  const ImapSyncResult({
    this.movedToInbox = 0,
    this.movedToSent = 0,
    this.activityTimestamps = const [],
    this.error,
  });

  bool get hasError => error != null;
  int get totalMoved => movedToInbox + movedToSent;
}

class ImapService {
  ImapService._();
  static final ImapService instance = ImapService._();

  static const _unavailable =
      'IMAP-Backend noch nicht aktiv (Paket-Konflikt mit excel wird aufgelöst).';

  Future<ImapSyncResult> sync(ImapConfig cfg) async =>
      const ImapSyncResult(error: _unavailable);

  Future<String?> testConnection(ImapConfig cfg) async => _unavailable;
}
