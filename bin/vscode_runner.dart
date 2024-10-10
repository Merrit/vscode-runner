import 'dart:async';
import 'dart:io';

import 'package:krunner/krunner.dart';
import 'package:vscode_runner/database.dart';
import 'package:vscode_runner/enums/enums.dart';
import 'package:vscode_runner/logs/logging_manager.dart';
import 'package:vscode_runner/vscode.dart';

Future<void> main(List<String> arguments) async {
  await checkIfAlreadyRunning();
  await LoggingManager.initialize(verbose: true);

  log.i('Starting VSCode runner.');

  final bool vscodeExists = await _executableExists('code');
  if (vscodeExists) {
    _vscodeInstances.add(VSCode(
      VSCodeVersion.stable,
      database: VSCodeDatabase(DatabaseFilePath.stable),
    ));
  }

  final bool vscodeInsidersExists = await _executableExists('code-insiders');
  if (vscodeInsidersExists) {
    _vscodeInstances.add(VSCode(
      VSCodeVersion.insiders,
      database: VSCodeDatabase(DatabaseFilePath.insiders),
    ));
  }

  final bool codiumExists = await _executableExists('codium');
  if (codiumExists) {
    _vscodeInstances.add(VSCode(
      VSCodeVersion.codium,
      database: VSCodeDatabase(DatabaseFilePath.codium),
    ));
  }

  if (_vscodeInstances.isEmpty) {
    log.e('Unable to find any instances of VSCode. '
        'Please make sure at least one is installed and on your PATH.\n'
        'e.g. `which code` or `which code-insiders`');
    exit(1);
  }

  final runner = KRunnerPlugin(
    identifier: 'codes.merritt.vscode_runner',
    name: '/vscode_runner',
    matchQuery: _debouncedMatchQuery,
    retrieveActions: retrieveActions,
    runAction: runAction,
  );

  await runner.init();
}

/// A list of all instances of VSCode detected on the system.
List<VSCode> _vscodeInstances = [];

/// Check if an instance of this plugin is already running.
///
/// If we don't check KRunner will just launch a new instance every time.
Future<void> checkIfAlreadyRunning() async {
  final result = await Process.run('pidof', ['vscode_runner']);
  final hasError = result.stderr != '';
  if (hasError) {
    print('Issue checking for existing process: ${result.stderr}');
    return;
  }
  final output = result.stdout as String;
  final runningInstanceCount = output.trim().split(' ').length;
  if (runningInstanceCount != 1) {
    print('An instance of vscode_runner appears to already be running. '
        'Aborting run of new instance.');
    exit(0);
  }
}

/// Checks if [executable] exists on the system.
Future<bool> _executableExists(String executable) async {
  final result = await Process.run('which', [executable]);
  final hasError = result.stderr != '';

  if (hasError) {
    log.e('Unable to locate code executable: ${result.stderr}');
    return false;
  }

  final output = result.stdout as String;
  final path = output.trim();
  log.i('Found VSCode executable at $path');
  return true;
}

/// A timer that is used to debounce the query.
Timer? _debounceTimer;

/// The amount of time to wait before running the query.
const _debounceTime = Duration(milliseconds: 500);

/// A completer that is used to complete the query.
///
/// The Completer is kept outside of the [_debouncedMatchQuery] function so that
/// we can be sure that a previous query is cancelled before starting a new one.
Completer<List<QueryMatch>>? _completer;

/// Debounces the query.
///
/// If the user is typing, we don't want to run the query for every keystroke or
/// we will run into performance issues.
///
/// Instead, we wait until the user has stopped typing for a short period of
/// time, and then run the query.
Future<List<QueryMatch>> _debouncedMatchQuery(String query) async {
  _debounceTimer?.cancel();

  if (_completer == null || _completer!.isCompleted) {
    _completer = Completer();
  }

  _debounceTimer = Timer(_debounceTime, () async {
    try {
      final matches = await matchQuery(query);
      _completer!.complete(matches);
    } catch (e) {
      _completer!.completeError(e);
    }
  });
  return _completer!.future;
}

/// Returns a list of [QueryMatch]es for the given [query].
Future<List<QueryMatch>> matchQuery(String query) async {
  log.i('Running query for: $query');

  final List<QueryMatch> matches = [];

  for (final instance in _vscodeInstances) {
    final instanceMatches = _getMatchesFor(query, instance.version);
    log.i(
      'Found ${instanceMatches.length} matches for ${instance.version}.',
    );
    matches.addAll(instanceMatches);
  }

  return matches;
}

