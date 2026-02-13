import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'services/storage_service.dart';
import 'platform/github_backend.dart';
import 'platform/platform_selector.dart' as platform;
import 'pages/settings_page.dart';
import 'pages/create_repo_page.dart';
import 'pages/manage_users_page.dart';
import 'pages/remove_user_page.dart';
import 'pages/usernames_page.dart';
import 'pages/help_page.dart';

void main() => runApp(const GitHubAdminApp());

class GitHubAdminApp extends StatelessWidget {
  const GitHubAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(AppColors.textMuted.withOpacity(0.3)),
          thickness: WidgetStateProperty.all(4),
          radius: const Radius.circular(4),
        ),
      ),
      home: const AdminShell(),
    );
  }
}

enum NavPage { settings, create, manage, remove, users, help }

class _Nav {
  final NavPage id;
  final IconData icon;
  final String label;
  final bool requiresToken;
  const _Nav(this.id, this.icon, this.label, {this.requiresToken = false});
}

const _navItems = [
  _Nav(NavPage.settings, Icons.settings_rounded, 'Settings'),
  _Nav(NavPage.create, Icons.add_box_rounded, 'Create Repo', requiresToken: true),
  _Nav(NavPage.manage, Icons.people_rounded, 'Manage Users', requiresToken: true),
  _Nav(NavPage.remove, Icons.delete_sweep_rounded, 'Remove User', requiresToken: true),
  _Nav(NavPage.users, Icons.badge_rounded, 'Usernames'),
  _Nav(NavPage.help, Icons.help_rounded, 'How to Use'),
];

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  NavPage _page = NavPage.settings;
  String _token = '';
  bool _tokenSaved = false;
  List<String> _savedUsers = [];
  late GitHubBackend _backend;

  @override
  void initState() {
    super.initState();
    _backend = platform.createBackend();
    _load();
  }

  Future<void> _load() async {
    final token = await StorageService.getToken();
    final users = await StorageService.getUsers();
    setState(() {
      if (token != null && token.isNotEmpty) { _token = token; _tokenSaved = true; }
      _savedUsers = users;
    });
  }

  Future<void> _saveToken() async {
    await StorageService.setToken(_token);
    setState(() => _tokenSaved = true);
  }

  Future<void> _addUser(String u) async {
    if (!_savedUsers.contains(u)) {
      setState(() => _savedUsers.add(u));
      await StorageService.setUsers(_savedUsers);
    }
  }

  Future<void> _removeUser(String u) async {
    setState(() => _savedUsers.remove(u));
    await StorageService.setUsers(_savedUsers);
  }

  void _nav(NavPage p) {
    final item = _navItems.firstWhere((n) => n.id == p);
    if (item.requiresToken && !_tokenSaved) {
      setState(() => _page = NavPage.settings);
      return;
    }
    setState(() => _page = p);
  }

  Widget _buildPage() {
    switch (_page) {
      case NavPage.settings:
        return SettingsPage(token: _token, tokenSaved: _tokenSaved, onTokenChanged: (v) => setState(() => _token = v), onSave: _saveToken);
      case NavPage.create:
        return CreateRepoPage(token: _token, savedUsers: _savedUsers, backend: _backend);
      case NavPage.manage:
        return ManageUsersPage(token: _token, savedUsers: _savedUsers, backend: _backend);
      case NavPage.remove:
        return RemoveUserPage(token: _token, savedUsers: _savedUsers, backend: _backend);
      case NavPage.users:
        return UsernamesPage(savedUsers: _savedUsers, onAdd: _addUser, onRemove: _removeUser);
      case NavPage.help:
        return const HelpPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        // ─── Sidebar ────────────────────────────────────
        Container(
          width: 250,
          decoration: const BoxDecoration(
            color: AppColors.sidebar,
            border: Border(right: BorderSide(color: AppColors.sidebarBorder)),
          ),
          child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.sidebarBorder))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.accent.withOpacity(0.2)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hexagon_rounded, color: AppColors.primaryLight, size: 20),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text('GitHub Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.3)),
                  SizedBox(height: 2),
                  Text('Repo Management', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ]),
              ]),
            ),

            // Nav
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: _navItems.map((n) {
                final active = _page == n.id;
                final disabled = n.requiresToken && !_tokenSaved;
                return Opacity(
                  opacity: disabled ? 0.35 : 1,
                  child: Material(color: Colors.transparent, child: InkWell(
                    onTap: () => _nav(n.id),
                    hoverColor: AppColors.sidebarActive.withOpacity(0.5),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: active ? AppColors.sidebarActive : Colors.transparent,
                        border: Border(left: BorderSide(color: active ? AppColors.primary : Colors.transparent, width: 3)),
                      ),
                      child: Row(children: [
                        Icon(n.icon, size: 18, color: active ? AppColors.primaryLight : AppColors.textMuted),
                        const SizedBox(width: 12),
                        Text(n.label, style: TextStyle(
                          fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          color: active ? Colors.white : AppColors.textMuted,
                        )),
                        if (n.requiresToken && disabled) ...[
                          const Spacer(),
                          const Icon(Icons.lock_rounded, size: 12, color: AppColors.textMuted),
                        ],
                      ]),
                    ),
                  )),
                );
              }).toList()),
            )),

            // Footer
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.sidebarBorder))),
              child: Column(children: [
                // Platform badge
                Row(children: [
                  Icon(platform.isMacOS ? Icons.terminal_rounded : Icons.language_rounded,
                    size: 13, color: platform.isMacOS ? AppColors.accent : AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Text(platform.isMacOS ? 'macOS · Scripts' : 'Web · HTTP',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                      color: platform.isMacOS ? AppColors.accent : AppColors.primaryLight)),
                ]),
                if (_tokenSaved) ...[
                  const SizedBox(height: 10),
                  Row(children: const [
                    Icon(Icons.circle, size: 7, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Token configured', style: TextStyle(fontSize: 11, color: AppColors.success)),
                  ]),
                ],
              ]),
            ),
          ]),
        ),

        // ─── Content ────────────────────────────────────
        Expanded(child: _buildPage()),
      ]),
    );
  }
}
