import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'github_backend.dart';

class MacOSGitHubBackend implements GitHubBackend {
  String? _scriptsDir;

  /// Ensure scripts are extracted from assets to a temp directory
  Future<String> _getScriptsDir() async {
    if (_scriptsDir != null) return _scriptsDir!;

    final appDir = await getApplicationSupportDirectory();
    final dir = Directory('${appDir.path}/github_scripts');
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final scripts = [
      'github_create_repo.sh',
      'github_add_user_to_repo.sh',
      'github_remove_user_from_org_repos.sh',
      'github_promote_to_admin.sh',
    ];

    for (final name in scripts) {
      final file = File('${dir.path}/$name');
      // Always overwrite to ensure latest version
      final content = await rootBundle.loadString('scripts/$name');
      await file.writeAsString(content);
      await Process.run('chmod', ['+x', file.path]);
    }

    _scriptsDir = dir.path;
    return _scriptsDir!;
  }

  /// Run a script and stream output to log callback
  Future<_ScriptResult> _runScript(
      String scriptName,
      List<String> args,
      String token, {
        LogCallback? onLog,
      }) async {
    final dir = await _getScriptsDir();
    onLog?.call('Scripts extracted to: $dir');
    onLog?.call(
      'Files: ${Directory(dir).listSync().map((e) => e.path).join(", ")}',
    );

    final scriptPath = '$dir/$scriptName';
    onLog?.call('Running: /bin/bash $scriptPath ${args.join(" ")}');

    final process = await Process.start(
      '/bin/bash',
      ['-x', scriptPath, ...args], // -x prints each command executed
      environment: {
        ...Platform.environment,
        'GITHUB_TOKEN': token,
      },
      workingDirectory: dir,
    );

    final out = StringBuffer();
    final err = StringBuffer();

    Future<void> pumpStdout() async {
      await for (final line in process.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())) {
        out.writeln(line);

        if (line.startsWith('[SUCCESS]')) {
          onLog?.call(line.replaceFirst('[SUCCESS] ', ''), isSuccess: true);
        } else if (line.startsWith('[ERROR]')) {
          onLog?.call(line.replaceFirst('[ERROR] ', ''), isError: true);
        } else if (line.startsWith('[WARN]')) {
          onLog?.call(line.replaceFirst('[WARN] ', ''), isWarn: true);
        } else if (line.startsWith('[INFO]')) {
          onLog?.call(line.replaceFirst('[INFO] ', ''));
        } else {
          onLog?.call(line);
        }
      }
    }

