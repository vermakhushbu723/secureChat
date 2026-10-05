import 'dart:async';

import 'package:flutter/foundation.dart';

import '../network/api_client.dart';
import '../network/socket_service.dart';

/// One admin "Blocked Keywords" entry (word, sentence or link).
class BlockedTerm {
  BlockedTerm({required this.text, required this.type, required this.partial, required this.scope}) : _test = _compile(text, type, partial);

  factory BlockedTerm.fromJson(Map<String, dynamic> j) =>
      BlockedTerm(text: '${j['text']}', type: '${j['type'] ?? 'word'}', partial: j['partial'] == true, scope: '${j['scope'] ?? 'all'}');

  final String text;
  final String type;
  final bool partial;

  /// all | direct | groups
  final String scope;
  final bool Function(String text) _test;

  bool appliesTo(String where) => scope == 'all' || scope == where;
  bool matches(String text) => _test(text);

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _normLink(String s) => _norm(s).replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'^www\.'), '').replaceFirst(RegExp(r'/+$'), '');

  /// Same rules as the server (src/utils/blockedTerms.js).
  static bool Function(String) _compile(String text, String type, bool partial) {
    if (type == 'link') {
      final needle = _normLink(text);
      return (t) {
        if (needle.isEmpty) return false;
        final links = _norm(t).replaceAll(RegExp(r'https?://'), ' ').replaceAllMapped(RegExp(r'(^|[\s(])www\.'), (m) => m[1]!);
        return links.contains(needle);
      };
    }
    final words = _norm(text).split(' ').where((w) => w.isNotEmpty).map(RegExp.escape).toList();
    if (words.isEmpty) return (_) => false;
    final body = words.join(r'\s+');
    final re = partial ? RegExp(body, caseSensitive: false, unicode: true) : RegExp(r'(?<![\p{L}\p{N}_])' + body + r'(?![\p{L}\p{N}_])', caseSensitive: false, unicode: true);
    return re.hasMatch;
  }
}

/// Admin "Blocked Keywords": the composer disables Send while the text contains one.
/// Refreshed on every socket connect and whenever the admin changes the list.
class BlockedTerms {
  BlockedTerms._();

  static final instance = BlockedTerms._();

  /// Bumped when the list changes (composers re-check their text).
  final version = ValueNotifier<int>(0);
  List<BlockedTerm> _terms = const [];
  StreamSubscription<SocketEvent>? _sub;

  void start() {
    _sub ??= SocketService.instance.events.where((e) => e.name == 'ready' || e.name == 'blocked-terms:updated').listen((_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final data = await ApiClient.instance.get('/blocked-terms');
      final list = (data as Map)['terms'] as List? ?? const [];
      _terms = [for (final t in list) BlockedTerm.fromJson(Map<String, dynamic>.from(t as Map))];
      version.value++;
    } catch (_) {
      // Offline: keep the last list; the server still refuses blocked text.
    }
  }

  /// The blocked text found in [text] for 'direct' (1-to-1) or 'groups', or null.
  String? find(String text, String where) {
    if (text.trim().isEmpty) return null;
    for (final t in _terms) {
      if (t.appliesTo(where) && t.matches(text)) return t.text;
    }
    return null;
  }

  @visibleForTesting
  void setForTest(List<BlockedTerm> terms) {
    _terms = terms;
    version.value++;
  }
}
