import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../widgets/styled_widgets.dart';

class SettingsPage extends StatefulWidget {
  final String token;
  final bool tokenSaved;
  final ValueChanged<String> onTokenChanged;
  final VoidCallback onSave;

  const SettingsPage({super.key, required this.token, required this.tokenSaved, required this.onTokenChanged, required this.onSave});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _obscure = true;
  late TextEditingController _ctrl;

  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.token); }

  @override
  void didUpdateWidget(covariant SettingsPage old) {
    super.didUpdateWidget(old);
    if (widget.token != old.token && widget.token != _ctrl.text) _ctrl.text = widget.token;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'Settings', subtitle: 'Configure your GitHub authentication. Token is stored locally only.'),
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
              PrimaryButton(label: 'Save Token', icon: Icons.check_rounded, onPressed: widget.onSave),
            ]),
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
