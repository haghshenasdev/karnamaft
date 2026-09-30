import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/content_model.dart';
import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_filter.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/RecordService.dart';
import 'package:karnamaft/widgets/content_group_filter.dart';

class ContentService implements RecordService<ContentModel>{
 const ContentService(); final String rootPath='/mobile/v1/contents';
 @override List<RecordFilter> get filters => [
    RecordFilter(
      key: 'group_id',
      field: 'group_id',
      title: 'دسته‌بندی',
      icon: Icons.label_outline,
      builder: (context, values, refresh, field) => ContentGroupFilter(
        values: values,
        field: field,
        onChanged: refresh,
      ),
    ),
  ];
 @override Future<PageResult<RecordItem>> list({int page=1,String? search,String? sort,Map<String,String>? filters})async{try{final q=<String,dynamic>{'page':page};if(search?.isNotEmpty==true)q['search']=search;if(sort!=null)q['sort']=sort;filters?.forEach((k,v){if(v.isNotEmpty)q['filter[$k]']=v;});final r=await ApiClient.dio.get(rootPath,queryParameters:q);final data=(r.data['data'] as List? ?? []).map((e)=>ContentModel.fromJson(Map<String,dynamic>.from(e))).toList();final m=Map<String,dynamic>.from(r.data['meta']??{});return PageResult(data:data.map((e)=>e.toRecord()).toList(),currentPage:m['current_page']??1,lastPage:m['last_page']??1,total:m['total']??data.length,perPage:m['per_page']??data.length);}catch(e){throw ApiErrorHandler.handle(e);}}
 Future<ContentModel> show(int id)async{try{final r=await ApiClient.dio.get('$rootPath/$id');return ContentModel.fromJson(Map<String,dynamic>.from(r.data['data']));}catch(e){throw ApiErrorHandler.handle(e);}}
 Future<ContentModel> create({required String title,required List<int> groupIds,List<Map<String,dynamic>> body=const [],Uint8List? uploadBytes,String? uploadFileName})async{try{final f=FormData();f.fields..add(MapEntry('title',title))..add(MapEntry('body',jsonEncode(body)));for(final id in groupIds)f.fields.add(MapEntry('group_ids[]','$id'));if(uploadBytes!=null)f.files.add(MapEntry('upload_file',MultipartFile.fromBytes(uploadBytes,filename:uploadFileName??'note.png')));final r=await ApiClient.dio.post(rootPath,data:f,options:Options(contentType:'multipart/form-data',sendTimeout:const Duration(minutes:2),receiveTimeout:const Duration(minutes:2)));return ContentModel.fromJson(Map<String,dynamic>.from(r.data['data']));}catch(e){throw ApiErrorHandler.handle(e);}}
 Future<ContentModel> update(int id,{required String title,required List<int> groupIds,List<Map<String,dynamic>> body=const [],Uint8List? uploadBytes,String? uploadFileName})async{try{final f=FormData();f.fields..add(MapEntry('_method','PUT'))..add(MapEntry('title',title))..add(MapEntry('body',jsonEncode(body)));for(final gid in groupIds)f.fields.add(MapEntry('group_ids[]','$gid'));if(uploadBytes!=null)f.files.add(MapEntry('upload_file',MultipartFile.fromBytes(uploadBytes,filename:uploadFileName??'note.png')));final r=await ApiClient.dio.post('$rootPath/$id',data:f,options:Options(contentType:'multipart/form-data',sendTimeout:const Duration(minutes:2),receiveTimeout:const Duration(minutes:2)));return ContentModel.fromJson(Map<String,dynamic>.from(r.data['data']));}catch(e){throw ApiErrorHandler.handle(e);}}
 Future<Uint8List?> downloadPart(String url)async{try{final r=await ApiClient.dio.get<List<int>>(url,options:Options(responseType:ResponseType.bytes));return r.data==null?null:Uint8List.fromList(r.data!);}catch(e){throw ApiErrorHandler.handle(e);}}
 @override Future<bool> delete(int id)async{try{return (await ApiClient.dio.delete('$rootPath/$id')).statusCode==200;}catch(e){throw ApiErrorHandler.handle(e);}}
}
