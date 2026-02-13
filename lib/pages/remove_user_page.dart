import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/styled_widgets.dart';
import '../widgets/log_panel.dart';
import '../platform/github_backend.dart';

class RemoveUserPage extends StatefulWidget {
  final String token;
  final List<String> savedUsers;
  final GitHubBackend backend;

  const RemoveUserPage({super.key, required this.token, required this.savedUsers, required this.backend});

  @override
  State<RemoveUserPage> createState() => _RemoveUserPageState();
}

class _RemoveUserPageState extends State<RemoveUserPage> with LoggerMixin {
  String _owner = '';
  String _username = '';
  bool _loading = false;
  Map<String, int>? _result;

  Future<void> _execute() async {
    final owner = _owner.trim().isEmpty ? defaultOwner : _owner.trim();
    if (_username.trim().isEmpty) return;

    setState(() { _loading = true; _result = null; });
    clearLogs();

    final result = await widget.backend.removeUserFromAllRepos(
      token: widget.token, owner: owner, username: _username.trim(), onLog: log,
    );

    if (result.success && result.data.containsKey('affected')) {
      setState(() => _result = {
        'affected': result.data['affected'] as int,
        'total': result.data['total'] as int,
      });
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
          const PageHeader(title: 'Remove User from All Repos', subtitle: 'Remove a user as collaborator from every repository in an organisation.'),

          // Warning
          StyledCard(
            backgroundColor: AppColors.warningCardBg, borderColor: AppColors.warningCardBorder,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.warning),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Use with caution', style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(
                  'This iterates through every repository in the organisation. '
                  'For large orgs it consumes many API calls (1 per 100 repos + 1 DELETE per repo). '
                  'Rate limit: 5,000 calls/hour.',
                  style: TextStyle(color: AppColors.warningText, fontSize: 12, height: 1.6),
                ),
              ])),
            ]),
          ),

          // Form
          StyledCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Owner / Organisation'),
                StyledInput(placeholder: defaultOwner, onChanged: (v) => setState(() => _owner = v)),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const FieldLabel('Username', required: true),
                ComboBox(value: _username, onChanged: (v) => setState(() => _username = v), options: widget.savedUsers, placeholder: 'GitHub username'),
              ])),
            ]),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _loading ? 'Removing...' : 'Remove from All Repos',
              icon: Icons.delete_sweep_rounded, danger: true,
              onPressed: _username.trim().isNotEmpty && !_loading ? _execute : null, loading: _loading,
            ),
          ])),

          // Result
          if (_result != null) StyledCard(
            backgroundColor: AppColors.successCardBg, borderColor: AppColors.successCardBorder,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                SizedBox(width: 8),
                Text('Operation Complete', style: TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              RichText(text: TextSpan(style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), children: [
                const TextSpan(text: 'User '),
                TextSpan(text: '\'${_username.trim()}\'', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                const TextSpan(text: ' removed from '),
                TextSpan(text: '${_result!['affected']}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 15)),
                TextSpan(text: ' of ${_result!['total']} repositories.'),
              ])),
            ]),
          ),

          LogPanel(logs: logs),
        ],
      )),
    );
  }
}
