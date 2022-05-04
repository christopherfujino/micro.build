import 'parser.dart';

class Interpreter {
  Interpreter(this.config);

  final Config config;

  final Map<String, FunctionDecl> _registeredFunctions = <String, FunctionDecl>{
    'run': const FunctionDecl(
      name: 'run',
      statements: <Stmt>[],
    ),
    'sequence': const FunctionDecl(
      name: 'sequence',
      statements: <Stmt>[],
    ),
  };

  final Map<String, TargetDecl> _registeredTargets = <String, TargetDecl>{};

  Future<void> interpret(String targetName) async {
    // Register declarations
    _registerDeclarations();

    // interpret target
    _target(targetName);
  }

  void _target(String name) {
    // Determine target to run from [targetName]
    final TargetDecl? target = _registeredTargets[name];
    if (target == null) {
      _throwRuntimeError('There is no defined target named $name');
    }

    target.statements.forEach(_stmt);
  }

  void _stmt(Stmt stmt) {
    if (stmt is FunctionExitStmt) {
      _throwRuntimeError('Unimplemented statement type ${stmt.runtimeType}');
    }
    if (stmt is BareStmt) {
      _bareStatement(stmt);
      return;
    }
    _throwRuntimeError('Unimplemented statement type ${stmt.runtimeType}');
  }

  void _registerDeclarations() {
    for (final Decl dec in config.declarations) {
      if (dec is TargetDecl) {
        // TODO should check globally for any identifier with this name
        if (_registeredTargets.containsKey(dec.name)) {
          _throwRuntimeError('Duplicate target named ${dec.name}');
        }
        _registeredTargets[dec.name] = dec;
      } else {
        _throwRuntimeError('Unknown declaration type ${dec.runtimeType}');
      }
    }
  }

  void _bareStatement(BareStmt statement) {
    _expr(statement.expression);
  }

  _Object? _expr(Expr expr) {
    if (expr is CallExpr) {
      return _callExpr(expr);
    }
    _throwRuntimeError('Unimplemented expression type ${expr.runtimeType}');
  }

  _Object? _callExpr(CallExpr expr) {
    final FunctionDecl? func = _registeredFunctions[expr.name];
    if (func == null) {
      _throwRuntimeError('Tried to call undeclared function ${expr.name}');
    }
    for (final Stmt stmt in func.statements) {
      if (stmt is FunctionExitStmt) {
        return _expr(stmt.returnValue);
      }
      _stmt(stmt);
    }
    return null;
  }
}

class _Object {}

// TODO accept token
Never _throwRuntimeError(String message) => throw RuntimeError(message);

class RuntimeError implements Exception {
  const RuntimeError(this.message);

  final String message;

  @override
  String toString() => message;
}
