import 'package:flutter/material.dart';
import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';

class TaskCreatePage extends StatefulWidget {
  const TaskCreatePage({super.key});
  @override State<TaskCreatePage> createState()=>_TaskCreatePageState();
}
class _TaskCreatePageState extends State<TaskCreatePage> {
  final form=GlobalKey<FormState>();
  final name=TextEditingController(), description=TextEditingController(), progress=TextEditingController(), amount=TextEditingController();
  int status=0; bool completed=false, repeat=false, saving=false;
  @override void dispose(){name.dispose();description.dispose();progress.dispose();amount.dispose();super.dispose();}
  Future<void> save() async {
    if(!form.currentState!.validate())return;
    setState(()=>saving=true);
    try{
      final r=await ApiClient.dio.post('/mobile/v1/tasks',data:{
        'name':name.text.trim(),'description':description.text.trim(),
        'status':status,'progress':int.tryParse(progress.text),'amount':double.tryParse(amount.text),
        'completed':completed?1:0,'repeat':repeat?1:0,
      });
      if(mounted)Navigator.pop(context,r.data['data']);
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ApiErrorHandler.handle(e).toString())));
    }finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('ایجاد فعالیت')),
    bottomNavigationBar:SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:FilledButton.icon(onPressed:saving?null:save,icon:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save_outlined),label:const Text('ذخیره')))),
    body:Form(key:form,child:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,120),children:[
      TextFormField(controller:name,maxLines:2,decoration:const InputDecoration(labelText:'عنوان *',prefixIcon:Icon(Icons.title)),validator:(v)=>v==null||v.trim().isEmpty?'عنوان الزامی است':null),
      const SizedBox(height:14),
      TextFormField(controller:description,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'توضیحات',prefixIcon:Icon(Icons.notes_outlined))),
      const SizedBox(height:14),
      DropdownButtonFormField<int>(value:status,decoration:const InputDecoration(labelText:'وضعیت',prefixIcon:Icon(Icons.flag_outlined)),items:const[
        DropdownMenuItem(value:0,child:Text('جدید')),DropdownMenuItem(value:1,child:Text('اتمام')),
        DropdownMenuItem(value:2,child:Text('در حال پیگیری')),DropdownMenuItem(value:3,child:Text('غیرقابل پیگیری')),
      ],onChanged:(v)=>setState(()=>status=v??0)),
      const SizedBox(height:14),
      Row(children:[
        Expanded(child:TextFormField(controller:progress,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'درصد انجام',suffixText:'%'))),
        const SizedBox(width:12),
        Expanded(child:TextFormField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'اعتبار',suffixText:'ریال'))),
      ]),
      const SizedBox(height:10),
      SwitchListTile.adaptive(value:completed,onChanged:(v)=>setState(()=>completed=v),title:const Text('انجام شده'),contentPadding:EdgeInsets.zero),
      SwitchListTile.adaptive(value:repeat,onChanged:(v)=>setState(()=>repeat=v),title:const Text('تکرارشونده'),contentPadding:EdgeInsets.zero),
    ])),
  );
}
