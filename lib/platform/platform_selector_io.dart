import 'dart:io' show Platform;
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

Future<String?> getScriptsDir() async {
  if (isMacOS) {
    final backend = MacOSGitHubBackend();
    return backend.getScriptsPath();
  }
  return null;
}
