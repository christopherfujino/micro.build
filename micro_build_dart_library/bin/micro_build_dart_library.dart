import 'package:micro_build_dart_library/micro_build_dart_library.dart';

Future<void> main(List<String> arguments) async {
  const aOut = TargetAction(
    name: 'a.out',
    outputs: [Path(['a.out'])],
    inputs: {TargetFile(Path(['a.c'])), TargetFile(Path(['b.c'])), TargetFile(Path(['c.h']))},
    action: Action(program: Path(['clang']), arguments: ['a.c', 'b.c', '-o', 'a.out'])
  );

  print(await aOut.build());
}
