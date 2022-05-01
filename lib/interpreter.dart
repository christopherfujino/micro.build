import 'parser.dart';

class Interpreter {
  Interpreter(this.config);

  final Config config;

  final Map<String, TargetDeclaration> _registeredTargets =
      <String, TargetDeclaration>{};

  Future<void> interpret(String targetName) async {
    // Register declarations
    _registerDeclarations();

    // Determine target to run from [targetName]
    final TargetDeclaration? target = _registeredTargets[targetName];
    if (target == null) {
      throw RuntimeError('There is no registered target named $targetName');
    }

    // interpret target
  }

  void _registerDeclarations() {
    for (final Declaration dec in config.declarations) {
      if (dec is TargetDeclaration) {
        // TODO should check globally for any identifier with this name
        if (_registeredTargets.containsKey(dec.name)) {
          throw RuntimeError('Duplicate target named ${dec.name}');
        }
        _registeredTargets[dec.name] = dec;
      } else {
        throw RuntimeError('Unknown declaration type ${dec.runtimeType}');
      }
    }
  }
}

class RuntimeError implements Exception {
  const RuntimeError(this.message);

  final String message;

  @override
  String toString() => message;
}
