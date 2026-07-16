import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/pages/profile_page.dart';
import 'package:karnamaft/pages/records_page.dart';
import 'package:karnamaft/pages/search_page.dart';
import 'package:karnamaft/storage/auth_storage.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});
  final user = UserController();

  @override
  Widget build(BuildContext context) {
    final List<_MenuItem> items = [
      _MenuItem(
        title: "یادداشت",
        icon: Icons.edit_note_rounded,
        color: Colors.blue,
        page: HomePage(),
      ),
      _MenuItem(
        title: "کارپوشه",
        icon: Icons.work_history,
        color: Colors.indigo,
        page: const RecordsPage(title: "کارپوشه"),
      ),
      _MenuItem(
        title: "صورت جلسه ها",
        icon: Icons.edit_document,
        color: Colors.amber,
        page: const RecordsPage(title: "صورت جلسه ها"),
      ),
      _MenuItem(
        title: "نامه ها",
        icon: Icons.markunread_sharp,
        color: Colors.green,
        page: const RecordsPage(title: "نامه ها"),
      ),
      _MenuItem(
        title: "فعالیت ها",
        icon: Icons.history_toggle_off,
        color: Colors.purple,
        page: const RecordsPage(title: "فعالیت ها"),
      ),
      _MenuItem(title: "گزارش", icon: Icons.bar_chart, color: Colors.red),
      _MenuItem(
        title: "تقویم",
        icon: Icons.calendar_month_rounded,
        color: Colors.teal,
      ),
      _MenuItem(
        title: "دستور کار",
        icon: Icons.star_rounded,
        color: Colors.orange,
        page: const RecordsPage(title: "دستور کار"),
      ),
      _MenuItem(
        title: "اعلانات",
        icon: Icons.notifications,
        color: Colors.grey,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      floatingActionButton: FloatingActionButton.large(
        elevation: 6,
        onPressed: () {},
        child: const Icon(Icons.add, size: 36),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            //---------------------------------------
            // Search
            //---------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SearchPage()),
                        );
                      },
                      child: Hero(
                        tag: "global_search",

                        child: Material(
                          color: Colors.transparent,

                          child: Container(
                            height: 56,

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(18),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),

                            child: IgnorePointer(
                              child: TextField(
                                enabled: false,

                                textAlignVertical: TextAlignVertical.center,

                                decoration: InputDecoration(
                                  hintText: "جستجو در همه اطلاعات...",

                                  border: InputBorder.none,

                                  contentPadding: EdgeInsets.zero,

                                  prefixIcon: const Center(
                                    widthFactor: 1,
                                    child: Icon(Icons.search),
                                  ),

                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 56,
                                    minHeight: 56,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                    },
                    child: Hero(
                      tag: "profile_avatar",
                      child: Consumer<UserController>(
                        builder: (_, user, __) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: () {
                              // صفحه پروفایل
                            },
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xffe9eef6),

                              backgroundImage: user.avatar.isNotEmpty
                                  ? NetworkImage(
                                      user.avatar,
                                      headers: {
                                        "Authorization":
                                            "Bearer ${AuthStorage.getToken()}",
                                      },
                                    )
                                  : null,

                              child: user.avatar.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.blueGrey,
                                      size: 30,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            //---------------------------------------
            // Grid
            //---------------------------------------
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                itemCount: items.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: .95,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      if (item.page != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => item.page!),
                        );
                      }
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(.12),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: item.color.withOpacity(.12),
                              child: Icon(
                                item.icon,
                                size: 30,
                                color: item.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget? page;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    this.page,
  });
}
