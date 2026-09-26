import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart';
import 'api_config.dart';
import 'auth_service.dart';

class SocketEvent {
  const SocketEvent(this.name, this.data);

  final String name;
  final Map<String, dynamic> data;
}

/// Single realtime connection shared by the whole app.
///
/// Server events are re-published on [events]; `ready` fires after every
/// (re)connect so screens can re-sync what they missed while offline.
class SocketService {
  SocketService._();

  static final instance = SocketService._();

  static const serverEvents = [
    'ready',
    'message:new',
    'message:updated',
    'message:removed',
    'message:status',
    'typing',
    'presence',
    'conversation:updated',
    'conversation:read',
    'conversation:cleared',
    'conversation:removed',
    'user:updated',
    'user:blocked',
    // Groups
    'group:message:new',
    'group:message:updated',
    'group:message:removed',
    'group:status',
    'group:typing',
    'group:read',
    'group:updated',
    'group:me',
    'group:cleared',
    'group:joined',
    'group:removed',
    'group:member:joined',
    'group:member:left',
    'group:member:updated',
    'group:join_request',
    'group:request:declined',
    'group:location',
  ];

  io.Socket? _socket;
  final connected = ValueNotifier<bool>(false);
  final _events = StreamController<SocketEvent>.broadcast();

  Stream<SocketEvent> get events => _events.stream;

  Stream<Map<String, dynamic>> on(String name) => events.where((e) => e.name == name).map((e) => e.data);

  void connect() {
    final token = AuthService.instance.accessToken;
    if (token == null) return;
    final existing = _socket;
    if (existing != null) {
      existing.auth = {'token': token};
      if (!existing.connected) existing.connect();
      return;
    }

    final socket = io.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'forceNew': true,
      'auth': {'token': token},
      'reconnection': true,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 10000,
    });
    socket
      ..onConnect((_) => connected.value = true)
      ..onDisconnect((_) => connected.value = false)
      ..onConnectError((err) => _onConnectError(socket, err));
    for (final name in serverEvents) {
      socket.on(name, (data) => _events.add(SocketEvent(name, _asMap(data))));
    }
    _socket = socket..connect();
  }

  Future<void> _onConnectError(io.Socket socket, dynamic err) async {
    connected.value = false;
    // Expired access token: rotate it and reconnect with the new one.
    if ('$err'.contains('UNAUTHORIZED') && await AuthService.instance.refresh()) {
      socket
        ..auth = {'token': AuthService.instance.accessToken}
        ..connect();
    }
  }

  /// Emits with acknowledgement. Resolves with `data`, throws [ApiException].
  Future<dynamic> request(
    String event,
    Map<String, dynamic> payload, {
    Duration timeout = const Duration(seconds: 12),
  }) {
    final socket = _socket;
    if (socket == null || !socket.connected) {
      return Future.error(const ApiException(code: 'OFFLINE', message: 'You are offline'));
    }
    final completer = Completer<dynamic>();
    socket.emitWithAck(
      event,
      payload,
      ack: (dynamic res) {
        if (completer.isCompleted) return;
        final map = _asMap(res);
        map['ok'] == true
            ? completer.complete(map['data'])
            : completer.completeError(ApiException.fromMap(map['error']));
      },
    );
    return completer.future.timeout(
      timeout,
      onTimeout: () => throw const ApiException(code: 'TIMEOUT', message: 'No response from server'),
    );
  }

  /// Fire-and-forget (typing indicators, receipts).
  void emit(String event, Map<String, dynamic> payload) {
    if (_socket?.connected ?? false) _socket!.emit(event, payload);
  }

  void disconnect() {
    _socket
      ?..clearListeners()
      ..dispose();
    _socket = null;
    connected.value = false;
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty && data.first is Map) return Map<String, dynamic>.from(data.first as Map);
    return const {};
  }
}
