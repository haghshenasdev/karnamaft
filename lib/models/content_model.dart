import 'package:karnamaft/models/record_item.dart';

class ContentGroupModel {
  final int id; final String name; final int? parentId;
  const ContentGroupModel({required this.id,required this.name,this.parentId});
  factory ContentGroupModel.fromJson(Map<String,dynamic> j)=>ContentGroupModel(id:j['id']??0,name:j['name']?.toString()??'',parentId:j['parent_id']==null?null:int.tryParse('${j['parent_id']}'));
}
class ContentPart {
  final String type; final String? text,file,name,url,mime,drawing,drawingUrl;
  const ContentPart({required this.type,this.text,this.file,this.name,this.url,this.mime,this.drawing,this.drawingUrl});
  factory ContentPart.fromJson(Map<String,dynamic> j)=>ContentPart(type:j['type']?.toString()??'text',text:j['text']?.toString(),file:j['file']?.toString(),name:j['name']?.toString(),url:j['url']?.toString(),mime:j['mime']?.toString(),drawing:j['drawing']?.toString(),drawingUrl:j['drawing_url']?.toString());
  Map<String,dynamic> toJson()=>{'type':type,if(text!=null)'text':text,if(file!=null)'file':file,if(name!=null)'name':name,if(mime!=null)'mime':mime,if(drawing!=null)'drawing':drawing};
}
class ContentModel {
  final int id; final String title; final int? userId; final List<ContentGroupModel> groups; final List<ContentPart> body; final DateTime? createdAt,updatedAt;
  const ContentModel({required this.id,required this.title,this.userId,required this.groups,required this.body,this.createdAt,this.updatedAt});
  factory ContentModel.fromJson(Map<String,dynamic> j)=>ContentModel(id:j['id']??0,title:j['title']?.toString()??'',userId:j['user_id']==null?null:int.tryParse('${j['user_id']}'),groups:(j['groups'] as List? ?? j['group'] as List? ?? []).map((e)=>ContentGroupModel.fromJson(Map<String,dynamic>.from(e))).toList(),body:(j['body'] as List? ?? []).map((e)=>ContentPart.fromJson(Map<String,dynamic>.from(e))).toList(),createdAt:j['created_at']==null?null:DateTime.tryParse('${j['created_at']}'),updatedAt:j['updated_at']==null?null:DateTime.tryParse('${j['updated_at']}'));
  List<Map<String,dynamic>> get bodyJson=>body.map((e)=>e.toJson()).toList();
  RecordItem toRecord()=>RecordItem(id:id,title:title,description:body.where((e)=>e.type=='text').map((e)=>e.text).whereType<String>().join('\n'),date:createdAt,tag:groups.map((e)=>e.name).where((e)=>e.trim().isNotEmpty).join('، ').isEmpty?null:groups.map((e)=>e.name).where((e)=>e.trim().isNotEmpty).join('، '),hasAttachment:body.any((e)=>e.file!=null||e.drawing!=null));
}
