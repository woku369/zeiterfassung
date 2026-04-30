import 'dart:convert';

class ImapConfig {
  final String id;
  final String host;
  final int port;
  final bool useSsl;
  final String username;
  final String password;
  final String inboxTargetFolder;
  final String sentTargetFolder;
  final List<String> watchAddresses;
  final List<String> subjectKeywords;
  final bool isActive;

  const ImapConfig({
    required this.id,
    required this.host,
    this.port = 993,
    this.useSsl = true,
    required this.username,
    required this.password,
    this.inboxTargetFolder = 'Gurktaler',
    this.sentTargetFolder = 'Gurktaler/Gesendet',
    this.watchAddresses = const [],
    this.subjectKeywords = const [],
    this.isActive = true,
  });

  ImapConfig copyWith({
    String? id,
    String? host,
    int? port,
    bool? useSsl,
    String? username,
    String? password,
    String? inboxTargetFolder,
    String? sentTargetFolder,
    List<String>? watchAddresses,
    List<String>? subjectKeywords,
    bool? isActive,
  }) =>
      ImapConfig(
        id: id ?? this.id,
        host: host ?? this.host,
        port: port ?? this.port,
        useSsl: useSsl ?? this.useSsl,
        username: username ?? this.username,
        password: password ?? this.password,
        inboxTargetFolder: inboxTargetFolder ?? this.inboxTargetFolder,
        sentTargetFolder: sentTargetFolder ?? this.sentTargetFolder,
        watchAddresses: watchAddresses ?? this.watchAddresses,
        subjectKeywords: subjectKeywords ?? this.subjectKeywords,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'host': host,
        'port': port,
        'use_ssl': useSsl ? 1 : 0,
        'username': username,
        'password': password,
        'inbox_target_folder': inboxTargetFolder,
        'sent_target_folder': sentTargetFolder,
        'watch_addresses': jsonEncode(watchAddresses),
        'subject_keywords': jsonEncode(subjectKeywords),
        'is_active': isActive ? 1 : 0,
      };

  factory ImapConfig.fromMap(Map<String, dynamic> m) => ImapConfig(
        id: m['id'] as String,
        host: m['host'] as String,
        port: m['port'] as int? ?? 993,
        useSsl: (m['use_ssl'] as int? ?? 1) == 1,
        username: m['username'] as String,
        password: m['password'] as String,
        inboxTargetFolder: m['inbox_target_folder'] as String? ?? 'Gurktaler',
        sentTargetFolder:
            m['sent_target_folder'] as String? ?? 'Gurktaler/Gesendet',
        watchAddresses:
            (jsonDecode(m['watch_addresses'] as String? ?? '[]') as List)
                .cast<String>(),
        subjectKeywords:
            (jsonDecode(m['subject_keywords'] as String? ?? '[]') as List)
                .cast<String>(),
        isActive: (m['is_active'] as int? ?? 1) == 1,
      );
}
