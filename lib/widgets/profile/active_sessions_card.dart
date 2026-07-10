import 'package:flutter/material.dart';
import 'package:karnamaft/models/profile_model.dart';


class ActiveSessionsCard extends StatelessWidget {
  final List<UserSession> sessions;

  final ValueChanged<UserSession>? onLogoutSession;

  const ActiveSessionsCard({
    super.key,
    required this.sessions,
    this.onLogoutSession,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        leading: const Icon(Icons.devices_outlined),
        title: Text(
          "نشست‌های فعال",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${sessions.length} نشست فعال"),
        children: sessions
            .map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SessionCard(
                  session: session,
                  onLogout: () {
                    onLogoutSession?.call(session);
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final UserSession session;

  final VoidCallback? onLogout;

  const _SessionCard({required this.session, this.onLogout});

  IconData _deviceIcon() {
    switch (session.platform.toLowerCase()) {
      case "android":
        return Icons.phone_android;

      case "ios":
        return Icons.phone_iphone;

      case "desktop":
      case "windows":
      case "macos":
      case "linux":
        return Icons.laptop_windows;

      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //----------------------------------
            // Header
            //----------------------------------
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(_deviceIcon(), color: colorScheme.primary),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.deviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        session.browser,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),

                if (session.current)
                  FilledButton.tonalIcon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle),
                    label: const Text("این دستگاه"),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            //----------------------------------
            // Details
            //----------------------------------
            _InfoRow(title: "سیستم عامل", value: session.platform),

            _InfoRow(title: "IP", value: session.ip),

            _InfoRow(title: "محل اتصال", value: session.location),

            _InfoRow(title: "آخرین فعالیت", value: session.lastActivity),

            const SizedBox(height: 12),

            //----------------------------------
            // Logout Button
            //----------------------------------
            if (!session.current)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text("خروج از این دستگاه"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;

  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),

          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
