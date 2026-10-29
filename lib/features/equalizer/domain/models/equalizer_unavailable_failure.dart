import 'package:pulso/shared/base_domain/error/failures.dart';

/// Fallo cuando el dispositivo o la plataforma no ofrece ecualizador.
class EqualizerUnavailableFailure extends Failure {
  const EqualizerUnavailableFailure(super.message, {super.cause});
}
