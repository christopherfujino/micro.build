import 'dart:io' as io;

import 'package:micro_build/interpreter.dart';
import 'package:micro_build/parser.dart';
import 'package:micro_build/scanner.dart';
import 'package:micro_build/source_code.dart';
import 'package:test/test.dart';

import 'common.dart';

Future<void> main() async {
  late final io.Directory tempDir;

  setUpAll(() async {
    tempDir = await io.Directory.systemTemp.createTemp('interpreter_test');
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  test('can scan, parse and interpret git_submodule_init.build', () async {
    await io.Process.run(
      'git',
      <String>['init'],
      workingDirectory: tempDir.absolute.path,
    );
    final SourceCode sourceCode = SourceCode(
        await io.File('test/build_files/git_submodule_init.build')
            .readAsString());
    final List<Token> tokenList =
        await Scanner.fromSourceCode(sourceCode).scan();
    final Config config =
        await Parser(tokenList: tokenList, source: sourceCode).parse();
    await TestInterpreter(
      config: config,
      env: InterpreterEnv(workingDir: tempDir),
    ).interpret('main');
  });

  test('can scan, parse and interpret test.build', () async {
    final SourceCode sourceCode =
        SourceCode(await io.File('test/build_files/test.build').readAsString());
    final List<Token> tokenList =
        await Scanner.fromSourceCode(sourceCode).scan();
    final Config config =
        await Parser(tokenList: tokenList, source: sourceCode).parse();
    final TestInterpreter interpreter = TestInterpreter(
      config: config,
      env: InterpreterEnv(workingDir: tempDir),
    );
    await interpreter.interpret('main');
    expect(interpreter.stdoutBuffer.toString(), contains('hello world'));
  });

  test('comments are skipped', () async {
    final SourceCode sourceCode = SourceCode(
        await io.File('test/build_files/comments.build').readAsString());
    final List<Token> tokenList =
        await Scanner.fromSourceCode(sourceCode).scan();
    final Config config =
        await Parser(tokenList: tokenList, source: sourceCode).parse();
    final TestInterpreter interpreter = TestInterpreter(
      config: config,
      env: InterpreterEnv(workingDir: tempDir),
    );
    await interpreter.interpret('main');
    expect(interpreter.stdoutBuffer.toString().trim(), isNot(contains('hello world')));
  });

  test('interprets dependencies', () async {
    final SourceCode sourceCode = SourceCode(
        await io.File('test/build_files/dependencies.build').readAsString());
    final List<Token> tokenList =
        await Scanner.fromSourceCode(sourceCode).scan();
    final Config config =
        await Parser(tokenList: tokenList, source: sourceCode).parse();
    final TestInterpreter interpreter = TestInterpreter(
      config: config,
      env: InterpreterEnv(workingDir: tempDir),
    );
    await interpreter.interpret('main');
    expect(
      interpreter.stdoutBuffer.toString().split('\n'),
      containsAllInOrder(<String>[
        'compile',
        'test',
        'main',
      ]),
    );
  });

  test('RuntimeError if told to interpret target that does not exist',
      () async {
    final SourceCode sourceCode = SourceCode('''
target main() {
  run("echo hello world");
}
''');
    final List<Token> tokenList =
        await Scanner.fromSourceCode(sourceCode).scan();
    final Config config =
        await Parser(tokenList: tokenList, source: sourceCode).parse();
    await expectLater(
      () => TestInterpreter(
        config: config,
        env: InterpreterEnv(workingDir: tempDir),
      ).interpret('non-main'),
      throwsA(
        isA<RuntimeError>().having(
          (RuntimeError error) => error.message,
          'accurate message',
          contains('There is no defined target named non-main'),
        ),
      ),
    );
  });
}
