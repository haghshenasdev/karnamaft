import 'package:flutter/material.dart';
import 'package:karnamaft/models/letter_model.dart';

class UserChipList extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<LetterUser> users;
  final String token;

  const UserChipList({
    super.key,
    required this.title,
    required this.icon,
    required this.users,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: users.map((user) {
            return Chip(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

              avatar: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xffe9eef6),

                backgroundImage:
                    (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                    ? NetworkImage(
                        "https://hajideligani.ir/api/get_avatar/${user.avatarUrl}",
                        headers: {"Authorization": "Bearer $token"},
                      )
                    : null,

                child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 22)
                    : null,
              ),

              label: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
