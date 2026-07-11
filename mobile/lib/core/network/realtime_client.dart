import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pair/core/network/realtime_config.dart';
import 'package:pair/core/storage/token_storage.dart';

/// A realtime event received on a pod private channel.
class PodRealtimeEvent {
  const PodRealtimeEvent({
    required this.podId,
    required this.eventName,
    required this.data,
  });

  final String podId;
  final String eventName;
  final Map<String, dynamic> data;
}

class _PodSubscription {
  _PodSubscription({
    required this.channel,
    required this.controller,
    required this.messageSentSub,
    required this.userTypingSub,
    required this.authErrorSub,
  });

  final PrivateChannel channel;
  final StreamController<PodRealtimeEvent> controller;
  final StreamSubscription<ChannelReadEvent> messageSentSub;
  final StreamSubscription<ChannelReadEvent> userTypingSub;
  final StreamSubscription<ChannelReadEvent> authErrorSub;
  int refCount = 0;

  Future<void> dispose() async {
    await messageSentSub.cancel();
    await userTypingSub.cancel();
    await authErrorSub.cancel();
    channel.unsubscribe();
    await controller.close();
  }
}

/// Connects to Laravel Reverb and exposes pod channel events.
class RealtimeClient {
  RealtimeClient(this._tokenStorage);

  final TokenStore _tokenStorage;
  PusherChannelsClient? _client;
  StreamSubscription? _connectionSub;
  final Map<String, _PodSubscription> _podSubscriptions = {};
  Future<PusherChannelsClient>? _connecting;

  Future<PusherChannelsClient> _ensureClient() {
    return _connecting ??= _connect();
  }

  Future<PusherChannelsClient> _connect() async {
    if (_client != null) return _client!;

    final options = PusherChannelsOptions.fromHost(
      scheme: ReverbConfig.wsScheme,
      host: ReverbConfig.host,
      key: ReverbConfig.appKey,
      port: ReverbConfig.port,
    );

    if (kDebugMode) {
      debugPrint(
        'Realtime: connecting to ${ReverbConfig.wsScheme}://${ReverbConfig.host}:${ReverbConfig.port}',
      );
    }

    final client = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) async {
        if (kDebugMode) {
          debugPrint('Realtime: connection error: $exception');
        }
        refresh();
      },
    );

    _connectionSub = client.onConnectionEstablished.listen((_) {
      if (kDebugMode) {
        debugPrint('Realtime: connected');
      }
      for (final subscription in _podSubscriptions.values) {
        subscription.channel.subscribe();
      }
    });

    await client.connect();
    _client = client;
    return client;
  }

  String _channelName(String podId) => 'private-pod.$podId';

  /// Subscribe to realtime events for a pod.
  Future<Stream<PodRealtimeEvent>> subscribeToPod(String podId) async {
    final existing = _podSubscriptions[podId];
    if (existing != null) {
      existing.refCount++;
      return existing.controller.stream;
    }

    final client = await _ensureClient();
    final controller = StreamController<PodRealtimeEvent>.broadcast();
    final delegate = _BearerTokenAuthorizationDelegate(_tokenStorage);
    final channel = client.privateChannel(
      _channelName(podId),
      authorizationDelegate: delegate,
    );

    final messageSentSub = channel.bind('MessageSent').listen((event) {
      _emitEvent(controller, podId, 'MessageSent', event);
    });
    final userTypingSub = channel.bind('UserTyping').listen((event) {
      _emitEvent(controller, podId, 'UserTyping', event);
    });
    final authErrorSub = channel.onAuthenticationSubscriptionFailed().listen((event) {
      if (kDebugMode) {
        debugPrint(
          'Realtime: auth failed for ${_channelName(podId)}: ${event.data}',
        );
      }
    });

    final subscription = _PodSubscription(
      channel: channel,
      controller: controller,
      messageSentSub: messageSentSub,
      userTypingSub: userTypingSub,
      authErrorSub: authErrorSub,
    )..refCount = 1;

    _podSubscriptions[podId] = subscription;
    channel.subscribe();

    return controller.stream;
  }

  void _emitEvent(
    StreamController<PodRealtimeEvent> controller,
    String podId,
    String eventName,
    ChannelReadEvent event,
  ) {
    if (controller.isClosed) return;

    final data = _extractPayload(event.data);
    if (data == null) {
      if (kDebugMode) {
        debugPrint('Realtime: ignored $eventName payload: ${event.data}');
      }
      return;
    }

    controller.add(
      PodRealtimeEvent(podId: podId, eventName: eventName, data: data),
    );
  }

  Map<String, dynamic>? _extractPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('sender') ||
          raw.containsKey('body') ||
          raw.containsKey('user')) {
        return raw;
      }

      final nested = raw['data'];
      if (nested is String) {
        return _extractPayload(jsonDecode(nested));
      }
      if (nested is Map<String, dynamic>) {
        return _extractPayload(nested) ?? nested;
      }
    }

    if (raw is String && raw.isNotEmpty) {
      try {
        return _extractPayload(jsonDecode(raw));
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  Future<void> unsubscribeFromPod(String podId) async {
    final subscription = _podSubscriptions[podId];
    if (subscription == null) return;

    subscription.refCount--;
    if (subscription.refCount > 0) return;

    _podSubscriptions.remove(podId);
    await subscription.dispose();

    if (_podSubscriptions.isEmpty) {
      await _connectionSub?.cancel();
      _connectionSub = null;
      _client?.dispose();
      _client = null;
      _connecting = null;
    }
  }

  Future<void> dispose() async {
    final podIds = _podSubscriptions.keys.toList();
    for (final podId in podIds) {
      final subscription = _podSubscriptions.remove(podId);
      await subscription?.dispose();
    }
    await _connectionSub?.cancel();
    _client?.dispose();
    _client = null;
    _connecting = null;
  }
}

class _BearerTokenAuthorizationDelegate
    implements
        EndpointAuthorizableChannelAuthorizationDelegate<
            PrivateChannelAuthorizationData> {
  _BearerTokenAuthorizationDelegate(this._tokenStorage);

  final TokenStore _tokenStorage;

  @override
  EndpointAuthFailedCallback? get onAuthFailed => null;

  @override
  Future<PrivateChannelAuthorizationData> authorizationData(
    String socketId,
    String channelName,
  ) async {
    final token = await _tokenStorage.readToken();
    final uri = ReverbConfig.broadcastingAuthUri;

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
      body: {
        'socket_id': socketId,
        'channel_name': channelName,
      },
    );

    if (response.statusCode != 200) {
      if (kDebugMode) {
        debugPrint(
          'Realtime: broadcast auth failed (${response.statusCode}) '
          'for $channelName at $uri: ${response.body}',
        );
      }
      throw Exception(
        'Broadcast auth failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['auth'] is! String) {
      throw const FormatException('Invalid broadcasting auth response');
    }

    return PrivateChannelAuthorizationData(authKey: decoded['auth'] as String);
  }
}

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(ref.watch(tokenStorageProvider));
  ref.onDispose(() => client.dispose());
  return client;
});
