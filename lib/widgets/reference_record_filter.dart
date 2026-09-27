
import 'package:flutter/material.dart';
import '../api/api_client.dart';

class ReferenceRecordFilter extends StatefulWidget {
  final String resource;
  final Map<String,String> values;
  final String field;
  final VoidCallback refresh;
  final String label;
  const ReferenceRecordFilter({super.key,required this.resource,required this.values,required this.field,required this.refresh,required this.label});
  @override State<ReferenceRecordFilter> createState()=>_ReferenceRecordFilterState();
}
class _ReferenceRecordFilterState extends State<ReferenceRecordFilter>{
  List<Map<String,dynamic>> items=[];bool loading=true;
  @override void initState(){super.initState();load();}
  Future<void>load()async{try{final r=await ApiClient.dio.get('/mobile/v1/${widget.resource}/reference',queryParameters:{'limit':100});final list=(r.data['data'] as List? ?? []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();if(mounted)setState(()=>items=list);}catch(e){if(mounted)setState(()=>loading=false);}}
  @override Widget build(BuildContext c)=>DropdownButtonFormField<String>(
    value: widget.values[widget.field]?.isEmpty==true?null:widget.values[widget.field],
    decoration: InputDecoration(labelText:widget.label),
    isExpanded:true,
    items:[const DropdownMenuItem(value:'',child:Text('همه')), ...items.map((e)=>DropdownMenuItem(value:e['id'].toString(),child:Text(e['name']?.toString()??'')))],
    onChanged:(v){widget.values[widget.field]=v??'';widget.refresh();},
  );
}
