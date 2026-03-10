import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../widgets/styled_widgets.dart';

class SettingsPage extends StatefulWidget {
  final String token;
  final String jenkinsUser;
  final String jenkinsToken;
  final bool tokenSaved;
  final ValueChanged<String> onTokenChanged;
  final ValueChanged<String> onJenkinsUserChanged;
  final ValueChanged<String> onJenkinsTokenChanged;
  final VoidCallback onSaveAll;

  const SettingsPage({
    super.key,
    required this.token,
    required this.jenkinsUser,
    required this.jenkinsToken,
    required this.tokenSaved,
    required this.onTokenChanged,
    required this.onJenkinsUserChanged,
    required this.onJenkinsTokenChanged,
    required this.onSaveAll,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _obscure = true;
  bool _obscureJenkins = true;
  late TextEditingController _ctrl;
  late TextEditingController _jenkinsUserCtrl;
  late TextEditingController _jenkinsTokenCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.token);
    _jenkinsUserCtrl = TextEditingController(text: widget.jenkinsUser);
    _jenkinsTokenCtrl = TextEditingController(text: widget.jenkinsToken);
  }

  @override
  void didUpdateWidget(covariant SettingsPage old) {
    super.didUpdateWidget(old);
    if (widget.token != old.token && widget.token != _ctrl.text) _ctrl.text = widget.token;
    if (widget.jenkinsUser != old.jenkinsUser && widget.jenkinsUser != _jenkinsUserCtrl.text) {
      _jenkinsUserCtrl.text = widget.jenkinsUser;
    }
    if (widget.jenkinsToken != old.jenkinsToken && widget.jenkinsToken != _jenkinsTokenCtrl.text) {
      _jenkinsTokenCtrl.text = widget.jenkinsToken;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _jenkinsUserCtrl.dispose();
    _jenkinsTokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'Settings', subtitle: 'Configure your GitHub and Jenkins authentication. Tokens are stored locally only.'),
          StyledCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const FieldLabel('GitHub Personal Access Token', required: true),
            Row(children: [
              Expanded(child: StyledInput(
                controller: _ctrl, obscureText: _obscure, placeholder: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                onChanged: widget.onTokenChanged,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.textMuted),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              )),
              const SizedBox(width: 12),
              PrimaryButton(label: 'Save Credentials', icon: Icons.check_rounded, onPressed: widget.onSaveAll),
            ]),
            const SizedBox(height: 20),
            const FieldLabel('Jenkins Username'),
            StyledInput(
              controller: _jenkinsUserCtrl,
              placeholder: 'jenkins-user',
              onChanged: widget.onJenkinsUserChanged,
            ),
            const SizedBox(height: 12),
            const FieldLabel('Jenkins API Token'),
            StyledInput(
              controller: _jenkinsTokenCtrl,
              obscureText: _obscureJenkins,
              placeholder: 'jenkins-token',
              onChanged: widget.onJenkinsTokenChanged,
              suffix: IconButton(
                icon: Icon(_obscureJenkins ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18, color: AppColors.textMuted),
                onPressed: () => setState(() => _obscureJenkins = !_obscureJenkins),
              ),
            ),
            if (widget.tokenSaved) Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Token saved successfully', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.6), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Required token scopes', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _scope('repo', 'Full control of repositories & collaborators'),
                const SizedBox(height: 6),
                _scope('admin:org', 'Manage org membership, teams, and repos'),
              ]),
            ),
          ])),
        ],
      )),
    );
  }

  Widget _scope(String scope, String desc) => Row(children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(scope, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.cyan)),
    ),
    const SizedBox(width: 10),
    Expanded(child: Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
  ]);
}
