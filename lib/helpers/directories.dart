import 'dart:io';

import 'package:xdg_directories/xdg_directories.dart';

/// Returns the Directory for `~/.local/share/vscode-runner`.
///
/// This is the directory for storing the plugin's data, configs, logs, etc.
Future<Directory> getAppSupportDirectory() async {
  final appSupportDir = Directory('${dataHome.path}/vscode-runner');
  final exists = await appSupportDir.exists();
  if (!exists) await appSupportDir.create(recursive: true);
  return appSupportDir;
}
