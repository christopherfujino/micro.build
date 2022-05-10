import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

import 'interpreter.dart';
import 'parser.dart';
import 'scanner.dart';
import 'source_code.dart';

const String kSourceFileName = 'micro.build';

class BuildCommand extends Command<void> {
  @override
  String name = 'build';

  @override
  String description = 'Run a micro.build build file.';

  ArgResults get _argResults => argResults!;

  @override
  Future<void> run() async {
    final String target;
    if (_argResults.rest.length > 1) {
      throw Exception('Pass one argument as a target.');
    }
    if (_argResults.rest.length == 1) {
      target = _argResults.rest.first;
    } else {
      target = 'main';
    }
    final io.Directory workingDir = io.Directory.current.absolute;
    final io.File sourceFile = io.File(<String>[
      workingDir.path,
      kSourceFileName,
    ].join(io.Platform.pathSeparator));
    final Context context = Context(workingDir: workingDir);

    if (!sourceFile.existsSync()) {
      throw RuntimeError(
        'No build file was specified, and no $kSourceFileName file found in '
        '${workingDir.path}',
      );
    }
    final SourceCode source = SourceCode(await sourceFile.readAsString());

    final List<Token> tokenList = await Scanner.fromSourceCode(source).scan();

    final Config config = await _parse(source, tokenList);

    await Interpreter(
      config: config,
      context: context,
    ).interpret(target);
  }
}

Future<Config> _parse(SourceCode source, List<Token> tokenList) async {
  try {
    final Config config = await Parser(
      source: source,
      tokenList: tokenList,
    ).parse();
    return config;
  } on ParseError catch (err, trace) {
    // catch so we can better format error message
    io.stderr.writeln('ParseError!\n');
    io.stderr.writeln(trace);
    io.stderr.writeln(err.message);
    io.exit(1);
  }
}
