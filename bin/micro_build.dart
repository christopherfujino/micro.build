import 'dart:io' as io;

import 'package:micro_build/interpret.dart';
import 'package:micro_build/parse.dart';
import 'package:micro_build/scanner.dart';
import 'package:micro_build/source_code.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw Exception('yolo!');
  }

  final path = args.first;
  final io.File sourceFile = io.File(path);
  final SourceCode source = SourceCode(await sourceFile.readAsString());
  final List<Token> tokenList = await Scanner.fromSourceCode(source).scan();
  final Config config = await Parser(
    source: source,
    tokenList: tokenList,
  ).parse();

  await interpret(config);
}
