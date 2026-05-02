import 'package:cloud_functions/cloud_functions.dart';

/// Dart ile yayınlanan callable: **isimle** (`httpsCallable`) çağrılamaz.
/// Deploy çıktısındaki tam HTTPS URL gerekir → [httpsCallableFromUrl].
///
/// Kurulum:
/// 1. `npx -y firebase-tools@latest experiments:enable dartfunctions`
/// 2. `npx -y firebase-tools@latest deploy --only functions`
/// 3. Uygulama: `flutter run --dart-define=PING_DART_CALLABLE_URL=<yapıştırılan_url>`
class DemoFunctionsService {
  DemoFunctionsService({FirebaseFunctions? functions})
      : _fn = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _fn;

  /// Deploy sonrası CLI’ın verdiği callable URL (Cloud Run / functions endpoint).
  static const String _callableUrl = String.fromEnvironment(
    'PING_DART_CALLABLE_URL',
  );

  Future<Map<String, dynamic>> ping({String name = 'Flutter'}) async {
    if (_callableUrl.isEmpty) {
      throw StateError(
        'PING_DART_CALLABLE_URL tanımsız. Örnek:\n'
        'flutter run --dart-define=PING_DART_CALLABLE_URL=https://…',
      );
    }

    final callable = _fn.httpsCallableFromUrl(_callableUrl);
    final res = await callable.call(<String, dynamic>{'name': name});
    final raw = res.data;
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    throw StateError('Callable yanıtı beklenen formatta değil: $raw');
  }
}