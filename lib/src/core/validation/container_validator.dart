import '../../exceptions/di_exceptions.dart';
import '../container/di_container.dart';

class ContainerValidator {
  static void validate(DIContainer container) {
    final errors = <String>[];

    for (final entry in container.registrationsMap.entries) {
      final type = entry.key;
      final registrationsByKey = entry.value;

      for (final registrationEntry in registrationsByKey.entries) {
        final key = registrationEntry.key;
        final registration = registrationEntry.value;

        try {
          registration.resolve(container);
        } catch (e) {
          final keyDescription = key.isEmpty ? '' : " with key '$key'";
          errors.add('$type$keyDescription: $e');
        }
      }
    }

    if (errors.isNotEmpty) {
      throw DIException('Container validation failed:\n${errors.join('\n')}');
    }
  }
}
