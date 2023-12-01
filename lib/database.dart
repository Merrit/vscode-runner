import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:xdg_directories/xdg_directories.dart';

import 'logs/logging_manager.dart';

/// The paths to the database files that various verions of VSCode use.
abstract class DatabaseFilePath {
  /// The VSCodium version of VSCode.
  static String codium =
      '${configHome.path}/VSCodium/User/globalStorage/state.vscdb';

  /// The Insiders version of VSCode.
  static String insiders =
      '${configHome.path}/Code - Insiders/User/globalStorage/state.vscdb';

  /// The stable version of VSCode.
  static String stable =
      '${configHome.path}/Code/User/globalStorage/state.vscdb';
}

/// Represents the database from the `state.vscdb` file that VSCode uses for
/// configurations.
class VSCodeDatabase {
  final String _dbFilePath;

  VSCodeDatabase(this._dbFilePath) {
    _watchDatabaseFile();
  }

  /// A stream that emits an event whenever the database file changes.
  ///
  /// This is used to detect when VSCode adds a new workspace to its "recent
  /// workspaces" list.
  Stream<void> get databaseChangedStream =>
      _databaseChangedStreamController.stream;

  /// Controller for the [databaseChangedStream].
  final _databaseChangedStreamController = StreamController<void>.broadcast();

  /// Watch the database file for changes, and emit an event to the
  /// [databaseChangedStream] whenever it changes.
  Future<void> _watchDatabaseFile() async {
    final databaseFile = File(_dbFilePath);
    final databaseFileExists = await databaseFile.exists();

    if (!databaseFileExists) {
      log.e('Unable to watch database file. File does not exist.');
      return;
    }

    log.i('Watching database file at $_dbFilePath');

    final databaseFileWatcher = databaseFile.watch(events: FileSystemEvent.all);
    Timer? databaseFileWatcherTimer;

    await for (final event in databaseFileWatcher) {
      if (event.type == FileSystemEvent.modify) {
        // If the file is modified multiple times in a short period of time,
        // we only want to emit one event.
        databaseFileWatcherTimer?.cancel();
        databaseFileWatcherTimer = Timer(const Duration(seconds: 30), () {
          _databaseChangedStreamController.add(null);
        });
      }
    }
  }

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

    return List<String>.unmodifiable([...recentPaths]);
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
