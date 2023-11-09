import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';
import 'package:xdg_directories/xdg_directories.dart';

import 'logs/logging_manager.dart';

/// The paths to the database files that various verions of VSCode use.
abstract class DatabaseFilePath {
  /// The stable version of VSCode.
  static String vscode =
      '${configHome.path}/Code/User/globalStorage/state.vscdb';

  /// The Insiders version of VSCode.
  static String vscodeInsiders =
      '${configHome.path}/Code - Insiders/User/globalStorage/state.vscdb';
}

/// Represents the database from the `state.vscdb` file that VSCode uses for
/// configurations.
class VSCodeDatabase {
  final String _dbFilePath;

  const VSCodeDatabase(this._dbFilePath);

  /// Returns a list where each is the path of a workspace that is remembered
  /// by VSCode, in its "recent workspaces" list.
  List<String> getRecentWorkspacePaths() {
    final Database db;

    try {
      db = sqlite3.open(_dbFilePath, mode: OpenMode.readOnly);
    } catch (e) {
      log.e('Unable to open VSCode database file.\n'
          'Expected file at $_dbFilePath\n'
          'Make sure sqlite3 is installed.\n'
          'Error: $e');
      return const [];
    }

    log.i('Opened VSCode database file at $_dbFilePath');

    final rows = db.select(
      "SELECT value FROM ItemTable WHERE key = 'history.recentlyOpenedPathsList'",
    );
    db.dispose();

    final jsonString = rows.first.values.first as String;
    final recentPaths = _recentPathsFromJson(jsonString);

    return recentPaths;
  }

  /// Converts the json from the db query into a `List<String>` of paths.
  List<String> _recentPathsFromJson(String data) {
    final dataMap = json.decode(data) as Map<String, dynamic>;
    final rawPathList = dataMap['entries'] as List;
    final pathMaps = rawPathList.cast<Map<String, dynamic>>();
    final paths =
        pathMaps.map((e) => e['folderUri'] ?? '').toList().cast<String>();
    return paths;
  }
}
