import 'dart:convert';
import 'dart:io' as io;

import 'parser.dart';

typedef Printer = void Function(String);

class Interpreter {
  Interpreter({
    required this.config,
    required this.context,
  });

  final Config config;
  final Context context;

  final Map<String, FunctionDecl> _functionBindings = <String, FunctionDecl>{};

  final Map<String, TargetDecl> _targetBindings = <String, TargetDecl>{};

  static const Map<String, ExtFuncDecl> _externalFunctions =
      <String, ExtFuncDecl>{
    'run': RunFuncDecl(),
    'print': PrintFuncDecl(),
  };

  //visibleForOverriding
  void stdoutPrint(String msg) {
    io.stdout.writeln(msg);
  }

  //visibleForOverriding
  void stderrPrint(String msg) {
    io.stderr.writeln(msg);
  }

  Future<void> interpret(String targetName) async {
    // Register declarations
    _registerDeclarations();

    // interpret target
    await _interpretTarget(targetName, <String>{});
  }

  Future<void> _interpretTarget(String name, Set<String> visitedTargets) async {
    visitedTargets.add(name);
    // Determine target to run from [targetName]
    final TargetDecl? target = _targetBindings[name];
    if (target == null) {
      _throwRuntimeError('There is no defined target named $name');
    }

    for (final IdentifierRef dep in target.deps) {
      if (!visitedTargets.contains(dep.name)) {
        await _interpretTarget(dep.name, visitedTargets);
      }
    }

    stdoutPrint('\nExecuting target "$name"...\n');

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
    for (final Decl decl in config.declarations) {
      if (decl is TargetDecl) {
        // TODO should check globally for any identifier with this name
        if (_targetBindings.containsKey(decl.name)) {
          _throwRuntimeError('Duplicate target named ${decl.name}');
        }
        _targetBindings[decl.name] = decl;
      } else {
        _throwRuntimeError('Unknown declaration type ${decl.runtimeType}');
      }
    }
  }

  Future<void> _bareStatement(BareStmt statement) async {
    await _expr(statement.expression);
  }

  Future<Object?> _expr(Expr expr) {
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
      await func.interpret(
        argExpressions: expr.argList,
        interpreter: this,
        context: context,
      );
      return null;
    }

    final FunctionDecl? func = _functionBindings[expr.name];
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

  Future<String> _stringLiteral(StringLiteral expr) {
    return Future<String>.value(expr.value);
  }

  Future<int> runProcess({
    required List<String> command,
    io.Directory? workingDir,
  }) async {
    stdoutPrint('Running command "${command.join(' ')}"...');
    final String executable = command.first;
    final List<String> rest = command.sublist(1);
    final io.Process process = await io.Process.start(
      executable,
      rest,
      workingDirectory: workingDir?.absolute.path,
    );
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      stdoutPrint(line);
    });
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
      stderrPrint(line);
    });
    return process.exitCode;
  }

  String _castExprToString(Expr expr) {
    switch (expr.runtimeType) {
      case StringLiteral:
        return (expr as StringLiteral).value;
      case ListLiteral:
        final StringBuffer buffer = StringBuffer('[');
        buffer.write(
          (expr as ListLiteral)
              .elements
              .map<String>((Expr expr) => _castExprToString(expr))
              .join(', '),
        );
        buffer.write(']');
        return buffer.toString();
    }
    throw UnimplementedError(expr.runtimeType.toString());
  }
}

class Context {
  const Context({
    this.workingDir,
    this.env,
  });

  final io.Directory? workingDir;
  final Map<String, String>? env;
}

/// An external [FunctionDecl].
abstract class ExtFuncDecl extends FunctionDecl {
  const ExtFuncDecl({
    required super.name,
  }) : super(statements: const <Stmt>[]);

  Future<void> interpret({
    required List<Expr> argExpressions,
    required Interpreter interpreter,
    required Context context,
  });
}

class PrintFuncDecl extends ExtFuncDecl {
  const PrintFuncDecl() : super(name: 'print');

  @override
  Future<void> interpret({
    required List<Expr> argExpressions,
    required Interpreter interpreter,
    required Context context,
  }) async {
    if (argExpressions.length != 1) {
      _throwRuntimeError(
        'Function run() expected one arg, got $argExpressions',
      );
    }
    interpreter.stdoutPrint(
      interpreter._castExprToString(argExpressions.first),
    );
  }
}

class RunFuncDecl extends ExtFuncDecl {
  const RunFuncDecl() : super(name: 'run');

  @override
  Future<void> interpret({
    required List<Expr> argExpressions,
    required Interpreter interpreter,
    required Context context,
  }) async {
    if (argExpressions.length != 1) {
      _throwRuntimeError(
        'Function run() expected one arg, got $argExpressions',
      );
    }

    final Object? value = await interpreter._expr(argExpressions.first);
    final List<String> command;
    if (value is String) {
      command = value.split(' ');
    } else if (value is List<String>) {
      command = value;
    } else {
      _throwRuntimeError(
        'Function run() expected an arg of either String or List<String>, got '
        '${value.runtimeType}',
      );
    }

    final int exitCode = await interpreter.runProcess(
      command: command,
      workingDir: context.workingDir,
    );
    if (exitCode != 0) {
      _throwRuntimeError('"${command.join(' ')}" exited with code $exitCode');
    }
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
