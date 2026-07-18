import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:provider/provider.dart';

class ProfileHeader extends StatelessWidget {
  final UserController profile;

  final VoidCallback? onAvatarTap;

  const ProfileHeader({super.key, required this.profile, this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          children: [
            //-----------------------------------------
            // Avatar
            //-----------------------------------------
            Stack(
              children: [
                Hero(
                  tag: "profile_avatar",
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: profile.avatar.isNotEmpty
                        ? NetworkImage(
                            "https://hajideligani.ir/api/me/avatar",
                            headers: {
                              "Authorization": "Bearer ${profile.token}",
                            },
                          )
                        : null,
                    child: profile.avatar.isEmpty
                        ? Icon(
                            Icons.person_rounded,
                            size: 54,
                            color: colorScheme.primary,
                          )
                        : null,
                  ),
                ),

                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Material(
                    color: colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onAvatarTap,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            //-----------------------------------------
            // Name
            //-----------------------------------------
            SelectableText(
              context.read<UserController>().name,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            //-----------------------------------------
            // Email
            //-----------------------------------------
            SelectableText(
              profile.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
