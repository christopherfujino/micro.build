import 'dart:io' as io;

import 'package:micro_build/interpreter.dart';
import 'package:micro_build/parser.dart';
import 'package:micro_build/scanner.dart';
import 'package:micro_build/source_code.dart';
import 'package:test/test.dart';

import 'common.dart';

Future<void> main() async {
  for (final io.File buildFile in await buildFiles) {
    late final SourceCode sourceCode;
    setUpAll(() async {
      sourceCode = SourceCode(await buildFile.readAsString());
    });

    test('can scan, parse and interpret ${buildFile.path}', () async {
      final List<Token> tokenList =
          await Scanner.fromSourceCode(sourceCode).scan();
      final Config config =
          await Parser(tokenList: tokenList, source: sourceCode).parse();
      await Interpreter(config).interpret('main');
    });
  }

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
      () => Interpreter(config).interpret('non-main'),
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
