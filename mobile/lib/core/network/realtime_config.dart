import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pair/core/network/api_client.dart';

const _configuredReverbAppKey = String.fromEnvironment('REVERB_APP_KEY');
const _configuredReverbHost = String.fromEnvironment('REVERB_HOST');
const _configuredReverbPort = String.fromEnvironment('REVERB_PORT');
const _configuredReverbScheme = String.fromEnvironment('REVERB_SCHEME');

abstract final class ReverbConfig {
  static String get appKey =>
      _configuredReverbAppKey.isNotEmpty ? _configuredReverbAppKey : 'pair-app-key';

  static String get host {
    if (_configuredReverbHost.isNotEmpty) return _configuredReverbHost;

    // Match the API host when only API_BASE_URL is configured (e.g. LAN testing).
    final apiHost = Uri.tryParse(apiBaseUrl)?.host;
    if (apiHost != null && apiHost.isNotEmpty) {
      return apiHost;
    }

    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  static int get port {
    if (_configuredReverbPort.isNotEmpty) {
      return int.tryParse(_configuredReverbPort) ?? 8080;
    }
    return 8080;
  }

  static String get scheme =>
      _configuredReverbScheme.isNotEmpty ? _configuredReverbScheme : 'http';

  static String get wsScheme => scheme == 'https' ? 'wss' : 'ws';

  static String get appBaseUrl {
    final api = apiBaseUrl;
    const suffix = '/api/v1';
    if (api.endsWith(suffix)) {
      return api.substring(0, api.length - suffix.length);
    }
    return api;
  }

  static Uri get broadcastingAuthUri =>
      Uri.parse('$appBaseUrl/broadcasting/auth');
}
