import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// FAQ assistant: FastAPI proxy ([FAQ_ASSISTANT_BASE_URL]), then Firebase Callable
/// [faqChat], then direct [OpenRouter](https://openrouter.ai/docs) with
/// [OPENROUTER_API_KEY] (dev only — unsafe on public web clients).
class OpenRouterChatService {
  OpenRouterChatService._();

  static const _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  /// Completes the user's message.
  ///
  /// When [FAQ_ASSISTANT_BASE_URL] is set, calls `POST {base}/chat` with
  /// `{"query": [currentQuery], "messages": [priorMessages]}` and reads `reply`.
  /// Otherwise uses [systemContent] + [apiMessages] for Callable / OpenRouter.
  ///
  /// [priorMessages] must exclude the current user turn (history only).
  /// [apiMessages] must include the full visible thread including the latest user
  /// message (for OpenRouter path).
  static Future<String> completeChat({
    required String currentQuery,
    required List<Map<String, String>> priorMessages,
    required String systemContent,
    required List<Map<String, String>> apiMessages,
  }) async {
    final base = dotenv.env['FAQ_ASSISTANT_BASE_URL']?.trim() ?? '';
    if (base.isNotEmpty) {
      return _completeViaProxy(base, currentQuery, priorMessages);
    }

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
        'Assistant unavailable: set FAQ_ASSISTANT_BASE_URL, or deploy Firebase '
        'Callable `faqChat`, or set OPENROUTER_API_KEY in .env for local dev '
        '(never ship API keys in web clients).',
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

  static String _normalizeBaseUrl(String base) {
    var b = base.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return b;
  }

  static Future<String> _completeViaProxy(
    String base,
    String currentQuery,
    List<Map<String, String>> priorMessages,
  ) async {
    final url = Uri.parse('${_normalizeBaseUrl(base)}/chat');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      // Avoid ngrok HTML interstitial on programmatic requests.
      'ngrok-skip-browser-warning': '1',
    };
    final apiKey = dotenv.env['FAQ_ASSISTANT_API_KEY']?.trim() ?? '';
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final payload = <String, dynamic>{
      'query': currentQuery.trim(),
      'messages': priorMessages,
    };

    final resp = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'FAQ backend HTTP ${resp.statusCode}: '
        '${resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body}',
      );
    }

    final json = jsonDecode(resp.body);
    if (json is! Map<String, dynamic>) {
      throw Exception('Unexpected FAQ backend response');
    }
    final reply = json['reply'];
    if (reply is String && reply.trim().isNotEmpty) {
      return reply.trim();
    }
    throw Exception('FAQ backend returned no reply');
  }
}
