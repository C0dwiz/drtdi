import 'package:drtdi/drtdi.dart';

class TypeUtils {
  static String getTypeName<T>() {
    return T.toString();
  }

  static bool isDisposable<T>(T instance) {
    return instance is Disposable;
  }

  static String buildRegistrationKey(Type type, [String? key]) {
    return key != null ? '$type-$key' : type.toString();
  }
}
