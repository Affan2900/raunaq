import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Chat completions via [OpenRouter](https://openrouter.ai/docs).
///
/// Tries Firebase Callable [faqChat] first when deployed; otherwise calls
/// OpenRouter directly using [OPENROUTER_API_KEY] (development only — unsafe on
/// public web builds; prefer a backend or Callable in production).
class OpenRouterChatService {
  OpenRouterChatService._();

  static const _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// [apiMessages] must be alternating user/assistant turns (no system message).
  static Future<String> completeChat({
    required String systemContent,
    required List<Map<String, String>> apiMessages,
  }) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        app: Firebase.app(),
        region: 'us-central1',
      ).httpsCallable('faqChat');
      final result = await callable.call(<String, dynamic>{
        'system': systemContent,
        'messages': apiMessages,
      });
      final data = result.data;
      if (data is Map) {
        final reply = data['reply'];
        if (reply is String && reply.trim().isNotEmpty) {
          return reply.trim();
        }
      }
    } catch (_) {
      // Callable not deployed or wrong region — fall through.
    }

    final key = dotenv.env['OPENROUTER_API_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      throw StateError(
        'Assistant unavailable: deploy Firebase Callable `faqChat`, or set '
        'OPENROUTER_API_KEY in .env for local development only (never ship API '
        'keys in web clients).',
      );
    }

    final modelEnv = dotenv.env['OPENROUTER_MODEL']?.trim();
    final model = (modelEnv != null && modelEnv.isNotEmpty)
        ? modelEnv
        : 'openai/gpt-4o-mini';

    final payload = <String, dynamic>{
      'model': model,
      'messages': <Map<String, String>>[
        {'role': 'system', 'content': systemContent},
        ...apiMessages,
      ],
    };

    final headers = <String, String>{
      'Authorization': 'Bearer $key',
      'Content-Type': 'application/json',
    };
    final referer = dotenv.env['OPENROUTER_HTTP_REFERER']?.trim();
    if (referer != null && referer.isNotEmpty) {
      headers['HTTP-Referer'] = referer;
    }
    final appName = dotenv.env['OPENROUTER_APP_NAME']?.trim();
    if (appName != null && appName.isNotEmpty) {
      headers['X-Title'] = appName;
    }

    final resp = await http.post(
      Uri.parse(_openRouterUrl),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'OpenRouter HTTP ${resp.statusCode}: '
        '${resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body}',
      );
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty choices from OpenRouter');
    }
    final msg = choices.first as Map<String, dynamic>;
    final message = msg['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('Empty assistant content');
    }
    return content.trim();
  }
}
