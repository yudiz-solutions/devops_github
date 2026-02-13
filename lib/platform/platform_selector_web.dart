import 'github_backend.dart';
import 'web_backend.dart';

GitHubBackend createBackend() => WebGitHubBackend();

bool get isMacOS => false;

bool get canDownloadScripts => false;

Future<String?> getScriptsDir() async => null;

Future<String?> downloadScript(String scriptName) async => null;
