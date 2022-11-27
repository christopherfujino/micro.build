import 'dart:io' as io;

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

    test('can scan ${buildFile.path}', () async {
      await Scanner.fromSourceCode(sourceCode).scan();
    });
  }
}
