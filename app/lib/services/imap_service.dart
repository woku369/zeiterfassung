import 'package:enough_mail/enough_mail.dart';
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

  /// Connects, organises matching mails into target folders, then disconnects.
  Future<ImapSyncResult> sync(ImapConfig cfg) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(
        cfg.host,
        cfg.port,
        isSecure: cfg.useSsl,
      );
      await client.login(cfg.username, cfg.password);

      final timestamps = <DateTime>[];
      int movedInbox = 0;
      int movedSent = 0;

      // ── Inbox ──
      movedInbox = await _processFolder(
        client: client,
        sourceFolder: 'INBOX',
        targetFolder: cfg.inboxTargetFolder,
        watchAddresses: cfg.watchAddresses,
        matchSender: true,
        timestamps: timestamps,
      );

      // ── Sent ──
      final sentFolder = await _detectSentFolder(client);
      if (sentFolder != null) {
        movedSent = await _processFolder(
          client: client,
          sourceFolder: sentFolder,
          targetFolder: cfg.sentTargetFolder,
          watchAddresses: cfg.watchAddresses,
          matchSender: false,
          timestamps: timestamps,
        );
      }

      await client.logout();
      return ImapSyncResult(
        movedToInbox: movedInbox,
        movedToSent: movedSent,
        activityTimestamps: timestamps,
      );
    } catch (e) {
      try { await client.logout(); } catch (_) {}
      return ImapSyncResult(error: e.toString());
    }
  }

  /// Tests the connection and returns null on success, error message on failure.
  Future<String?> testConnection(ImapConfig cfg) async {
    final client = ImapClient(isLogEnabled: false);
    try {
      await client.connectToServer(cfg.host, cfg.port, isSecure: cfg.useSsl);
      await client.login(cfg.username, cfg.password);
      await client.logout();
      return null;
    } catch (e) {
      try { await client.logout(); } catch (_) {}
      return e.toString();
    }
  }

  Future<int> _processFolder({
    required ImapClient client,
    required String sourceFolder,
    required String targetFolder,
    required List<String> watchAddresses,
    required bool matchSender,
    required List<DateTime> timestamps,
  }) async {
    if (watchAddresses.isEmpty) return 0;

    await client.selectMailbox(
      await _getOrCreateMailbox(client, sourceFolder),
    );

    final lowerAddresses = watchAddresses.map((a) => a.toLowerCase()).toList();

    // Search for unseen+all messages – we check headers ourselves for flexibility.
    final fetchResult = await client.fetchAllMessages(
      fetchPreference: FetchPreference.envelope,
    );
    if (fetchResult.messages == null) return 0;

    final targetMbox = await _getOrCreateMailbox(client, targetFolder);

    int moved = 0;
    for (final msg in fetchResult.messages!) {
      if (_matchesAddress(msg, lowerAddresses, matchSender)) {
        final date = msg.envelope?.date;
        if (date != null) timestamps.add(date);

        await client.store(
          MessageSequence.fromMessage(msg),
          [MessageFlags.seen],
        );
        await client.moveMessages(
          MessageSequence.fromMessage(msg),
          targetMbox,
        );
        moved++;
      }
    }
    return moved;
  }

  bool _matchesAddress(
    MimeMessage msg,
    List<String> lowerAddresses,
    bool matchSender,
  ) {
    final addresses = matchSender
        ? (msg.envelope?.from ?? [])
        : (msg.envelope?.to ?? []) + (msg.envelope?.cc ?? []);

    return addresses.any(
      (addr) => lowerAddresses.contains(addr.email?.toLowerCase()),
    );
  }

  Future<Mailbox> _getOrCreateMailbox(
      ImapClient client, String folderName) async {
    final listResult = await client.listMailboxes();
    final existing = listResult.mailboxes?.firstWhere(
      (m) => m.name.toLowerCase() == folderName.toLowerCase(),
      orElse: () => Mailbox.setup(folderName, folderName, [MailboxFlag.noChildren]),
    );
    if (existing != null &&
        listResult.mailboxes?.any(
              (m) => m.name.toLowerCase() == folderName.toLowerCase()) ==
            true) {
      return existing;
    }
    // Create missing folder.
    await client.createMailbox(folderName);
    final after = await client.listMailboxes();
    return after.mailboxes!.firstWhere(
      (m) => m.name.toLowerCase() == folderName.toLowerCase(),
    );
  }

  Future<String?> _detectSentFolder(ImapClient client) async {
    final result = await client.listMailboxes();
    final candidates = ['Sent', 'Gesendet', 'Sent Items', 'Sent Messages', 'SENT'];
    for (final name in candidates) {
      final found = result.mailboxes?.any(
            (m) => m.name.toLowerCase() == name.toLowerCase()) ??
          false;
      if (found) return name;
    }
    // Fallback: look for mailbox with \Sent flag.
    final sentMbox = result.mailboxes?.where(
      (m) => m.flags.contains(MailboxFlag.sent)).firstOrNull;
    return sentMbox?.name;
  }
}
