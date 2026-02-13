import 'dart:io' show Directory, File, Platform;

import 'package:path_provider/path_provider.dart';

import 'github_backend.dart';
import 'macos_backend.dart';
import 'web_backend.dart';

GitHubBackend createBackend() {
  if (Platform.isMacOS || Platform.isLinux) {
    return MacOSGitHubBackend();
  }
  return WebGitHubBackend();
}

bool get isMacOS => Platform.isMacOS || Platform.isLinux;

bool get canDownloadScripts => true;

Future<String?> getScriptsDir() async {
  final backend = MacOSGitHubBackend();
  return backend.getScriptsPath();
}

Future<String?> downloadScript(String scriptName) async {
  final backend = MacOSGitHubBackend();
  final scriptsPath = await backend.getScriptsPath();
  final source = File('$scriptsPath/$scriptName');
  if (!source.existsSync()) return null;

  final downloadsDir = await getDownloadsDirectory();
  final targetDir = downloadsDir ?? Directory(scriptsPath);
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  var targetPath = '${targetDir.path}/$scriptName';
  if (File(targetPath).existsSync()) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stem = scriptName.endsWith('.sh')
        ? scriptName.substring(0, scriptName.length - 3)
        : scriptName;
    targetPath = '${targetDir.path}/${stem}_$timestamp.sh';
  }

  final copied = await source.copy(targetPath);
  return copied.path;
}
