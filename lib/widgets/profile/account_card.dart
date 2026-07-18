import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';

class AccountCard extends StatelessWidget {
  final UserController profile;

  const AccountCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          children: [
            //------------------------------------
            // Header
            //------------------------------------
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(
                "اطلاعات حساب",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            const Divider(height: 8),

            //------------------------------------
            // First Name
            //------------------------------------
            _ProfileItem(
              icon: Icons.person_outline,
              title: "نام",
              value: profile.name,
            ),
            //------------------------------------
            // Mobile
            //------------------------------------

            // _ProfileItem(
            //   icon: Icons.phone_android_outlined,
            //   title: "شماره همراه",
            //   value: profile.mobile,
            // ),

            //------------------------------------
            // Position
            //------------------------------------

            // _ProfileItem(
            //   icon: Icons.work_outline,
            //   title: "سمت",
            //   value: profile.position,
            // ),

            //------------------------------------
            // Organization
            //------------------------------------

            // _ProfileItem(
            //   icon: Icons.apartment_outlined,
            //   title: "سازمان",
            //   value: profile.organization,
            // ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;

  final String title;

  final String value;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SelectableText(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
