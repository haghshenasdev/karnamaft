
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'letter_create_page.dart';
import 'minute_create_page.dart';
import 'task_create_page.dart';

class IncomingSharePage extends StatefulWidget {
  final String filePath;
  const IncomingSharePage({super.key,required this.filePath});
  @override State<IncomingSharePage> createState()=>_IncomingSharePageState();
}
class _IncomingSharePageState extends State<IncomingSharePage>{
  Uint8List? bytes; bool loading=true;
  @override void initState(){super.initState();_load();}
  Future<void>_load()async{try{bytes=await File(widget.filePath).readAsBytes();}catch(_){ }if(mounted)setState(()=>loading=false);}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('ثبت فایل دریافت‌شده')),
    body:ListView(padding:const EdgeInsets.all(20),children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[
        const Icon(Icons.file_present,size:42),const SizedBox(width:12),Expanded(child:Text(widget.filePath.split(Platform.pathSeparator).last,maxLines:2,overflow:TextOverflow.ellipsis)),
      ]))),
      const SizedBox(height:20),
      const Text('این فایل را در کدام موجودیت ثبت می‌کنید؟',style:TextStyle(fontWeight:FontWeight.bold)),
      const SizedBox(height:12),
      _Action(icon:Icons.mail_outline,title:'ایجاد نامه',onTap:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>LetterCreatePage(initialFilePath:widget.filePath)))),
      _Action(icon:Icons.description_outlined,title:'ایجاد صورتجلسه',onTap:loading||bytes==null?null:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>MinuteCreatePage(initialFileBytes:bytes,initialFileName:widget.filePath.split(Platform.pathSeparator).last)))),
      _Action(icon:Icons.task_alt,title:'ایجاد فعالیت',onTap:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>TaskCreatePage(initialFilePath:widget.filePath)))),
    ]),
  );
}
class _Action extends StatelessWidget{final IconData icon;final String title;final VoidCallback? onTap;const _Action({required this.icon,required this.title,required this.onTap});@override Widget build(BuildContext c)=>Card(elevation:0,child:ListTile(enabled:onTap!=null,leading:CircleAvatar(child:Icon(icon)),title:Text(title),trailing:const Icon(Icons.chevron_left),onTap:onTap));}
