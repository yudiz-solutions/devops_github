import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/styled_widgets.dart';
import '../widgets/log_panel.dart';
import '../platform/github_backend.dart';
import '../platform/platform_selector.dart' as platform;

class ManageUsersPage extends StatefulWidget {
  final String token;
  final List<String> savedUsers;
  final GitHubBackend backend;

  const ManageUsersPage({super.key, required this.token, required this.savedUsers, required this.backend});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> with LoggerMixin {
  String _owner = '';
  String _repoName = '';
  bool _repoValid = false;
  String? _repoUrl;
  List<Collaborator> _collaborators = [];
  String _newUser = '';
  String _newRole = 'push';
  bool _checking = false;
  bool _loading = false;

  Future<void> _checkRepo() async {
    final owner = _owner.trim().isEmpty ? defaultOwner : _owner.trim();
    if (_repoName.trim().isEmpty) return;

    setState(() { _checking = true; _repoValid = false; _collaborators = []; _repoUrl = null; });
    clearLogs();

    final result = await widget.backend.checkRepo(token: widget.token, owner: owner, repoName: _repoName.trim(), onLog: log);

    if (result.success) {
      setState(() { _repoValid = true; _repoUrl = result.data['url'] as String?; });
      final collabs = await widget.backend.getCollaborators(token: widget.token, owner: owner, repoName: _repoName.trim(), onLog: log);
      setState(() => _collaborators = collabs);
    }
    setState(() => _checking = false);
  }

  Future<void> _changeRole(Collaborator c) async {
    final owner = _owner.trim().isEmpty ? defaultOwner : _owner.trim();
    setState(() => _loading = true);
    final result = await widget.backend.setCollaboratorRole(
      token: widget.token, owner: owner, repoName: _repoName.trim(), username: c.login, role: c.role, onLog: log,
    );
    if (result.success) setState(() => c.originalRole = c.role);
    setState(() => _loading = false);
  }

  Future<void> _addCollaborator() async {
    if (_newUser.trim().isEmpty) return;
    final owner = _owner.trim().isEmpty ? defaultOwner : _owner.trim();
    setState(() => _loading = true);

    final result = await widget.backend.setCollaboratorRole(
      token: widget.token, owner: owner, repoName: _repoName.trim(), username: _newUser.trim(), role: _newRole, onLog: log,
    );

    if (result.success) {
      setState(() {
        _collaborators.add(Collaborator(login: _newUser.trim(), role: _newRole, originalRole: _newRole));
        _newUser = '';
      });
    }
    setState(() => _loading = false);
  }


  Future<void> _downloadScript() async {
    final filePath = await platform.downloadScript('github_add_user_to_repo.sh');
    if (!mounted) return;

    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Script downloaded to: $filePath')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not download script on this platform.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(title: 'Manage Repo Users', subtitle: 'Add users or change roles on an existing repository.', trailing: platform.isMacOS ? PrimaryButton(label: 'Download Script', icon: Icons.download_rounded, compact: true, onPressed: _downloadScript) : null),

          // Repo check
          StyledCard(child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('Owner / Organisation'),
              StyledInput(placeholder: defaultOwner, onChanged: (v) => setState(() { _owner = v; _repoValid = false; })),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('Repository Name', required: true),
              StyledInput(placeholder: 'my-repo', onChanged: (v) => setState(() { _repoName = v; _repoValid = false; })),
            ])),
            const SizedBox(width: 16),
            Padding(padding: const EdgeInsets.only(bottom: 1), child: PrimaryButton(
              label: _checking ? 'Checking...' : 'Check Repo', icon: Icons.search_rounded,
              onPressed: _repoName.trim().isNotEmpty && !_checking ? _checkRepo : null, loading: _checking,
            )),
          ])),

          // Verified banner
          if (_repoValid && _repoUrl != null) StyledCard(
            backgroundColor: AppColors.successCardBg, borderColor: AppColors.successCardBorder, padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
              const SizedBox(width: 10),
              const Text('Verified — ', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
              Expanded(child: SelectableText(_repoUrl!, style: const TextStyle(color: AppColors.link, fontSize: 13))),
            ]),
          ),

          // Collaborators
          if (_repoValid) StyledCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Collaborators (${_collaborators.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              const Spacer(),
            ]),
            const SizedBox(height: 14),

            if (_collaborators.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No collaborators found', style: TextStyle(color: AppColors.textMuted, fontSize: 13))),

            ..._collaborators.map((c) => Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.cardBorder.withOpacity(0.6)))),
              child: Row(children: [
                // Avatar
                ClipRRect(borderRadius: BorderRadius.circular(20),
                  child: c.avatar != null && c.avatar!.isNotEmpty
                    ? Image.network(c.avatar!, width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatar(c.login))
                    : _avatar(c.login)),
                const SizedBox(width: 14),
                Expanded(child: Text(c.login, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
                SizedBox(width: 140, child: StyledDropdown(
                  value: c.role, items: AppRoles.roles,
                  onChanged: (v) => setState(() => c.role = v ?? c.role),
                )),
                const SizedBox(width: 10),
                if (c.hasChanged) PrimaryButton(label: 'Update', compact: true, onPressed: _loading ? null : () => _changeRole(c))
                else const SizedBox(width: 85),
              ]),
            )),

            const SizedBox(height: 16),
            Divider(color: AppColors.cardBorder.withOpacity(0.5)),
            const SizedBox(height: 14),
            const Text('Add Collaborator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(flex: 2, child: ComboBox(value: _newUser, onChanged: (v) => setState(() => _newUser = v), options: widget.savedUsers, placeholder: 'GitHub username')),
              const SizedBox(width: 10),
              SizedBox(width: 140, child: StyledDropdown(value: _newRole, items: AppRoles.roles, onChanged: (v) => setState(() => _newRole = v ?? 'push'))),
              const SizedBox(width: 10),
              PrimaryButton(label: 'Add User', icon: Icons.person_add_rounded,
                onPressed: _newUser.trim().isNotEmpty && !_loading ? _addCollaborator : null, loading: _loading),
            ]),
          ])),

          LogPanel(logs: logs),
        ],
      )),
    );
  }

  Widget _avatar(String login) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.3), AppColors.accent.withOpacity(0.3)]),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(login.isNotEmpty ? login[0].toUpperCase() : '?',
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
  );
}
