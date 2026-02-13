import 'package:flutter/material.dart';
import '../constants.dart';
import '../widgets/styled_widgets.dart';

class UsernamesPage extends StatefulWidget {
  final List<String> savedUsers;
  final Function(String) onAdd;
  final Function(String) onRemove;

  const UsernamesPage({super.key, required this.savedUsers, required this.onAdd, required this.onRemove});

  @override
  State<UsernamesPage> createState() => _UsernamesPageState();
}

class _UsernamesPageState extends State<UsernamesPage> {
  final _ctrl = TextEditingController();

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isNotEmpty && !widget.savedUsers.contains(v)) {
      widget.onAdd(v);
      _ctrl.clear();
    }
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
          const PageHeader(title: 'Predefined Usernames', subtitle: 'Manage frequently used GitHub usernames. These appear as dropdown suggestions across all pages.'),

          StyledCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: StyledInput(controller: _ctrl, placeholder: 'Enter GitHub username', onSubmitted: (_) => _add())),
              const SizedBox(width: 12),
              PrimaryButton(label: 'Add', icon: Icons.add_rounded, onPressed: _add),
            ]),
            const SizedBox(height: 24),

            if (widget.savedUsers.isEmpty)
              Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(children: [
                  Icon(Icons.people_outline_rounded, size: 40, color: AppColors.textMuted.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text('No usernames added yet', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Add your team members above', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ]),
              )
            else
              Wrap(spacing: 8, runSpacing: 8, children: widget.savedUsers.map((u) => Container(
                padding: const EdgeInsets.only(left: 14, right: 6, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.4), AppColors.accent.withOpacity(0.4)]),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(u[0].toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Text('@$u', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => widget.onRemove(u),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, size: 13, color: AppColors.danger),
                    ),
                  ),
                ]),
              )).toList()),
          ])),
        ],
      )),
    );
  }
}
