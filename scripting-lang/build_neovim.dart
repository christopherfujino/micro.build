import 'lib/utils.dart' as utils;

Future<void> main() async {
  final String neovimPath = utils.joinPath(<String>[
    utils.repoRoot.absolute.path,
    'third_party',
    'neovim',
  ]);

  await utils.stream(
    <String>['make'],
    env: <String, String>{'CMAKE_BUILD_TYPE': 'RelWithDebInfo'},
    workingDirectory: neovimPath,
  );

  utils.checkPath(
    utils.joinPath(<String>[neovimPath, 'build', 'bin', 'nvim']),
  );
}
