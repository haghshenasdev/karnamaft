import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';

class PermissionsCard extends StatelessWidget {
  final UserController user;
  const PermissionsCard({super.key,required this.user});

  @override Widget build(BuildContext context){
    final cs=Theme.of(context).colorScheme;
    return Card(
      margin:const EdgeInsets.symmetric(horizontal:16),
      color:cs.surfaceContainerLow,
      child:ExpansionTile(
        leading:const Icon(Icons.admin_panel_settings_outlined),
        title:const Text('نقش و دسترسی‌ها'),
        subtitle:Text('${user.user?.roles.length ?? 0} نقش • ${user.user?.permissions.length ?? 0} دسترسی'),
        childrenPadding:const EdgeInsets.fromLTRB(16,0,16,16),
        children:[
          if(user.user?.roles.isNotEmpty==true)
            Align(alignment:Alignment.centerRight,child:Wrap(spacing:6,runSpacing:6,children:user.user!.roles.map((r)=>Chip(label:Text(r))).toList())),
          if(user.user?.roles.isNotEmpty==true && user.user?.permissions.isNotEmpty==true) const SizedBox(height:10),
          if(user.user?.permissions.isNotEmpty==true)
            Align(alignment:Alignment.centerRight,child:Wrap(spacing:6,runSpacing:6,children:user.user!.permissions.map((p)=>InputChip(avatar:const Icon(Icons.check,size:15),label:Text(_label(p)))).toList())),
          if(user.user?.permissions.isEmpty!=false) const Text('دسترسی‌ای برای این حساب گزارش نشده است.'),
        ],
      ),
    );
  }

  String _label(String value)=>value
    .replaceAll('view_any_', 'مشاهده ')
    .replaceAll('create_', 'ایجاد ')
    .replaceAll('update_', 'ویرایش ')
    .replaceAll('delete_', 'حذف ')
    .replaceAll('_', ' ');
}
