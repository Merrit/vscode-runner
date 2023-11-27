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
