import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  final VoidCallback? onNewDiagnosis;

  const AppDrawer({super.key, this.onNewDiagnosis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = ref.watch(currentUserProvider);

    return Drawer(
      child: Column( 
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
                user?.displayName ?? "SonicFix User", 
                style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            accountEmail: Text(user?.email ?? "mechanic@sonicfix.ai"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null 
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const Text('New Diagnosis'),
                    onTap: () {
                      Navigator.pop(context); // Close drawer first
                      onNewDiagnosis?.call();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('History'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Profile'),
                    onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/profile');
                    }, 
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text("Dark Mode"),
                    secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    value: isDark,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                  ),
              ],
            ),
          ),
          
          // Logout Button at Bottom
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Sign Out", style: TextStyle(color: Colors.red)),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Sign Out"),
                  content: const Text("Are you sure you want to sign out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                   Navigator.of(context).popUntil((route) => route.isFirst);
                   Navigator.pushReplacementNamed(context, '/auth_wrapper');
                }
              }
            },
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}
