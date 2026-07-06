import 'package:flutter/material.dart';

import 'home_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_MenuItem> items = [
      _MenuItem(
        title: "یادداشت",
        icon: Icons.edit_note_rounded,
        color: Colors.blue,
        page: const HomePage(),
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
      ),
      _MenuItem(
        title: "نامه ها",
        icon: Icons.markunread_sharp,
        color: Colors.green,
      ),
      _MenuItem(
        title: "فعالیت ها",
        icon: Icons.history_toggle_off,
        color: Colors.purple,
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
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "جستجو...",
                    prefixIcon: const Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            //---------------------------------------
            // Title
            //---------------------------------------
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "دسترسی سریع",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 15),

            //---------------------------------------
            // Grid
            //---------------------------------------
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                itemCount: items.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
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
