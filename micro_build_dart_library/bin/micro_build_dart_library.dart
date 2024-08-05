import 'package:micro_build_dart_library/micro_build_dart_library.dart';

Future<void> main(List<String> arguments) async {
  const aDotO = TargetAction(
    name: 'a.o',
    outputs: [
      Path(['a.o'])
    ],
    inputs: {
      TargetFile(Path(['a.c'])),
      TargetFile(Path(['c.h'])),
    },
    action: Action(
      program: Path(['clang']),
      // -c means compile only
      arguments: ['a.c', '-c', '-o', 'a.o'],
    ),
  );
  const bDotO = TargetAction(
    name: 'b.o',
    outputs: [
      Path(['b.o'])
    ],
    inputs: {
      TargetFile(Path(['b.c'])),
      TargetFile(Path(['c.h'])),
    },
    action: Action(
      program: Path(['clang']),
      arguments: ['b.c', '-c', '-o', 'b.o'],
    ),
  );
  const aOut = TargetAction(
    name: 'a.out',
    outputs: [
      Path(['a.out'])
    ],
    inputs: {
      aDotO,
      bDotO,
    },
    action: Action(
      program: Path(['clang']),
      arguments: ['a.c', 'b.c', '-o', 'a.out'],
    ),
  );

  print(await aOut.build());
}
