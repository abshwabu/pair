import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
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
  });

  final PrivateChannel channel;
  final StreamController<PodRealtimeEvent> controller;
  final StreamSubscription<ChannelReadEvent> messageSentSub;
  final StreamSubscription<ChannelReadEvent> userTypingSub;
  int refCount = 0;

  Future<void> dispose() async {
    await messageSentSub.cancel();
    await userTypingSub.cancel();
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

    final client = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) async {
        refresh();
      },
    );

    _connectionSub = client.onConnectionEstablished.listen((_) {
      for (final subscription in _podSubscriptions.values) {
        subscription.channel.subscribeIfNotUnsubscribed();
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

    final subscription = _PodSubscription(
      channel: channel,
      controller: controller,
      messageSentSub: messageSentSub,
      userTypingSub: userTypingSub,
    )..refCount = 1;

    _podSubscriptions[podId] = subscription;
    channel.subscribeIfNotUnsubscribed();

    return controller.stream;
  }

  void _emitEvent(
    StreamController<PodRealtimeEvent> controller,
    String podId,
    String eventName,
    ChannelReadEvent event,
  ) {
    if (controller.isClosed) return;

    final raw = event.data;
    Map<String, dynamic> data;
    if (raw is Map<String, dynamic>) {
      data = raw;
    } else if (raw is String) {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } else {
      return;
    }

    controller.add(
      PodRealtimeEvent(podId: podId, eventName: eventName, data: data),
    );
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
    final response = await http.post(
      ReverbConfig.broadcastingAuthUri,
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
