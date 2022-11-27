import 'package:args/command_runner.dart';

import 'package:micro_build/build.dart';

Future<void> main(List<String> args) async {
  final CommandRunner<void> runner = CommandRunner<void>(
    'micro_build',
    'A small build system for large repositories.',
    usageLineLength: 80,
  );

  runner.addCommand(BuildCommand());
  await runner.run(args);
}
