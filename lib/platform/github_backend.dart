/// Platform abstraction for GitHub operations.
/// Current app mode: web-style HTTP backend.

typedef LogCallback = void Function(String message, {bool isError, bool isSuccess, bool isWarn});

/// Result from any GitHub operation
class GHResult {
  final bool success;
  final String message;
  final Map<String, dynamic> data;

  GHResult({required this.success, this.message = '', this.data = const {}});
}

/// Collaborator model
class Collaborator {
  final String login;
  String role;
  String originalRole;
  final String? avatar;

  Collaborator({
    required this.login,
    required this.role,
    required this.originalRole,
    this.avatar,
  });

  bool get hasChanged => role != originalRole;
}

/// Abstract platform backend
abstract class GitHubBackend {
  /// Create a repository, optionally add collaborator with role
  Future<GHResult> createRepo({
    required String token,
    required String owner,
    required String repoName,
    String? collaborator,
    String role = 'push',
    LogCallback? onLog,
  });

  /// Check if a repo exists, return repo info
  Future<GHResult> checkRepo({
    required String token,
    required String owner,
    required String repoName,
    LogCallback? onLog,
  });

  /// Get list of collaborators for a repo
  Future<List<Collaborator>> getCollaborators({
    required String token,
    required String owner,
    required String repoName,
    LogCallback? onLog,
  });

  /// Add or update collaborator role
  Future<GHResult> setCollaboratorRole({
    required String token,
    required String owner,
    required String repoName,
    required String username,
    required String role,
    LogCallback? onLog,
  });

  /// Remove user from all org repos
  Future<GHResult> removeUserFromAllRepos({
    required String token,
    required String owner,
    required String username,
    LogCallback? onLog,
  });
}
