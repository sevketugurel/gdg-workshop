import 'package:flutter/material.dart';

import 'package:travel_app_gdg/models/chat_models.dart';
import 'package:travel_app_gdg/services/agent_chat_services.dart';
import 'package:travel_app_gdg/services/chat_log_service.dart';
import 'package:travel_app_gdg/services/demo_functions_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:travel_app_gdg/ui/widgets/agent_bubble.dart';
import 'package:travel_app_gdg/ui/widgets/user_bubble.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  final _service = AgentChatService();
  final _log = ChatLogService();
  final _demoFn = DemoFunctionsService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Object> _messages = [];
  bool _loading = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    // İlk kareden sonra: iOS (implicit engine) ve macOS’ta plugin kanalı hazır olsun.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    try {
      final batch = await _log.loadRecent(limit: 80);
      if (!mounted) return;
      setState(() => _messages.addAll(batch));
      _scrollDown();
    } catch (e) {
      debugPrint('Firestore geçmiş: $e');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _controller.text).trim();
    if (text.isEmpty || _loading) return;

    if (override == null) _controller.clear();

    final userMsg = UserMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _scrollDown();

    try {
      await _log.saveUserMessage(userMsg);
    } catch (e) {
      debugPrint('Firestore kullanıcı kaydı: $e');
    }

    try {
      final reply = await _service.send(text);
      if (!mounted) return;
      setState(() => _messages.add(reply));
      try {
        await _log.saveAgentMessage(reply);
      } catch (e) {
        debugPrint('Firestore ajan kaydı: $e');
      }
    } catch (e) {
      if (!mounted) return;
      final err = AgentMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Hata: $e',
        timestamp: DateTime.now(),
      );
      setState(() => _messages.add(err));
      try {
        await _log.saveAgentMessage(err);
      } catch (logErr) {
        debugPrint('Firestore hata kaydı: $logErr');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _onUiAction(String actionType, String buttonText) {
    _send('Kullanıcı "$buttonText" seçti (aksiyon: $actionType). Devam et.');
  }

  Future<void> _tryPingCloudFunction() async {
    try {
      final data = await _demoFn.ping(name: 'Dart');
      if (!mounted) return;
      final msg = data['message'] ?? '';
      final echo = data['echo'] ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Callable: $msg ($echo)')),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CF hata [${e.code}]: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seyahat asistanı'),
        actions: [
          IconButton(
            tooltip: 'Cloud Function (pingDart)',
            onPressed: _tryPingCloudFunction,
            icon: const Icon(Icons.cloud_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loadingHistory || _loading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Mesaj yazın; yanıtta metin ve kartlar gelebilir.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return switch (m) {
                        UserMessage u => UserBubble(message: u),
                        AgentMessage a =>
                          AgentBubble(message: a, onUiAction: _onUiAction),
                        _ => const SizedBox.shrink(),
                      };
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Mesaj…',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _loading ? null : () => _send(),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}