import 'github_backend.dart';
import 'web_backend.dart';

GitHubBackend createBackend() => WebGitHubBackend();

bool get isMacOS => false;

Future<String?> getScriptsDir() async => null;
