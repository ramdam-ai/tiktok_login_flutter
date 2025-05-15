import 'dart:async';

import 'package:flutter/services.dart';

typedef AuthorizeResponse = ({String? authCode, String? codeVerifier, String? codeChallenge});

class TiktokLoginFlutter {
  static const MethodChannel _channel = MethodChannel('tiktok_login_flutter');

  static Future<bool> initializeTiktokLogin(String clientKey) async {
    return await _channel.invokeMethod('initializeTiktokLogin', clientKey);
  }

  static Future<AuthorizeResponse> authorize({required String scope, String? redirectUrl}) async {
    try {
      final result = await _channel.invokeMethod('authorize', {"scope": scope, "redirectUrl": redirectUrl});

      // Handle different response types
      if (result is Map) {
        // First, safely convert to Map<String, dynamic>
        final Map<String, dynamic> safeMap = Map<String, dynamic>.from(result.map((key, value) =>
            MapEntry(key.toString(), value)));

        // Log the data for debugging
        print('TikTok response data: $safeMap');

        // Now extract values, using empty string as fallback
        final String authCode = safeMap['authCode']?.toString() ?? '';
        final String codeVerifier = safeMap['codeVerifier']?.toString() ?? '';
        final String codeChallenge = safeMap['codeChallenge']?.toString() ?? '';

        return (
        authCode: authCode.isNotEmpty ? authCode : null,
        codeVerifier: codeVerifier.isNotEmpty ? codeVerifier : null,
        codeChallenge: codeChallenge.isNotEmpty ? codeChallenge : null
        );
      } else {
        print('Unexpected result type: ${result.runtimeType}');
        return (authCode: null, codeVerifier: null, codeChallenge: null);
      }
    } catch (e) {
      print('Error during TikTok authorization: $e');
      return (authCode: null, codeVerifier: null, codeChallenge: null);
    }
  }
}
