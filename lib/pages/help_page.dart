import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../widgets/styled_widgets.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'How to Use',
            subtitle: 'Step-by-step guide to using the GitHub Admin Panel.',
          ),

          // Platform info
          StyledCard(
            backgroundColor: AppColors.primary.withOpacity(0.05),
            borderColor: AppColors.primary.withOpacity(0.2),
            child: Row(children: [
              const Icon(Icons.language_rounded,
                size: 20, color: AppColors.primaryLight),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('HTTP Mode — Direct API',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('This app calls the GitHub REST API directly from the browser. No local scripts are used.',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5)),
              ])),
            ]),
          ),

          _section('1. Configure Token', 'Go to Settings and enter your GitHub Personal Access Token.\n\nRequired scopes: repo, admin:org'),
          _section('2. Add Team Members', 'Go to Predefined Usernames and add your team members\' GitHub usernames. These appear as dropdown suggestions in all forms.'),
          _section('3. Create Repository', 'Enter the org/owner name and repo name. Owner defaults to "$defaultOwner" if empty. Optionally add a collaborator and select their role.'),
          _section('4. Manage Repo Users', 'Enter org and repo, click "Check Repo" to verify. See all collaborators with role dropdowns. Change roles inline or add new collaborators.'),
          _section('5. Remove User from All Repos', 'Enter org and username. Iterates through every org repo. Use with caution on large orgs.'),

          StyledCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Available Roles', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 14),
            _roleRow('Read (pull)', 'Can view and clone the repository'),
            _roleRow('Triage', 'Can manage issues and pull requests'),
            _roleRow('Write (push)', 'Can push to the repository'),
            _roleRow('Maintain', 'Can manage without admin access'),
            _roleRow('Admin', 'Full access to the repository'),
          ])),

          StyledCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('API Rate Limits', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 14),
            _rateRow('Unauthenticated', '60/hour'),
            _rateRow('Authenticated (PAT)', '5,000/hour'),
            _rateRow('Enterprise Cloud', '15,000/hour'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
              child: Row(children: const [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.success),
                SizedBox(width: 8),
                Text('API calls are free. When limits are hit, requests are blocked until reset.', style: TextStyle(color: AppColors.success, fontSize: 12)),
              ]),
            ),
          ])),
        ],
      )),
    );
  }

  Widget _section(String title, String content) => StyledCard(
    margin: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 8),
      Text(content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.7)),
    ]),
  );

  Widget _roleRow(String role, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      SizedBox(width: 130, child: Text(role, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500))),
      Expanded(child: Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 12))),
    ]),
  );

  Widget _rateRow(String label, String limit) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 180, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
      Text(limit, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.primaryLight)),
    ]),
  );
}
