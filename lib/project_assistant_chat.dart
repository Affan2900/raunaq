import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:raunaq/openrouter_chat_service.dart';

/// In-app assistant: optional FastAPI proxy ([FAQ_ASSISTANT_BASE_URL]), else FAQ asset +
/// OpenRouter or Firebase Callable.
/// Intended as the body of a parent [Scaffold] (no own AppBar).
class ProjectAssistantChat extends StatefulWidget {
  const ProjectAssistantChat({super.key});

  @override
  State<ProjectAssistantChat> createState() => _ProjectAssistantChatState();
}

class _ChatBubble {
  _ChatBubble({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class _ProjectAssistantChatState extends State<ProjectAssistantChat> {
  static const _primaryColor = Color(0xFF00A2FF);

  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final List<_ChatBubble> _bubbles = [];

  String _faqKnowledge = '';
  bool _loadingAsset = true;
  bool _sending = false;
  String? _assetError;
  bool _assetErrorDismissed = false;

  /// FAQ answers come from [FAQ_ASSISTANT_BASE_URL] backend; embedded FAQ optional.
  late final bool _backendConfigured;

  bool get _canCompose =>
      !_loadingAsset && (_faqKnowledge.isNotEmpty || _backendConfigured);

  @override
  void initState() {
    super.initState();
    _backendConfigured =
        dotenv.env['FAQ_ASSISTANT_BASE_URL']?.trim().isNotEmpty ?? false;
    _loadFaqAsset();
  }

  Future<void> _loadFaqAsset() async {
    try {
      final text = await rootBundle.loadString('assets/faq_knowledge.md');
      if (!mounted) return;
      setState(() {
        _faqKnowledge = text;
        _loadingAsset = false;
        _bubbles.add(
          _ChatBubble(
            text:
                'Hi! I can help you use Raunaq — navigation, profiles, admin view, '
                'and vendor chats. What would you like to know?',
            isUser: false,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingAsset = false;
        if (_backendConfigured) {
          _assetError =
              'Could not load embedded FAQ ($e). The assistant still uses your backend.';
          _bubbles.add(
            _ChatBubble(
              text:
                  'Hi! I can help you use Raunaq — navigation, profiles, admin view, '
                  'and vendor chats. What would you like to know?',
              isUser: false,
            ),
          );
        } else {
          _assetError = '$e';
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  String _buildSystemPrompt() {
    return '''
You are Raunaq's in-app helper. Answer using ONLY the FAQ knowledge below and obvious navigation hints for this Flutter app. If you are unsure, say so briefly and suggest opening Profile, Messages, or the relevant category from Home.

FAQ KNOWLEDGE:
${_faqKnowledge.isEmpty ? '(FAQ file missing)' : _faqKnowledge}
''';
  }

  List<Map<String, String>> _apiMessagesFromBubbles() {
    final out = <Map<String, String>>[];
    const maxMessages = 16;
    final relevant = _bubbles.where((b) => b.text != '…').toList();
    var start = 0;
    if (relevant.length > maxMessages) {
      start = relevant.length - maxMessages;
    }
    for (var i = start; i < relevant.length; i++) {
      final b = relevant[i];
      out.add({
        'role': b.isUser ? 'user' : 'assistant',
        'content': b.text,
      });
    }
    return out;
  }

  /// History before the current user message (for FastAPI `/chat`).
  List<Map<String, String>> _priorMessagesForProxy(String currentQuery) {
    final relevant = _bubbles.where((b) => b.text != '…').toList();
    if (relevant.isEmpty) return [];
    if (relevant.last.isUser && relevant.last.text == currentQuery) {
      relevant.removeLast();
    }
    const maxMessages = 16;
    var start = 0;
    if (relevant.length > maxMessages) {
      start = relevant.length - maxMessages;
    }
    final out = <Map<String, String>>[];
    for (var i = start; i < relevant.length; i++) {
      final b = relevant[i];
      out.add({
        'role': b.isUser ? 'user' : 'assistant',
        'content': b.text,
      });
    }
    return out;
  }

  Future<void> _send() async {
    final q = _inputController.text.trim();
    if (q.isEmpty || _loadingAsset || !_canCompose) return;

    setState(() {
      _bubbles.add(_ChatBubble(text: q, isUser: true));
      _bubbles.add(_ChatBubble(text: '…', isUser: false));
      _sending = true;
      _inputController.clear();
    });
    _scrollToBottom();

    try {
      final reply = await OpenRouterChatService.completeChat(
        currentQuery: q,
        priorMessages: _priorMessagesForProxy(q),
        systemContent: _buildSystemPrompt(),
        apiMessages: _apiMessagesFromBubbles(),
      );
      if (!mounted) return;
      setState(() {
        _bubbles.removeLast();
        _bubbles.add(_ChatBubble(text: reply, isUser: false));
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bubbles.removeLast();
        _bubbles.add(
          _ChatBubble(
            text:
                'Sorry, I could not get an answer ($e). '
                'Check FAQ_ASSISTANT_BASE_URL / device network, or set OPENROUTER_API_KEY '
                'for direct OpenRouter fallback.',
            isUser: false,
          ),
        );
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_assetError != null && !_assetErrorDismissed)
          MaterialBanner(
            content: Text('Could not load FAQ: $_assetError'),
            actions: [
              TextButton(
                onPressed: () =>
                    setState(() => _assetErrorDismissed = true),
                child: const Text('DISMISS'),
              ),
            ],
          ),
        Expanded(
          child: _loadingAsset
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _bubbles.length,
                  itemBuilder: (context, i) {
                    final b = _bubbles[i];
                    return Align(
                      alignment: b.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                        ),
                        decoration: BoxDecoration(
                          color: b.isUser
                              ? _primaryColor.withValues(alpha: 0.12)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: b.text == '…'
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                b.text,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    minLines: 1,
                    maxLines: 4,
                    enabled: _canCompose && !_sending,
                    decoration: InputDecoration(
                      hintText: 'Ask about using Raunaq…',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      !_canCompose || _sending ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
