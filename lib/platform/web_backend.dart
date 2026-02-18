import 'dart:convert';
import 'package:http/http.dart' as http;
import 'github_backend.dart';

class WebGitHubBackend implements GitHubBackend {
  static const _apiBase = 'https://api.github.com';

  Map<String, String> _headers(String token) => {
        'Accept': 'application/vnd.github+json',
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  Future<http.Response> _call(String method, String endpoint, String token,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_apiBase$endpoint');
    final headers = {
      ..._headers(token),
      if (body != null) 'Content-Type': 'application/json',
    };
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'PUT':
        return http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw Exception('Unsupported method: $method');
    }
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
    onLog?.call('Checking owner type for \'$owner\'...');
    final userRes = await _call('GET', '/users/$owner', token);
    final userData = jsonDecode(userRes.body);
    final isOrg = userData['type'] == 'Organization';
    onLog?.call('Owner \'$owner\' is ${isOrg ? 'an Organisation' : 'a User account'}');

    final endpoint = isOrg ? '/orgs/$owner/repos' : '/user/repos';
    onLog?.call('Creating repository \'$repoName\' under \'$owner\'...');
    final res = await _call('POST', endpoint, token, body: {
      'name': repoName,
      'private': true,
      'auto_init': true,
    });

    if (res.statusCode != 201) {
      final msg = jsonDecode(res.body)['message'] ?? 'HTTP ${res.statusCode}';
      onLog?.call('Failed: $msg', isError: true);
      return GHResult(success: false, message: msg);
    }

    final repoUrl = jsonDecode(res.body)['html_url'] as String;
    onLog?.call('Repository created: $repoUrl', isSuccess: true);

    if (collaborator != null && collaborator.isNotEmpty) {
      onLog?.call('Inviting \'$collaborator\' with \'${_roleLabel(role)}\' role...');
      final inv = await _call('PUT', '/repos/$owner/$repoName/collaborators/$collaborator', token,
          body: {'permission': role});
      if (inv.statusCode == 201 || inv.statusCode == 204) {
        onLog?.call('User \'$collaborator\' invited with \'${_roleLabel(role)}\' role', isSuccess: true);
      } else {
        onLog?.call('Failed to invite: HTTP ${inv.statusCode}', isError: true);
      }
    }

    return GHResult(success: true, message: repoUrl, data: {'url': repoUrl});
  }

  @override
  Future<GHResult> checkRepo({
    required String token,
    required String owner,
    required String repoName,
    LogCallback? onLog,
  }) async {
    onLog?.call('Checking repository \'$owner/$repoName\'...');
    final res = await _call('GET', '/repos/$owner/$repoName', token);
    if (res.statusCode == 200) {
      final url = jsonDecode(res.body)['html_url'] as String;
      onLog?.call('Repository found: $url', isSuccess: true);
      return GHResult(success: true, data: {'url': url});
    }
    final msg = jsonDecode(res.body)['message'] ?? 'HTTP ${res.statusCode}';
    onLog?.call('Not found: $msg', isError: true);
    return GHResult(success: false, message: msg);
  }

  @override
  Future<List<Collaborator>> getCollaborators({
    required String token,
    required String owner,
    required String repoName,
    LogCallback? onLog,
  }) async {
    onLog?.call('Fetching collaborators...');
    final res = await _call('GET', '/repos/$owner/$repoName/collaborators?per_page=100', token);
    if (res.statusCode != 200) return [];

    final List data = jsonDecode(res.body);
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
    onLog?.call('Setting \'$username\' to \'${_roleLabel(role)}\' role...');
    final res = await _call('PUT', '/repos/$owner/$repoName/collaborators/$username', token,
        body: {'permission': role});
    if (res.statusCode == 201 || res.statusCode == 204) {
      onLog?.call('\'$username\' role updated to \'${_roleLabel(role)}\'', isSuccess: true);
      return GHResult(success: true);
    }
    final msg = jsonDecode(res.body)['message'] ?? 'HTTP ${res.statusCode}';
    onLog?.call('Failed: $msg', isError: true);
    return GHResult(success: false, message: msg);
  }

  @override
  Future<GHResult> removeUserFromAllRepos({
    required String token,
    required String owner,
    required String username,
    LogCallback? onLog,
  }) async {
    onLog?.call('Fetching all repositories for \'$owner\'...');
    List allRepos = [];
    int page = 1;

    while (true) {
      final res = await _call('GET', '/orgs/$owner/repos?per_page=100&page=$page', token);
      if (res.statusCode != 200) {
        onLog?.call('Failed to fetch repos: HTTP ${res.statusCode}', isError: true);
        return GHResult(success: false, message: 'Failed to fetch repos');
      }
      final List data = jsonDecode(res.body);
      if (data.isEmpty) break;
      allRepos.addAll(data);
      onLog?.call('Fetched page $page (${data.length} repos)...');
      if (data.length < 100) break;
      page++;
    }

    onLog?.call('Found ${allRepos.length} repositories');
    int affected = 0;

    for (final repo in allRepos) {
      final fullName = repo['full_name'] as String;
      final name = repo['name'] as String;
      onLog?.call('Checking \'$fullName\'...');
      final del = await _call('DELETE', '/repos/$fullName/collaborators/$username', token);
      if (del.statusCode == 204) {
        onLog?.call('✓ Removed from \'$fullName\'', isSuccess: true);
        affected++;
      } else if (del.statusCode == 404) {
        onLog?.call('– Not a collaborator on \'$fullName\'');
      } else {
        onLog?.call('✗ HTTP ${del.statusCode} for \'$fullName\'', isWarn: true);
      }
    }

    onLog?.call('Done. Removed from $affected of ${allRepos.length} repo(s)', isSuccess: true);
    return GHResult(success: true, data: {'affected': affected, 'total': allRepos.length});
  }

  String _roleLabel(String role) {
    const map = {'push': 'Write', 'pull': 'Read', 'maintain': 'Maintain', 'admin': 'Admin', 'triage': 'Triage'};
    return map[role] ?? role;
  }
}
