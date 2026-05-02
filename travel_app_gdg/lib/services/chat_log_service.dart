import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:travel_app_gdg/models/chat_models.dart';
import 'package:travel_app_gdg/models/ui_component.dart';

/// Sohbet satırlarını Firestore'da tutar (koleksiyon: `agent_ui_chat`).
///
/// Test modu (auth yok): depodaki [firestore.rules] — yalnızca `agent_ui_chat`
/// için read/write açık, diğer path'ler kapalı. Yayın:
/// `npx -y firebase-tools@latest deploy --only firestore:rules`
class ChatLogService {
  ChatLogService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _collection = 'agent_ui_chat';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_collection);

  Future<void> saveUserMessage(UserMessage m) async {
    await _col.add({
      'role': 'user',
      'messageId': m.id,
      'text': m.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveAgentMessage(AgentMessage m) async {
    await _col.add({
      'role': 'agent',
      'messageId': m.id,
      'text': m.text,
      'uiComponents': m.uiComponents.map((c) => c.toJson()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// `createdAt` artan sırada son [limit] mesaj.
  Future<List<Object>> loadRecent({int limit = 100}) async {
    final snap = await _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final out = <Object>[];
    for (final doc in snap.docs.reversed) {
      final data = doc.data();
      final msg = _docToMessage(data);
      if (msg != null) out.add(msg);
    }
    return out;
  }

  Object? _docToMessage(Map<String, dynamic> data) {
    final role = data['role'] as String?;
    final text = data['text'] as String? ?? '';
    final id = data['messageId'] as String? ?? '';
    final ts = data['createdAt'];
    final time = ts is Timestamp ? ts.toDate() : DateTime.now();

    switch (role) {
      case 'user':
        if (id.isEmpty) return null;
        return UserMessage(id: id, text: text, timestamp: time);
      case 'agent':
        final uiRaw = data['uiComponents'];
        final ui = _parseUiList(uiRaw);
        return AgentMessage(
          id: id.isEmpty ? docFallbackId(time) : id,
          text: text,
          uiComponents: ui,
          timestamp: time,
        );
      default:
        return null;
    }
  }

  List<UiComponent> _parseUiList(dynamic raw) {
    if (raw is! List<dynamic>) return const [];
    final list = <UiComponent>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        list.add(UiComponent.fromJson(Map<String, dynamic>.from(e)));
      } catch (err) {
        debugPrint('Firestore uiComponents satırı atlandı: $err');
      }
    }
    return list;
  }

  static String docFallbackId(DateTime t) =>
      'fs_${t.millisecondsSinceEpoch}';
}