/// Returns a list of [QueryMatch]es for the given [query], for the version of
/// VSCode specified by [vscodeVersion].
List<QueryMatch> _getMatchesFor(String query, VSCodeVersion vscodeVersion) {
  final vscode = _vscodeInstances.firstWhere((e) => e.version == vscodeVersion);
  final recentWorkspacePaths = List<String>.from(vscode.recentWorkspacePaths);
  final regex = RegExp(query, caseSensitive: false);
  recentWorkspacePaths.removeWhere((element) => !regex.hasMatch(element));
  if (recentWorkspacePaths.isEmpty) return [];
  final matches = _workspacePathsToQueryMatches(
    recentWorkspacePaths,
    vscodeVersion,
  );
  return matches;
}

/// Converts a list of workspace paths into a list of [QueryMatch]es.
List<QueryMatch> _workspacePathsToQueryMatches(
  List<String> recentWorkspacePaths,

  /// The version of VSCode that the paths are from. This is used to determine
  /// which icon to use.
  VSCodeVersion vscodeVersion,
) {
  final icon = vscodeIconNameFor(vscodeVersion);

  final matches = recentWorkspacePaths.map((path) {
    final uri = pathToUri(path);
    final relativePath = parseRelativePath(uri);
    final projectName = path.split('/').last;

    final String idPrefix;
    switch (vscodeVersion) {
      case VSCodeVersion.codium:
        idPrefix = 'codium';
        break;
      case VSCodeVersion.insiders:
        idPrefix = 'insiders';
        break;
      case VSCodeVersion.stable:
        idPrefix = 'stable';
        break;
    }

    final id = '$idPrefix-$path';

    log.i('Found match: $id');

    return QueryMatch(
      id: id, // id is the raw folderUri starting with file:// or vscode-remote://
      title: projectName,
      icon: icon,
      rating: QueryMatchRating.exact,
      relevance: 1.0,
      properties: QueryMatchProperties(subtitle: relativePath ?? uri.path),
    );
  }).toList();

  return matches;
}

Uri pathToUri(String path) {
  // Remove the leading "file://" or "vscode-remote://"
  final trimmed = path
      .replaceFirst('file://', '') //
      .replaceFirst('vscode-remote://', '');
  final uri = Uri.directory(trimmed);
  return uri;
}

String? parseRelativePath(Uri uri) {
  var homeDir = Process.runSync('xdg-user-dir', []).stdout as String;
  homeDir = homeDir.trim();
  final pathIsUnderHome = uri.path.contains(homeDir);
  if (pathIsUnderHome) {
    // If the path is under the user's home directory, we return
    // the relative path so that the subtitle in KRunner can be a shorter
    // path that will fit better in limited space, eg:
    // `~/Development/project` rather than `/home/user/Development/project`.
    final withoutHomePrefix = uri.path.substring(homeDir.length);
    final relativePath = '~$withoutHomePrefix';
    return relativePath;
  } else {
    return null;
  }
}

Future<List<SecondaryAction>> retrieveActions() async {
  return [
    SecondaryAction(
      id: 'openContainingFolder',
      text: 'Open Containing Folder',
      icon: 'document-open-folder',
    ),
  ];
}

Future<void> runAction({
  required String actionId,
  required String matchId,
}) async {
  log.i('Running action. actionId: $actionId, matchId: $matchId');

  final matchPrefix = matchId.split('-').first;
  final vscodeVersion = VSCodeVersion.values.byName(matchPrefix);
  final path = matchId.replaceFirst('$matchPrefix-', '');

  final isOpenFolderRequest = (actionId == "openContainingFolder") //
      ? true
      : false;

  if (isOpenFolderRequest) {
    openContainingFolder(path);
  } else {
    openWorkspace(path, vscodeVersion);
  }
}

Future<void> openWorkspace(String uri, VSCodeVersion vscodeVersion) async {
  log.i('Opening workspace at $uri with $vscodeVersion');

  final executable = vscodeExecutableFor(vscodeVersion);

  /// Pass the raw uri with `--folder-uri` and VSCode will handle it.
  // see https://stackoverflow.com/questions/60144074/how-to-open-a-remote-folder-from-command-line-in-vs-code
  await Process.run(executable, ['--folder-uri=$uri']);
}

Future<void> openContainingFolder(String path) async {
  log.i('Opening containing folder at $path');
  await Process.run('xdg-open', [path]);
}
