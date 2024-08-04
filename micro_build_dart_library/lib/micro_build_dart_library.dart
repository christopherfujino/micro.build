import 'dart:io' as io;

class Path {
  final List<String> value;

  // TODO validate
  const Path(this.value);

  DateTime get timeStamp => io.File(toString()).statSync().modified;

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
}

sealed class Target {
  Future<BuildFailure?> build();

  List<Path> get outputs;
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

  bool get _needsBuild {
    final outputTimestamps = outputs.map((output) => output.timeStamp);
    final mostRecentInputTimestamp = inputs.fold<DateTime>(
      DateTime(0),
      (acc, input) {
        final inputTimestamps = input.outputs.map((output) => output.timeStamp);
        for (final inputTimestamp in inputTimestamps) {
          if (inputTimestamp.isAfter(acc)) {
            acc = inputTimestamp;
          }
        }
        return acc;
      },
    );
    return outputTimestamps.any((outputTimestamp) => outputTimestamp.isBefore(mostRecentInputTimestamp));
  }

  @override
  Future<BuildFailure?> build() async {
    if (!_needsBuild) {
      print('$name is cached');
      return null;
    }
    final inputResults = await Future.wait(
      inputs.map((input) => input.build()),
    );
    final inputFailures = inputResults.whereType<BuildFailure>();
    if (inputFailures.isNotEmpty) {
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
        '${action.program} ${action.arguments} failed with ${result.exitCode}');
  }
}

class TargetFile implements Target {
  final Path path;

  const TargetFile(this.path);

  @override
  List<Path> get outputs => [path];

  @override
  Future<BuildFailure?> build() => Future<BuildFailure?>.value(null);
}
