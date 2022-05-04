import 'dart:io' as io;

import 'parser.dart';

abstract class ExtFuncDecl extends FunctionDecl {
  const ExtFuncDecl({
    required super.name,
  }) : super(statements: const <Stmt>[]);

  Future<Object?> _interpret(
      List<Expr> argExpressions, Interpreter interpreter);
}

class RunFuncDecl extends ExtFuncDecl {
  const RunFuncDecl() : super(name: 'run');

  @override
  Future<Object?> _interpret(
      List<Expr> argExpressions, Interpreter interpreter) async {
    final List<String> args = <String>[];

    for (final Expr argExpr in argExpressions) {
      final Object? value = await interpreter._expr(argExpr);
      if (value is! String) {
        _throwRuntimeError(
            'Expected an arg of type String, got ${value.runtimeType}');
      }
      args.add(value);
    }
    final String command = args.first;
    return _runProcess(command);
  }
}

class SequenceFuncDecl extends ExtFuncDecl {
  const SequenceFuncDecl() : super(name: 'sequence');

  @override
  Future<Object?> _interpret(
      List<Expr> argExpressions, Interpreter interpreter) async {
    if (argExpressions.length != 1) {
      _throwRuntimeError('Expected one arg, got $argExpressions');
    }
    final Object? value = await interpreter._expr(argExpressions.first);
    if (value is! List<Object?>) {
      _throwRuntimeError(
        'Expected an arg of type List, got ${value.runtimeType}',
      );
    }

    for (final Object? command in value) {
      if (command is! String) {
        _throwRuntimeError('Foo bar');
      }
      final int exitCode = await _runProcess(command);
      if (exitCode != 0) {
        _throwRuntimeError('Command "$command" exited with non-zero');
      }
    }
    return null;
  }
}

Future<int> _runProcess(String command) async {
  final List<String> commandParts = command.split(' ');
  final String executable = commandParts.first;
  final List<String> rest = commandParts.sublist(1);
  final io.Process process = await io.Process.start(
    executable,
    rest,
    mode: io.ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

class Interpreter {
  Interpreter(this.config);

  final Config config;

  final Map<String, FunctionDecl> _registeredFunctions =
      <String, FunctionDecl>{};

  static const Map<String, ExtFuncDecl> _externalFunctions =
      <String, ExtFuncDecl>{
    'run': RunFuncDecl(),
    'sequence': SequenceFuncDecl(),
  };

  final Map<String, TargetDecl> _registeredTargets = <String, TargetDecl>{};

  Future<void> interpret(String targetName) async {
    // Register declarations
    _registerDeclarations();

    // interpret target
    await _target(targetName);
  }

  Future<void> _target(String name) async {
    // Determine target to run from [targetName]
    final TargetDecl? target = _registeredTargets[name];
    if (target == null) {
      _throwRuntimeError('There is no defined target named $name');
    }

    for (final Stmt stmt in target.statements) {
      await _stmt(stmt);
    }
  }

  Future<void> _stmt(Stmt stmt) async {
    if (stmt is FunctionExitStmt) {
      _throwRuntimeError('Unimplemented statement type ${stmt.runtimeType}');
    }
    if (stmt is BareStmt) {
      await _bareStatement(stmt);
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

  Future<void> _bareStatement(BareStmt statement) async {
    await _expr(statement.expression);
  }

  Future<Object?> _expr(Expr expr) async {
    if (expr is CallExpr) {
      return _callExpr(expr);
    }

    if (expr is ListLiteral) {
      return _list(expr.elements);
    }

    if (expr is StringLiteral) {
      return _stringLiteral(expr);
    }
    _throwRuntimeError('Unimplemented expression type ${expr.runtimeType}');
  }

  Future<Object?> _callExpr(CallExpr expr) async {
    if (_externalFunctions.containsKey(expr.name)) {
      final ExtFuncDecl func = _externalFunctions[expr.name]!;
      return func._interpret(expr.argList, this);
    }

    final FunctionDecl? func = _registeredFunctions[expr.name];
    if (func == null) {
      _throwRuntimeError('Tried to call undeclared function ${expr.name}');
    }
    for (final Stmt stmt in func.statements) {
      if (stmt is FunctionExitStmt) {
        return _expr(stmt.returnValue);
      }
      await _stmt(stmt);
    }
    return null;
  }

  Future<List<Object?>> _list(List<Expr> expressions) async {
    final List<Object?> elements = <Object?>[];
    for (final Expr element in expressions) {
      elements.add(await _expr(element));
    }
    return elements;
  }

  Future<String> _stringLiteral(StringLiteral expr) async {
    return expr.value;
  }
}

// TODO accept token
Never _throwRuntimeError(String message) => throw RuntimeError(message);

class RuntimeError implements Exception {
  const RuntimeError(this.message);

  final String message;

  @override
  String toString() => message;
}
