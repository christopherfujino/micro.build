import 'dart:io' as io;

import 'package:micro_build/interpreter.dart';
import 'package:micro_build/parser.dart';
import 'package:micro_build/scanner.dart';
import 'package:micro_build/source_code.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw Exception('yolo!');
  }

  final String path = args.first;
  final io.File sourceFile = io.File(path);
  final SourceCode source = SourceCode(await sourceFile.readAsString());
  final List<Token> tokenList = await Scanner.fromSourceCode(source).scan();
  final Config config = await _parse(source, tokenList);
  await Interpreter(config).interpret('main'); // TODO parse args
}

Future<Config> _parse(SourceCode source, List<Token> tokenList) async {
  try {
    final Config config = await Parser(
      source: source,
      tokenList: tokenList,
    ).parse();
    return config;
  } on ParseError catch (err, trace) {
    io.stderr.writeln('ParseError!\n');
    io.stderr.writeln(trace);
    io.stderr.writeln(err.message);
    io.exit(1);
  }
}
