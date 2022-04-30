import 'lib/utils.dart';

Future<void> main() async {
  await sequence([
    'git submodule init',
    'git submodule update',
  ]);
}
