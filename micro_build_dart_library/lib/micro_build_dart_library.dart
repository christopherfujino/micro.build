import 'dart:io' as io;

class Path {
  final List<String> value;

  // TODO validate
  const Path(this.value);

  DateTime? get timeStamp {
    final stat = io.File(toString()).statSync();
    if (stat.type == io.FileSystemEntityType.notFound) {
      return null;
    }
    return stat.modified;
  }

  @override
  // TODO handle platform
  String toString() => value.join('/');
}

class Action {
  final Path program;
  final List<String> arguments;
  final Map<String, String> environment;

  const Action({
    required this.program,
    required this.arguments,
    this.environment = const {},
  });
}

class BuildFailure {
  final String reason;

  const BuildFailure(this.reason);

  @override
  String toString() => reason;
}

sealed class Target {
  Future<BuildFailure?> build();

  List<Path> get outputs;

  bool get needsBuild;
}

class TargetAction implements Target {
  @override
  final List<Path> outputs;
  final Set<Target> inputs;
  final String name;
  final Action action;
  // TODO encode working dir

  const TargetAction({
    required this.outputs,
    required this.inputs,
    required this.name,
    required this.action,
  });

  @override
  bool get needsBuild {
    // If any inputs need to be built, we also need to rebuild.
    if (inputs.map((input) => input.needsBuild).any((b) => b)) {
      return true;
    }
    final outputTimestamps = outputs.map((output) => output.timeStamp);
    // null means input that *must* be rebuilt
    final mostRecentInputTimestamp = inputs.fold<DateTime?>(
      DateTime(0),
      (acc, input) {
        final inputTimestamps = input.outputs.map((output) => output.timeStamp);
        for (final inputTimestamp in inputTimestamps) {
          if (inputTimestamp == null || acc == null) {
            return null;
          }
          if (inputTimestamp.isAfter(acc)) {
            acc = inputTimestamp;
          }
        }
        return acc;
      },
    );
    if (mostRecentInputTimestamp == null) {
      // we must build an input
      return true;
    }
    return outputTimestamps.any((outputTimestamp) {
      return outputTimestamp == null ||
          outputTimestamp.isBefore(mostRecentInputTimestamp);
    });
  }

  @override
  Future<BuildFailure?> build() async {
    if (!needsBuild) {
      print('$name is cached');
      return null;
    }
    final inputResults = await Future.wait(
      inputs.map((input) => input.build()),
    );
    final inputFailures = inputResults.whereType<BuildFailure>();
    if (inputFailures.isNotEmpty) {
      if (inputFailures.length == 1) {
        return inputFailures.single;
      }
      return BuildFailure(inputFailures.toString());
    }

    print('Building $name...');

    // TODO use env and working dir
    final result = await io.Process.run(
      action.program.toString(),
      action.arguments,
    );

    if (result.exitCode == 0) {
      return null;
    }

    return BuildFailure(
      '${action.program} ${action.arguments} failed with ${result.exitCode}:'
      '\n\nSTDOUT: ${result.stdout}\n\nSTDERR: ${result.stderr}',
    );
  }
}

class TargetFile implements Target {
  final Path path;

  const TargetFile(this.path);

  @override
  List<Path> get outputs => [path];

  @override
  final bool needsBuild = false;

  @override
  Future<BuildFailure?> build() async {
    if (!io.File(path.toString()).existsSync()) {
      return BuildFailure('The file $path does not exist!');
    }

    return null;
  }
}
