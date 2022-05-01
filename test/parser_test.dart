import 'dart:io' as io;

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

    test('can scan and parse ${buildFile.path}', () async {
      final List<Token> tokenList = await Scanner.fromSourceCode(sourceCode).scan();
      await Parser(tokenList: tokenList, source: sourceCode).parse();
    });
  }
}
