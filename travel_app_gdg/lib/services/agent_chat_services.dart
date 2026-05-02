import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'package:travel_app_gdg/models/chat_models.dart';
import 'package:travel_app_gdg/models/ui_component.dart';
import 'package:travel_app_gdg/utils/json_helper.dart';

/// Firebase AI oturumu + yanıt metninden UI bileşenlerini ayıklama.
class AgentChatService {
  late final ChatSession _chat;

  AgentChatService() {
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(
        'Sen bir seyahat ve planlama asistanısın (Türkçe). '
        'Kısa açıklama + mutlaka ```json [...] ``` ile geçerli bir dizi ver. '
        'Her nesnede "runtimeType" zorunlu. Türler:\n'
        '1) metricCard: {"runtimeType":"metricCard","label":"...","value":"...","isAlert":false}\n'
        '2) spendingChart: {"runtimeType":"spendingChart","dataPoints":[1.0,2.0],"labels":["A","B"]}\n'
        '3) actionButton: {"runtimeType":"actionButton","text":"...","actionType":"..."}\n'
        '4) tripLayout: {"runtimeType":"tripLayout","layoutType":"itinerary_viewer|budget_alert|booking_confirmation","data":{...}}\n'
        '   itinerary_viewer: data.days = [{"title":"Gün 1","items":["a","b"]}]\n'
        '   budget_alert: data.current, data.limit\n'
        '   booking_confirmation: data.booking_info = map',
      ),
    );
    _chat = model.startChat();
  }

  Future<AgentMessage> send(String prompt) async {
    final response = await _chat.sendMessage(Content.text(prompt));

    final rawContent = response.text ?? '';

    final components = _parseComponents(rawContent);

    final cleaned = _cleanText(rawContent);

    return AgentMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: cleaned.isEmpty ? 'Yanıt alınamadı.' : cleaned,
      uiComponents: components,
      timestamp: DateTime.now(),
    );
  }

  List<UiComponent> _parseComponents(String response) {
    try {
      final jsonList = JsonHelper.extractJsonList(response);
      return jsonList
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .map(_normalizeComponentJson)
          .where(_isUiComponentMap)
          .map((j) {
            try {
              return UiComponent.fromJson(j);
            } catch (e) {
              debugPrint('Bileşen parse: $e');
              return null;
            }
          })
          .whereType<UiComponent>()
          .toList();
    } catch (e) {
      debugPrint('Parse: $e');
      return [];
    }
  }

  Map<String, dynamic> _normalizeComponentJson(Map<String, dynamic> m) {
    if (!m.containsKey('runtimeType') && m.containsKey('type')) {
      return {...m, 'runtimeType': m['type']};
    }
    return m;
  }

  bool _isUiComponentMap(Map<String, dynamic> m) {
    final t = m['runtimeType'] ?? m['type'];
    return t is String && t.isNotEmpty;
  }

  String _cleanText(String text) {
    var t = text.replaceAll(
      RegExp(r'```(?:json)?\s*[\s\S]*?```', caseSensitive: false),
      '',
    );
    final list = JsonHelper.extractJsonList(text);
    if (list.isNotEmpty) {
      final slice = _findJsonArraySubstring(text);
      if (slice != null && slice.isNotEmpty) {
        t = t.replaceAll(slice, '');
      }
    }
    return t.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  String? _findJsonArraySubstring(String s) {
    final start = s.indexOf('[');
    if (start == -1) return null;
    var depth = 0;
    for (var i = start; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c == 0x5B) depth++;
      if (c == 0x5D) {
        depth--;
        if (depth == 0) return s.substring(start, i + 1);
      }
    }
    return null;
  }
}