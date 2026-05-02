import 'dart:convert';

import 'package:flutter/foundation.dart';

/// AI yanıtından JSON dizi (UI bileşen listesi) çıkarma.
class JsonHelper {
  /// Önce ` ```json ... ``` ` blokları, sonra dengeli `[...]` dilimi, son çare `jsonDecode(tüm metin)`.
  static List<dynamic> extractJsonList(String response) {
    final fenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    );
    for (final m in fenced.allMatches(response)) {
      final inner = m.group(1)?.trim() ?? '';
      final list = _tryDecodeJsonArray(inner);
      if (list != null) return list;
    }

    final balanced = _extractBalancedJsonArray(response);
    if (balanced != null) return balanced;

    final whole = _tryDecodeJsonArray(response.trim());
    return whole ?? [];
  }

  static List<dynamic>? _tryDecodeJsonArray(String s) {
    if (s.isEmpty) return null;
    try {
      final decoded = jsonDecode(s);
      if (decoded is List<dynamic>) return decoded;
    } catch (e) {
      debugPrint('JsonHelper decode: $e');
    }
    return null;
  }

  /// İlk `[` ile dengeli `]` arasındaki metni `jsonDecode` dener.
  static List<dynamic>? _extractBalancedJsonArray(String s) {
    final start = s.indexOf('[');
    if (start == -1) return null;
    var depth = 0;
    for (var i = start; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c == 0x5B) depth++; // [
      if (c == 0x5D) {
        // ]
        depth--;
        if (depth == 0) {
          final slice = s.substring(start, i + 1);
          return _tryDecodeJsonArray(slice);
        }
      }
    }
    return null;
  }
}