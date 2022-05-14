import 'dart:convert';
import 'dart:io' as io;

import 'parser.dart';

typedef Printer = void Function(String);

class Interpreter {
  Interpreter({
    required this.config,
    required this.ctx,
  });

  final Config config;
  final Context ctx;

  final Map<String, FuncDecl> _functionBindings = <String, FuncDecl>{};

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
    await _interpretTarget(targetName, <String>{}, ctx);
  }

  Future<void> _interpretTarget(
    String name,
    Set<String> visitedTargets,
    Context ctx,
  ) async {
    visitedTargets.add(name);
    // Determine target to run from [targetName]
    final TargetDecl? target = _targetBindings[name];
    if (target == null) {
      _throwRuntimeError('There is no defined target named $name');
    }

    ConstDecl? deps;
    FuncDecl? buildFunc;

    for (final Decl decl in target.declarations) {
      if (decl is ConstDecl && decl.name == 'deps') {
        deps = decl;
        continue;
      }
      if (decl is FuncDecl && decl.name == 'build') {
        buildFunc = decl;
        continue;
      }
    }

    if (buildFunc == null) {
      _throwRuntimeError(
        'Target named "${target.name}" does not define a "build()" function',
      );
    }

    // Find hooks
    final Iterable<Decl> depsIterable = target.declarations.where((Decl decl) {
      return decl is ConstDecl && decl.name == 'deps';
    });

    if (depsIterable.length > 1) {
      _throwRuntimeError('More than one declaration of "deps"');
    }

    if (deps != null) {
      final Object? depsValue = await _expr(deps.initialValue, ctx);
      if (depsValue is! List<Object?>) {
        _throwRuntimeError('"deps" constant must be a list of target names');
      }

      for (final Object? dep in depsValue) {
        final TargetDecl targetDep = dep! as TargetDecl;
        if (!visitedTargets.contains(targetDep.name)) {
          await _interpretTarget(targetDep.name, visitedTargets, ctx);
        }
      }
    }

    stdoutPrint('\nExecuting target "$name"...\n');

    await _executeFunc(buildFunc, ctx);
  }

  Future<void> _stmt(Stmt stmt, Context ctx) async {
    if (stmt is FunctionExitStmt) {
      _throwRuntimeError('Unimplemented statement type ${stmt.runtimeType}');
    }
    if (stmt is BareStmt) {
      await _bareStatement(stmt, ctx);
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

  Future<void> _bareStatement(BareStmt statement, Context ctx) async {
    await _expr(statement.expression, ctx);
  }

  Future<Object?> _expr(Expr expr, Context ctx) {
    if (expr is CallExpr) {
      return _callExpr(expr, ctx);
    }

    if (expr is ListLiteral) {
      return _list(expr.elements, ctx);
    }

    if (expr is StringLiteral) {
      return _stringLiteral(expr);
    }

    if (expr is IdentifierRef) {
      return _resolveIdentifier(expr, ctx);
    }
    _throwRuntimeError('Unimplemented expression type $expr');
  }

  Future<Object?> _callExpr(CallExpr expr, Context ctx) async {
    if (_externalFunctions.containsKey(expr.name)) {
      final ExtFuncDecl func = _externalFunctions[expr.name]!;
      await func.interpret(
        argExpressions: expr.argList,
        interpreter: this,
        ctx: ctx,
      );
      return null;
    }

    final FuncDecl? func = _functionBindings[expr.name];
    if (func == null) {
      _throwRuntimeError('Tried to call undeclared function ${expr.name}');
    }

    return _executeFunc(func, ctx);
  }

  Future<Object?> _executeFunc(FuncDecl func, Context ctx) async {
    for (final Stmt stmt in func.statements) {
      if (stmt is FunctionExitStmt) {
        return _expr(stmt.returnValue, ctx);
      }
      await _stmt(stmt, ctx);
    }
    return null;
  }

  Future<Object?> _resolveIdentifier(
      IdentifierRef identifier, Context ctx) async {
    if (_targetBindings.containsKey(identifier.name)) {
      return _targetBindings[identifier.name]!;
    }
    throw UnimplementedError(
        "Don't know how to resolve identifier ${identifier.name}");
  }

  Future<List<Object?>> _list(List<Expr> expressions, Context ctx) async {
    final List<Object?> elements = <Object?>[];
    for (final Expr element in expressions) {
      elements.add(await _expr(element, ctx));
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
    this.parent,
  });

  final io.Directory? workingDir;
  final Map<String, String>? env;
  final Context? parent;
}

/// An external [FunctionDecl].
abstract class ExtFuncDecl extends FuncDecl {
  const ExtFuncDecl({
    required super.name,
    required super.params,
  }) : super(statements: const <Stmt>[]);

  Future<void> interpret({
    required List<Expr> argExpressions,
    required Interpreter interpreter,
    required Context ctx,
  });
}

class PrintFuncDecl extends ExtFuncDecl {
  const PrintFuncDecl()
      : super(
          name: 'print',
          params: const <IdentifierRef>[IdentifierRef('msg')],
        );

  @override
  Future<void> interpret({
    required List<Expr> argExpressions,
    required Interpreter interpreter,
    required Context ctx,
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
  const RunFuncDecl()
      : super(
          name: 'run',
          params: const <IdentifierRef>[IdentifierRef('command')],
        );

  @override
  Future<void> interpret({
    required List<Expr> argExpressions,
    required Interpreter interpreter,
    required Context ctx,
  }) async {
    if (argExpressions.length != 1) {
      _throwRuntimeError(
        'Function run() expected one arg, got $argExpressions',
      );
    }

    final Object? value = await interpreter._expr(argExpressions.first, ctx);
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
      workingDir: ctx.workingDir,
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
