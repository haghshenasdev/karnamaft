
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/api_error_handler.dart';

class AnnouncementsPage extends StatefulWidget{const AnnouncementsPage({super.key});@override State<AnnouncementsPage> createState()=>_AnnouncementsPageState();}
class _AnnouncementsPageState extends State<AnnouncementsPage>{
  bool loading=true;String? error;List<Map<String,dynamic>> items=[];int page=1,lastPage=1;
  @override void initState(){super.initState();load();}
  Future<void> load({int p=1})async{setState(()=>loading=true);try{final r=await ApiClient.dio.get('/mobile/v1/notifications',queryParameters:{'page':p,'per_page':20});final j=Map<String,dynamic>.from(r.data);final m=Map<String,dynamic>.from(j['meta']??{});if(!mounted)return;setState((){items=(j['data'] as List? ?? []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();page:m['current_page']??1;lastPage:m['last_page']??1;});}catch(e){if(!mounted)return;setState(()=>error=ApiErrorHandler.handle(e).toString());}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> read(String id,int index)async{try{await ApiClient.dio.patch('/mobile/v1/notifications/$id/read');if(mounted)setState(()=>items[index]['read_at']=DateTime.now().toIso8601String());}catch(e){}}
  @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('اعلانات'),actions:[IconButton(onPressed:loading?null:()=>load(p:page),icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Text(error!)):ListView.builder(itemCount:items.length+1,itemBuilder:(c,i){if(i==items.length)return page<lastPage?Padding(padding:const EdgeInsets.all(16),child:FilledButton(onPressed:()=>load(p:page+1),child:const Text('نمایش بیشتر'))):const SizedBox(height:40);final n=items[i];final unread=n['read_at']==null;return ListTile(isThreeLine:true,leading:CircleAvatar(child:Icon(unread?Icons.notifications_active:Icons.notifications_none)),title:Text(n['title']?.toString()??'اعلان',style:TextStyle(fontWeight:unread?FontWeight.bold:FontWeight.normal)),subtitle:Text(n['message']?.toString()??''),onTap:()=>read(n['id'].toString(),i));}));
}
