import 'database.dart';
import 'enums/enums.dart';
import 'notifications.dart';

class VSCode {
  final VSCodeDatabase _database;

  List<String> recentWorkspacePaths = [];
  final VSCodeVersion version;

  VSCode(
    this.version, {
    required VSCodeDatabase database,
  }) : _database = database {
    // Populate the recentWorkspacePaths list.
    _updateRecentWorkspacePaths();

    // Listen for changes to the database file, and update the recentWorkspacePaths.
    database.databaseChangedStream.listen((_) {
      _updateRecentWorkspacePaths();
    });
  }

  /// Populates the [recentWorkspacePaths] list with the most recent workspace
  /// paths.
  Future<void> _updateRecentWorkspacePaths() async {
    try {
      recentWorkspacePaths = _database.getRecentWorkspacePaths();
    } on MissingSQLite3Exception catch (e) {
      await sendNotification(
        title: 'SQLite3 Error',
        body: e.toString(),
      );
    }
  }
}

/// Returns the executable name for the given [version].
String vscodeExecutableFor(VSCodeVersion version) {
  switch (version) {
    case VSCodeVersion.codium:
      return 'codium';
    case VSCodeVersion.insiders:
      return 'code-insiders';
    case VSCodeVersion.stable:
      return 'code';
  }
}

/// Returns the icon name for the given [version].
///
/// This is used to determine which icon will be shown in the search results.
String vscodeIconNameFor(VSCodeVersion version) {
  switch (version) {
    case VSCodeVersion.codium:
      return 'vscodium';
    case VSCodeVersion.insiders:
      return 'vscode-insiders';
    case VSCodeVersion.stable:
      return 'vscode';
  }
}
