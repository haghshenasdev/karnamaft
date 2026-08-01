import 'package:flutter/material.dart';

class RecordFilter {

  final String key;

  // نام فیلد در API
  final String field;

  final String title;

  final IconData icon;


  final Widget Function(
    BuildContext context,
    Map<String,String> values,
    VoidCallback refresh,
    String field,
  ) builder;


  const RecordFilter({
    required this.key,
    required this.field,
    required this.title,
    required this.icon,
    required this.builder,
  });

}