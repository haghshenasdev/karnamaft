import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/pages/cartable_page.dart';
import 'package:karnamaft/pages/home_page.dart';
import 'package:karnamaft/pages/letter_create_page.dart';
import 'package:karnamaft/pages/letter_show_page.dart';
import 'package:karnamaft/pages/minute_create_page.dart';
import 'package:karnamaft/pages/minute_show_page.dart';
import 'package:karnamaft/pages/profile_page.dart';
import 'package:karnamaft/pages/project_create_page.dart';
import 'package:karnamaft/pages/project_show_page.dart';
import 'package:karnamaft/pages/records_page.dart';
import 'package:karnamaft/pages/search_page.dart';
import 'package:karnamaft/pages/task_create_page.dart';
import 'package:karnamaft/pages/task_show_page.dart';
import 'package:karnamaft/services/letter_service.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/services/project_service.dart';
import 'package:karnamaft/services/task_service.dart';
import 'package:provider/provider.dart';

/// صفحه اصلی برنامه.
///
/// این صفحه عمداً نقش «داشبورد» دارد و به جای جایگزین کردن آن با
/// NavigationRail/NavigationBar، تمام امکانات اصلی برنامه را به صورت کارت
/// در اختیار کاربر می‌گذارد. دسترسی هر کارت نیز از permissionهای Laravel
/// خوانده می‌شود.
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _comingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('صفحه «$title» هنوز در نسخه موبایل تکمیل نشده است.')),
      );
  }

  List<_MenuItem> _items(BuildContext context, UserController user) {
    final items = <_MenuItem>[
      const _MenuItem(
        title: 'دفترچه یادداشت',
        subtitle: 'یادداشت‌برداری و تبدیل یادداشت به صورتجلسه',
        icon: Icons.edit_note_rounded,
        color: Color(0xff2563eb),
        page: HomePage(),
      ),
      if (user.canManageCartable)
        const _MenuItem(
          title: 'کارپوشه',
          subtitle: 'نامه‌ها و ارجاعات دریافتی',
          icon: Icons.inbox_rounded,
          color: Color(0xff4f46e5),
          page: CartablePage(),
        ),
      if (user.canManageLetters)
        _MenuItem(
          title: 'نامه‌ها',
          subtitle: 'مشاهده، جستجو و ثبت نامه',
          icon: Icons.mark_email_read_rounded,
          color: Color(0xff059669),
          page: RecordsPage(
            title: 'نامه ها',
            service: const LetterService(),
            showPageBuilder: (id, title) => LetterShowPage(id: id, title: title),
            createPageBuilder: user.can('create_letter')
                ? () => const LetterCreatePage()
                : null,
            createSuccessMessage: 'نامه با موفقیت ایجاد شد',
          ),
        ),
      if (user.canManageMinutes)
        _MenuItem(
          title: 'صورتجلسه‌ها',
          subtitle: 'مشاهده، جستجو و ثبت صورتجلسه',
          icon: Icons.description_rounded,
          color: Color(0xffd97706),
          page: RecordsPage(
            title: 'صورت جلسه ها',
            service: const MinuteService(),
            showPageBuilder: (id, title) => MinuteShowPage(id: id, title: title),
            createPageBuilder: user.can('create_minutes')
                ? () => const MinuteCreatePage()
                : null,
            createSuccessMessage: 'صورتجلسه با موفقیت ایجاد شد',
          ),
        ),
      if (user.canManageTasks)
        _MenuItem(
          title: 'فعالیت‌ها',
          subtitle: 'پیگیری فعالیت‌ها و وضعیت آن‌ها',
          icon: Icons.task_alt_rounded,
          color: Color(0xff9333ea),
          page: RecordsPage(
            title: 'فعالیت ها',
            service: const TaskService(),
            showPageBuilder: (id, title) => TaskShowPage(id: id, title: title),
            createPageBuilder: user.can('create_task')
                ? () => const TaskCreatePage()
                : null,
            createSuccessMessage: 'فعالیت با موفقیت ایجاد شد',
          ),
        ),
      if (user.canManageProjects)
        _MenuItem(
          title: 'دستورکار',
          subtitle: 'مدیریت دستورکارها و پروژه‌ها',
          icon: Icons.work_history_rounded,
          color: Color(0xffea580c),
          page: RecordsPage(
            title: 'دستورکار',
            service: const ProjectService(),
            showPageBuilder: (id, title) => ProjectShowPage(id: id, title: title),
            createPageBuilder: user.can('create_project')
                ? () => const ProjectCreatePage()
                : null,
            createSuccessMessage: 'دستورکار با موفقیت ایجاد شد',
          ),
        ),
      _MenuItem(
        title: 'گزارش‌ها',
        subtitle: 'گزارش‌ها و آمار سامانه',
        icon: Icons.analytics_rounded,
        color: Color(0xffdc2626),
        onTap: () => _comingSoon(context, 'گزارش‌ها'),
      ),
      _MenuItem(
        title: 'تقویم',
        subtitle: 'رویدادها و برنامه‌های کاری',
        icon: Icons.calendar_month_rounded,
        color: Color(0xff0891b2),
        onTap: () => _comingSoon(context, 'تقویم'),
      ),
      _MenuItem(
        title: 'اعلانات',
        subtitle: 'اعلان‌ها و پیام‌های سامانه',
        icon: Icons.notifications_active_rounded,
        color: Color(0xff64748b),
        onTap: () => _comingSoon(context, 'اعلانات'),
      ),
    ];
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserController>();
    final width = MediaQuery.sizeOf(context).width;
    final items = _items(context, user);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('کارنامه'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'جستجوی سراسری',
            onPressed: () => _open(context, const SearchPage()),
            icon: const Icon(Icons.search_rounded),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: IconButton(
              tooltip: 'حساب کاربری',
              onPressed: () => _open(context, const ProfilePage()),
              icon: _Avatar(user: user),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(context, user)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _MenuCard(
                    item: items[index],
                    onTap: () {
                      final item = items[index];
                      if (item.page != null) {
                        _open(context, item.page!);
                      } else {
                        item.onTap?.call();
                      }
                    },
                  ),
                  childCount: items.length,
                ),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: width >= 1200 ? 330 : 380,
                  mainAxisExtent: width >= 700 ? 174 : 158,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, const SearchPage()),
        icon: const Icon(Icons.search_rounded),
        label: const Text('جستجوی سراسری'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final BuildContext parentContext;
  final UserController user;
  const _Header(this.parentContext, this.user);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Card(
        elevation: 0,
        color: scheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => Navigator.of(parentContext).push(
            MaterialPageRoute(builder: (_) => const SearchPage()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 32, color: scheme.onPrimaryContainer),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('جستجوی سراسری', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('در نامه‌ها، صورتجلسه‌ها، فعالیت‌ها و دستورکارها جستجو کنید'),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final UserController user;
  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      child: user.avatar.isEmpty
          ? const Icon(Icons.person_outline_rounded)
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: 'https://hajideligani.ir/api/me/avatar',
                httpHeaders: {'Authorization': 'Bearer ${user.token}'},
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.person_outline_rounded),
              ),
            ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;
  const _MenuCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(item.icon, size: 32, color: item.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 7),
                    Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? page;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.page,
    this.onTap,
  });
}