    Future<void> pumpStderr() async {
      await for (final line in process.stderr
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())) {
        err.writeln(line);
        onLog?.call(line, isError: true);
      }
    }

    // ✅ Drain both at the same time to avoid deadlock
    await Future.wait([pumpStdout(), pumpStderr()]);

    final exitCode = await process.exitCode;
    onLog?.call('Exit code: $exitCode');

    return _ScriptResult(
      exitCode: exitCode,
      stdout: out.toString(),
      stderr: err.toString(),
    );
  }


  /// Extract [RESULT] line from script output
  String? _extractResult(String output) {
    for (final line in output.split('\n')) {
      if (line.startsWith('[RESULT]')) {
        return line.replaceFirst('[RESULT] ', '').trim();
      }
    }
    return null;
  }

  @override
  Future<GHResult> createRepo({
    required String token,
    required String owner,
    required String repoName,
    String? collaborator,
    String role = 'push',
    LogCallback? onLog,
  }) async {
    final args = [owner, repoName];
    if (collaborator != null && collaborator.isNotEmpty) {
      args.addAll([collaborator, role]);
    }

    final result = await _runScript('github_create_repo.sh', args, token, onLog: onLog);
    final url = _extractResult(result.stdout);

    if (result.exitCode == 0 && url != null) {
      return GHResult(success: true, message: url, data: {'url': url});
    }
    return GHResult(success: false, message: result.stderr);
  }

  @override
  Future<GHResult> checkRepo({
    required String token,
    required String owner,
    required String repoName,
    LogCallback? onLog,
  }) async {
    // For check, we use the API helper within the add_user script's verification
    // But simpler to do a quick curl check via process
    onLog?.call('Checking repository \'$owner/$repoName\'...');

    final process = await Process.run(
      'curl',
      [
        '--silent', '--show-error', '-w', '\n%{http_code}',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'Authorization: Bearer $token',
        '-H', 'X-GitHub-Api-Version: 2022-11-28',
        'https://api.github.com/repos/$owner/$repoName',
      ],
    );

    final lines = process.stdout.toString().trim().split('\n');
    final httpCode = int.tryParse(lines.last) ?? 0;
    final body = lines.sublist(0, lines.length - 1).join('\n');

    if (httpCode == 200) {
      try {
        final data = jsonDecode(body);
        final url = data['html_url'] as String;
        onLog?.call('Repository found: $url', isSuccess: true);
        return GHResult(success: true, data: {'url': url});
      } catch (_) {}
    }

    onLog?.call('Repository not found (HTTP $httpCode)', isError: true);
    return GHResult(success: false, message: 'Not found');
  }

  @override
  Future<List<Collaborator>> getCollaborators({
    required String token,
    required String owner,
    required String repoName,
    LogCallback? onLog,
  }) async {
    onLog?.call('Fetching collaborators...');

    final process = await Process.run(
      'curl',
      [
        '--silent', '--show-error',
        '-H', 'Accept: application/vnd.github+json',
        '-H', 'Authorization: Bearer $token',
        '-H', 'X-GitHub-Api-Version: 2022-11-28',
        'https://api.github.com/repos/$owner/$repoName/collaborators?per_page=100',
      ],
    );

    try {
      final List data = jsonDecode(process.stdout.toString());
      final collabs = data.map((c) {
        final perms = Map<String, dynamic>.from(c['permissions']);
        final role = perms['admin'] == true
            ? 'admin'
            : perms['maintain'] == true
                ? 'maintain'
                : perms['push'] == true
                    ? 'push'
                    : perms['triage'] == true
                        ? 'triage'
                        : 'pull';
        return Collaborator(
          login: c['login'],
          role: role,
          originalRole: role,
          avatar: c['avatar_url'],
        );
      }).toList();
      onLog?.call('Found ${collabs.length} collaborator(s)', isSuccess: true);
      return collabs;
    } catch (e) {
      onLog?.call('Failed to parse collaborators: $e', isError: true);
      return [];
    }
  }

  @override
  Future<GHResult> setCollaboratorRole({
    required String token,
    required String owner,
    required String repoName,
    required String username,
    required String role,
    LogCallback? onLog,
  }) async {
    final result = await _runScript(
      'github_promote_to_admin.sh',
      [owner, repoName, username, role],
      token,
      onLog: onLog,
    );
    return GHResult(success: result.exitCode == 0);
  }

  @override
  Future<GHResult> removeUserFromAllRepos({
    required String token,
    required String owner,
    required String username,
    LogCallback? onLog,
  }) async {
    final result = await _runScript(
      'github_remove_user_from_org_repos.sh',
      [owner, username],
      token,
      onLog: onLog,
    );

    final resultLine = _extractResult(result.stdout);
    if (result.exitCode == 0 && resultLine != null) {
      // Parse "Removed from X of Y repositories"
      final match = RegExp(r'(\d+) of (\d+)').firstMatch(resultLine);
      if (match != null) {
        return GHResult(success: true, data: {
          'affected': int.parse(match.group(1)!),
          'total': int.parse(match.group(2)!),
        });
      }
    }

    return GHResult(success: result.exitCode == 0);
  }

  /// Get the path to bundled scripts for download
  Future<String> getScriptsPath() => _getScriptsDir();
}

class _ScriptResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  _ScriptResult({required this.exitCode, required this.stdout, required this.stderr});
}
