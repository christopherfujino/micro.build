import 'dart:io' as io;

import 'package:micro_build/interpreter.dart';

final Future<List<io.File>> buildFiles = (() async {
  if (io.Platform.isWindows) {
    throw UnimplementedError('hard-coded posix paths');
  }
  final List<io.File> buildFiles = <io.File>[];
  // package:test requires working directory to be project root
  await io.Directory('test/build_files')
      .absolute
      .list()
      .forEach((io.FileSystemEntity entity) {
    if (entity is io.File) {
      buildFiles.add(entity);
    }
  });

  return buildFiles;
})();

class TestInterpreter extends Interpreter {
  TestInterpreter({
    required super.config,
    required super.ctx,
  });

  final StringBuffer stdoutBuffer = StringBuffer();
  @override
  void stdoutPrint(String msg) {
    stdoutBuffer.writeln(msg);
  }

  final StringBuffer stderrBuffer = StringBuffer();
  @override
  void stderrPrint(String msg) {
    stderrBuffer.writeln(msg);
  }
}
