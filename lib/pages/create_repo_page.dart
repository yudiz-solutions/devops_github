import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/styled_widgets.dart';
import '../widgets/log_panel.dart';
import '../platform/github_backend.dart';

class CreateRepoPage extends StatefulWidget {
  final String token;
  final List<String> savedUsers;
  final GitHubBackend backend;

  const CreateRepoPage({super.key, required this.token, required this.savedUsers, required this.backend});

  @override
  State<CreateRepoPage> createState() => _CreateRepoPageState();
}

class _CreateRepoPageState extends State<CreateRepoPage> with LoggerMixin {
  String _owner = '';
  String _repoName = '';
  String _username = '';
  String _role = 'push';
  bool _loading = false;
  String? _repoUrl;

  Future<void> _execute() async {
    final owner = _owner.trim().isEmpty ? defaultOwner : _owner.trim();
    if (_repoName.trim().isEmpty) return;

    setState(() { _loading = true; _repoUrl = null; });
    clearLogs();

    final result = await widget.backend.createRepo(
      token: widget.token,
      owner: owner,
      repoName: _repoName.trim(),
      collaborator: _username.trim().isEmpty ? null : _username.trim(),
      role: _role,
      onLog: log,
    );

    if (result.success && result.data.containsKey('url')) {
      setState(() => _repoUrl = result.data['url'] as String);
    }
    setState(() => _loading = false);
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'Create Repository', subtitle: 'Create a new GitHub repo and optionally invite a collaborator.'),

          StyledCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Owner / Organisation'),
                StyledInput(placeholder: defaultOwner, onChanged: (v) => setState(() => _owner = v)),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Repository Name', required: true),
                StyledInput(placeholder: 'my-new-repo', onChanged: (v) => setState(() => _repoName = v)),
              ])),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Collaborator (optional)'),
                ComboBox(value: _username, onChanged: (v) => setState(() => _username = v), options: widget.savedUsers, placeholder: 'GitHub username'),
              ])),
              const SizedBox(width: 16),
              SizedBox(width: 150, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Role'),
                StyledDropdown(value: _role, items: AppRoles.roles, onChanged: (v) => setState(() => _role = v ?? 'push')),
              ])),
            ]),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _loading ? 'Creating...' : 'Create Repository',
              icon: Icons.add_rounded,
              onPressed: _repoName.trim().isNotEmpty && !_loading ? _execute : null,
              loading: _loading,
            ),
          ])),

          if (_repoUrl != null) StyledCard(
            backgroundColor: AppColors.successCardBg, borderColor: AppColors.successCardBorder,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Text('Repository Created', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              SelectableText(_repoUrl!, style: const TextStyle(color: AppColors.link, fontSize: 14)),
            ]),
          ),

          LogPanel(logs: logs),
        ],
      )),
    );
  }
}
