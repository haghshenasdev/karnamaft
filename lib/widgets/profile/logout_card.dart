import 'package:flutter/material.dart';

class LogoutCard extends StatelessWidget {
  final VoidCallback? onLogout;

  const LogoutCard({super.key, this.onLogout});

  Future<void> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.logout_rounded, size: 36),
          title: const Text("خروج از حساب"),
          content: const Text(
            "آیا از خروج از حساب کاربری اطمینان دارید؟",
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("انصراف"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("خروج"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      onLogout?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      color: colorScheme.errorContainer.withOpacity(.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.logout_rounded, color: colorScheme.error, size: 42),

            const SizedBox(height: 12),

            Text(
              "خروج از حساب کاربری",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              "با خروج از حساب، برای استفاده مجدد باید دوباره وارد برنامه شوید.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                onPressed: () {
                  _showLogoutDialog(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text("خروج از حساب"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
