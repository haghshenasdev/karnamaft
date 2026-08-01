import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/pages/home_page.dart';
import 'package:karnamaft/pages/letter_show_page.dart';
import 'package:karnamaft/pages/minute_show_page.dart';
import 'package:karnamaft/pages/profile_page.dart';
import 'package:karnamaft/pages/project_show_page.dart';
import 'package:karnamaft/pages/records_page.dart';
import 'package:karnamaft/pages/search_page.dart';
import 'package:karnamaft/pages/task_show_page.dart';

import 'package:karnamaft/services/letter_service.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/services/project_service.dart';
import 'package:karnamaft/services/task_service.dart';

import 'package:provider/provider.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});

  final user = UserController();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 900) {
      return _buildDesktop(context);
    }

    return _buildMobile(context);
  }

  List<_MenuItem> _menuItems() {
    return [
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
      ),

      _MenuItem(
        title: "صورت جلسه ها",
        icon: Icons.edit_document,
        color: Colors.amber,

        page: RecordsPage(
          title: "صورت جلسه ها",
          service: const MinuteService(),

          showPageBuilder: (id, title) => MinuteShowPage(id: id, title: title),
        ),
      ),

      _MenuItem(
        title: "نامه ها",
        icon: Icons.markunread_sharp,
        color: Colors.green,

        page: RecordsPage(
          title: "نامه ها",
          service: const LetterService(),

          showPageBuilder: (id, title) => LetterShowPage(id: id, title: title),
        ),
      ),

      _MenuItem(
        title: "فعالیت ها",
        icon: Icons.history_toggle_off,
        color: Colors.purple,

        page: RecordsPage(
          title: "فعالیت ها",
          service: const TaskService(),

          showPageBuilder: (id, title) => TaskShowPage(id: id, title: title),
        ),
      ),

      _MenuItem(
        title: "دستور کار",
        icon: Icons.star_rounded,
        color: Colors.orange,

        page: RecordsPage(
          title: "دستورکار",
          service: const ProjectService(),

          showPageBuilder: (id, title) => ProjectShowPage(id: id, title: title),
        ),
      ),

      _MenuItem(title: "گزارش", icon: Icons.bar_chart, color: Colors.red),

      _MenuItem(
        title: "تقویم",
        icon: Icons.calendar_month_rounded,
        color: Colors.teal,
      ),

      _MenuItem(
        title: "اعلانات",
        icon: Icons.notifications,
        color: Colors.grey,
      ),
    ];
  }

  Widget _buildMobile(BuildContext context) {
    final items = _menuItems();

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
            // Search + Profile
            //---------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),

              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchPage()),
                        );
                      },

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

                        child: const Row(
                          children: [
                            SizedBox(width: 18),

                            Icon(Icons.search),

                            SizedBox(width: 12),

                            Text(
                              "جستجو در همه اطلاعات...",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Consumer<UserController>(
                    builder: (_, user, __) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(30),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
                        },

                        child: CircleAvatar(
                          radius: 28,

                          backgroundColor: const Color(0xffe9eef6),

                          backgroundImage: user.avatar.isNotEmpty
                              ? NetworkImage(
                                  "https://hajideligani.ir/api/me/avatar",

                                  headers: {
                                    "Authorization": "Bearer ${user.token}",
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
                  return _menuCard(context, items[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final items = _menuItems();

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      floatingActionButton: FloatingActionButton.large(
        elevation: 6,

        onPressed: () {},

        child: const Icon(Icons.add, size: 36),
      ),

      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,

          child: Padding(
            padding: const EdgeInsets.all(28),

            child: Column(
              children: [
                //--------------------------------
                // Search + Profile
                //--------------------------------
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),

                        onTap: () {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) => const SearchPage(),
                            ),
                          );
                        },

                        child: Container(
                          height: 64,

                          decoration: BoxDecoration(
                            color: Colors.white,

                            borderRadius: BorderRadius.circular(20),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.08),

                                blurRadius: 15,
                              ),
                            ],
                          ),

                          child: const Row(
                            children: [
                              SizedBox(width: 24),

                              Icon(Icons.search, size: 28),

                              SizedBox(width: 16),

                              Text(
                                "جستجو در همه اطلاعات...",

                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    Consumer<UserController>(
                      builder: (_, user, __) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(40),

                          onTap: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) => const ProfilePage(),
                              ),
                            );
                          },

                          child: CircleAvatar(
                            radius: 32,

                            backgroundColor: const Color(0xffe9eef6),

                            backgroundImage: user.avatar.isNotEmpty
                                ? NetworkImage(
                                    "https://hajideligani.ir/api/me/avatar",

                                    headers: {
                                      "Authorization": "Bearer ${user.token}",
                                    },
                                  )
                                : null,

                            child: user.avatar.isEmpty
                                ? const Icon(Icons.person, size: 35)
                                : null,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                //--------------------------------
                // Responsive Grid
                //--------------------------------
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 90),

                    itemCount: items.length,

                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,

                          crossAxisSpacing: 24,

                          mainAxisSpacing: 24,

                          childAspectRatio: 1.1,
                        ),

                    itemBuilder: (context, index) {
                      return _menuCard(context, items[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, _MenuItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),

      onTap: () {
        if (item.page != null) {
          Navigator.push(
            context,

            MaterialPageRoute(builder: (_) => item.page!),
          );
        }
      },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(24),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),

              blurRadius: 15,

              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 72,

              height: 72,

              decoration: BoxDecoration(
                color: item.color.withOpacity(.12),

                shape: BoxShape.circle,
              ),

              child: Icon(item.icon, size: 38, color: item.color),
            ),

            const SizedBox(height: 18),

            Text(
              item.title,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
