import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../platform/script_downloader.dart' as script_downloader;
import '../widgets/styled_widgets.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _scripts = [
    'github_create_repo.sh',
    'github_add_user_to_repo.sh',
    'github_remove_user_from_org_repos.sh',
    'github_promote_to_admin.sh',
  ];

  Future<void> _downloadScripts(BuildContext context) async {
    var successCount = 0;
    for (final script in _scripts) {
      final ok = await script_downloader.downloadAssetScript(script);
      if (ok) successCount++;
    }

    if (!context.mounted) return;

    final message = successCount == _scripts.length
        ? 'Downloaded all ${_scripts.length} scripts.'
        : successCount > 0
            ? 'Downloaded $successCount of ${_scripts.length} scripts.'
            : 'Could not download scripts on this platform.';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepItem(
        icon: Icons.key_rounded,
        title: 'Configure Token',
        description: 'Open Settings and add your GitHub Personal Access Token with scopes: repo, admin:org.',
      ),
      _StepItem(
        icon: Icons.badge_rounded,
        title: 'Save Team Usernames',
        description: 'Use Predefined Usernames so forms can auto-suggest collaborators and reduce typos.',
      ),
      _StepItem(
        icon: Icons.add_box_rounded,
        title: 'Create Repository',
        description: 'Set org/owner + repo name. You can optionally add a collaborator and choose a role.',
      ),
      _StepItem(
        icon: Icons.people_rounded,
        title: 'Manage Repo Users',
        description: 'Verify an existing repo, review collaborators, and update/add users with the right role.',
      ),
      _StepItem(
        icon: Icons.delete_sweep_rounded,
        title: 'Remove User from Org Repos',
        description: 'Run bulk removal for a username across repositories. Best for offboarding workflows.',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'How to Use',
              subtitle: 'A practical guide to safely manage repositories and collaborators.',
              trailing: PrimaryButton(
                label: 'View Scripts',
                icon: Icons.download_rounded,
                onPressed: () => _downloadScripts(context),
              ),
            ),

            StyledCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available scripts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 14),
                  ...List.generate(
                    steps.length,
                    (i) => _stepCard(index: i + 1, item: steps[i]),
                  ),
                ],
              ),
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: StyledCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Roles', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 12),
                        _roleRow('Read (pull)', 'View and clone repositories'),
                        _roleRow('Triage', 'Manage issues and PRs'),
                        _roleRow('Write (push)', 'Push commits and collaborate'),
                        _roleRow('Maintain', 'Manage most settings except admin'),
                        _roleRow('Admin', 'Full repository control'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StyledCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rate Limits & Safety', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 12),
                        _rateRow('Unauthenticated', '60/hour'),
                        _rateRow('Authenticated (PAT)', '5,000/hour'),
                        _rateRow('Enterprise Cloud', '15,000/hour'),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                          child: Row(children: const [
                            Icon(Icons.info_outline_rounded, size: 14, color: AppColors.success),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bulk operations are powerful—double-check owner, repo, and username before running destructive actions.',
                                style: TextStyle(color: AppColors.success, fontSize: 12, height: 1.45),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard({required int index, required _StepItem item}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inputBg.withOpacity(0.45),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('$index', style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Icon(item.icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(item.description, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _roleRow(String role, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 120, child: Text(role, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            Expanded(child: Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
          ],
        ),
      );

  Widget _rateRow(String label, String limit) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 170, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            Text(limit, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.primaryLight)),
          ],
        ),
      );
}

class _StepItem {
  final IconData icon;
  final String title;
  final String description;

  const _StepItem({required this.icon, required this.title, required this.description});
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.inputBg.withOpacity(0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryLight),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
