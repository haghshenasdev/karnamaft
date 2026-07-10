import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  static const String _website = "https://haghshenasdev.github.io/";

  Future<void> _openWebsite() async {
    final uri = Uri.parse(_website);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            //---------------------------------------
            // Header
            //---------------------------------------
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(
                "درباره برنامه",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),

            const Divider(height: 8),

            //---------------------------------------
            // Version
            //---------------------------------------
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: const Text("نسخه برنامه"),
              subtitle: const Text("1.0.0"),
            ),

            //---------------------------------------
            // Developer
            //---------------------------------------
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text("برنامه نویس"),
              subtitle: const Text("محمد مهدی حق شناس"),
              trailing: const Icon(Icons.open_in_new),
              onTap: _openWebsite,
            ),

            //---------------------------------------
            // Website
            //---------------------------------------
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text("وب سایت"),
              subtitle: const Text(_website),
              trailing: const Icon(Icons.open_in_new),
              onTap: _openWebsite,
            ),
          ],
        ),
      ),
    );
  }
}
