import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Calls Cloud Function [faqChat] when deployed; otherwise OpenAI directly using
/// [OPENAI_API_KEY] (development only — exposes key on web builds).
class FaqOpenAiService {
  FaqOpenAiService._();

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

    final key = dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
    if (key.isEmpty) {
      throw StateError(
        'FAQ unavailable: deploy Firebase Callable `faqChat`, or set OPENAI_API_KEY '
        'in .env for local development only (never ship API keys in web clients).',
      );
    }

    final modelEnv = dotenv.env['OPENAI_FAQ_MODEL']?.trim();
    final model = (modelEnv != null && modelEnv.isNotEmpty)
        ? modelEnv
        : 'gpt-4o-mini';

    final payload = <String, dynamic>{
      'model': model,
      'messages': <Map<String, String>>[
        {'role': 'system', 'content': systemContent},
        ...apiMessages,
      ],
    };

    final resp = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (resp.statusCode != 200) {
      throw Exception(
        'OpenAI HTTP ${resp.statusCode}: ${resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body}',
      );
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Empty choices from OpenAI');
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
