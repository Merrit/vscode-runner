import 'database.dart';
import 'enums/enums.dart';

class VSCode {
  final VSCodeDatabase _database;

  List<String> recentWorkspacePaths = [];
  final VSCodeVersion version;

  VSCode(
    this.version, {
    required VSCodeDatabase database,
  }) : _database = database {
    // Populate the recentWorkspacePaths list.
    recentWorkspacePaths = _database.getRecentWorkspacePaths();

    // Listen for changes to the database file, and update the recentWorkspacePaths.
    database.databaseChangedStream.listen((_) {
      recentWorkspacePaths = _database.getRecentWorkspacePaths();
    });
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
