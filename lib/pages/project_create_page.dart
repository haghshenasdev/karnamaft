import 'package:flutter/material.dart';
import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';

class ProjectCreatePage extends StatefulWidget {
  const ProjectCreatePage({super.key});
  @override State<ProjectCreatePage> createState()=>_ProjectCreatePageState();
}
class _ProjectCreatePageState extends State<ProjectCreatePage> {
  final form=GlobalKey<FormState>();
  final name=TextEditingController(), description=TextEditingController(), requiredAmount=TextEditingController(), amount=TextEditingController();
  int status=1; bool saving=false;
  @override void dispose(){name.dispose();description.dispose();requiredAmount.dispose();amount.dispose();super.dispose();}
  Future<void> save() async {
    if(!form.currentState!.validate())return;
    setState(()=>saving=true);
    try{
      final r=await ApiClient.dio.post('/mobile/v1/projects',data:{
        'name':name.text.trim(),'description':description.text.trim(),'status':status,
        'required_amount':double.tryParse(requiredAmount.text),'amount':double.tryParse(amount.text),
      });
      if(mounted)Navigator.pop(context,r.data['data']);
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ApiErrorHandler.handle(e).toString())));
    }finally{if(mounted)setState(()=>saving=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('ایجاد دستورکار')),
    bottomNavigationBar:SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:FilledButton.icon(onPressed:saving?null:save,icon:saving?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save_outlined),label:const Text('ذخیره')))),
    body:Form(key:form,child:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,120),children:[
      TextFormField(controller:name,maxLines:2,decoration:const InputDecoration(labelText:'عنوان *',prefixIcon:Icon(Icons.title)),validator:(v)=>v==null||v.trim().isEmpty?'عنوان الزامی است':null),
      const SizedBox(height:14),
      TextFormField(controller:description,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'توضیحات',prefixIcon:Icon(Icons.notes_outlined))),
      const SizedBox(height:14),
      DropdownButtonFormField<int>(value:status,decoration:const InputDecoration(labelText:'وضعیت',prefixIcon:Icon(Icons.flag_outlined)),items:const[
        DropdownMenuItem(value:1,child:Text('فعال')),DropdownMenuItem(value:2,child:Text('در حال انجام')),DropdownMenuItem(value:3,child:Text('تکمیل شده')),
      ],onChanged:(v)=>setState(()=>status=v??1)),
      const SizedBox(height:14),
      Row(children:[
        Expanded(child:TextFormField(controller:requiredAmount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'اعتبار مورد نیاز',suffixText:'ریال'))),
        const SizedBox(width:12),
        Expanded(child:TextFormField(controller:amount,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'اعتبار اخذ شده',suffixText:'ریال'))),
      ]),
    ])),
  );
}
