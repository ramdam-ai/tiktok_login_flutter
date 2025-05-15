import 'dart:async';

import 'package:flutter/services.dart';

typedef AuthorizeResponse = ({String? authCode, String? codeVerifier, String? codeChallenge});

class TiktokLoginFlutter {
  static const MethodChannel _channel = MethodChannel('tiktok_login_flutter');

  static Future<bool> initializeTiktokLogin(String clientKey) async {
    return await _channel.invokeMethod('initializeTiktokLogin', clientKey);
  }

  static Future<AuthorizeResponse> authorize({required String scope, String? redirectUrl}) async {
    final Map<String, dynamic> authResult =
        await _channel.invokeMethod('authorize', {"scope": scope, "redirectUrl": redirectUrl});
    final String authCode = authResult['authCode'];
    final String codeVerifier = authResult['codeVerifier'];
    final String codeChallenge = authResult['codeChallenge'];
    return (authCode: authCode, codeVerifier: codeVerifier, codeChallenge: codeChallenge);
  }
}
