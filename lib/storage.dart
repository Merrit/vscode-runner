import 'dart:convert';

/// Represents the `state.vscdb` file that VSCode uses for configurations.
class Storage {
  /// A list of all the recently opened paths VSCode remembers.
  final List<String> recentPaths;

  const Storage({
    required this.recentPaths,
  });

  /// Generate the [recentPaths] from the `state.vscdb` database.
  static Storage fromJson(String data) {
    final dataMap = json.decode(data) as Map<String, dynamic>;
    final rawPathList = dataMap['entries'] as List;
    final pathMaps = rawPathList.cast<Map<String, dynamic>>();
    final paths =
        pathMaps.map((e) => e['folderUri'] ?? '').toList().cast<String>();
    return Storage(recentPaths: paths);
  }
}
