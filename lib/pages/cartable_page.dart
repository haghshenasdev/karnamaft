import 'package:flutter/material.dart';
import 'package:karnamaft/models/cartable_model.dart';
import 'package:karnamaft/pages/letter_show_page.dart';
import 'package:karnamaft/services/cartable_service.dart';

class CartablePage extends StatefulWidget {
  const CartablePage({super.key});
  @override State<CartablePage> createState() => _CartablePageState();
}

class _CartablePageState extends State<CartablePage> {
  final service = const CartableService();
  final search = TextEditingController();
  final scroll = ScrollController();
  List<CartableModel> items = [];
  bool loading = true, loadingMore = false;
  bool? showOnlyUnread;
  int page = 1, lastPage = 1;

  @override void initState() {
    super.initState();
    load();
    scroll.addListener(() {
      if (scroll.position.pixels > scroll.position.maxScrollExtent - 300) loadMore();
    });
  }
  @override void dispose(){ search.dispose(); scroll.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(()=>loading=true);
    try {
      final r=await service.list(search: search.text, checked: showOnlyUnread == null ? null : !showOnlyUnread!);
      if (!mounted) return;
      setState(()=>items=r.data..sort((a,b)=>(a.checked?1:0).compareTo(b.checked?1:0)));
      page=r.currentPage; lastPage=r.lastPage;
    } finally { if(mounted)setState(()=>loading=false); }
  }
  Future<void> loadMore() async {
    if(loadingMore || page>=lastPage)return;
    setState(()=>loadingMore=true);
    try {
      final r=await service.list(page:page+1,search:search.text,checked:showOnlyUnread==null?null:!showOnlyUnread!);
      if(!mounted)return;
      setState(()=>items.addAll(r.data));
      page=r.currentPage; lastPage=r.lastPage;
    } finally { if(mounted)setState(()=>loadingMore=false); }
  }

  @override Widget build(BuildContext context) {
    final cs=Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('کارپوشه'),
        actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh_rounded))],
      ),
      body: Column(children:[
        Padding(
          padding: const EdgeInsets.fromLTRB(16,8,16,8),
          child: SearchBar(
            controller: search,
            hintText:'جستجوی نامه در کارپوشه',
            leading:const Icon(Icons.search_rounded),
            trailing:[if(search.text.isNotEmpty)IconButton(onPressed:(){search.clear();load();setState((){});},icon:const Icon(Icons.clear))],
            onChanged:(_)=>setState((){}),
            onSubmitted:(_)=>load(),
          ),
        ),
        Padding(
          padding:const EdgeInsets.fromLTRB(16,0,16,10),
          child: SingleChildScrollView(
            scrollDirection:Axis.horizontal,
            child:Row(children:[
              ChoiceChip(label:const Text('همه'),selected:showOnlyUnread==null,onSelected:(_){setState(()=>showOnlyUnread=null);load();}),
              const SizedBox(width:8),
              ChoiceChip(label:const Text('خوانده نشده'),selected:showOnlyUnread==true,onSelected:(_){setState(()=>showOnlyUnread=true);load();}),
              const SizedBox(width:8),
              ChoiceChip(label:const Text('بررسی شده'),selected:showOnlyUnread==false,onSelected:(_){setState(()=>showOnlyUnread=false);load();}),
            ]),
          ),
        ),
        Expanded(
          child: loading ? const Center(child:CircularProgressIndicator()) :
          RefreshIndicator(
            onRefresh:load,
            child: ListView.builder(
              controller:scroll,
              padding:const EdgeInsets.fromLTRB(12,4,12,100),
              itemCount:items.length+(loadingMore?1:0),
              itemBuilder:(context,index){
                if(index==items.length)return const Padding(padding:EdgeInsets.all(24),child:Center(child:CircularProgressIndicator()));
                final item=items[index], letter=item.letter;
                return Card(
                  margin:const EdgeInsets.only(bottom:10),
                  child: InkWell(
                    borderRadius:BorderRadius.circular(16),
                    onTap:letter==null?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>LetterShowPage(id:letter.id,title:'نامه ${letter.id}'))),
                    child:Padding(
                      padding:const EdgeInsets.all(16),
                      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                        Row(children:[
                          CircleAvatar(
                            backgroundColor:(item.checked?cs.surfaceContainerHighest:cs.primaryContainer),
                            child:Icon(item.checked?Icons.mark_email_read_outlined:Icons.mark_email_unread_outlined,color:item.checked?cs.onSurfaceVariant:cs.onPrimaryContainer),
                          ),
                          const SizedBox(width:12),
                          Expanded(child:Text(letter?.subject??'نامه شماره ${item.letterId}',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w700),maxLines:2,overflow:TextOverflow.ellipsis)),
                          Switch.adaptive(value:item.checked,onChanged:(v)async{
                            final updated=await service.setChecked(item.id,v);
                            if(mounted)setState(()=>items[index]=CartableModel(id:item.id,letterId:item.letterId,checked:updated.checked,createdAt:item.createdAt,updatedAt:updated.updatedAt,letter:item.letter));
                          }),
                        ]),
                        const SizedBox(height:12),
                        Wrap(spacing:6,runSpacing:6,children:[
                          InputChip(label:Text('نامه ${item.letterId}'),onPressed:null),
                          if(letter?.organ!=null)InputChip(avatar:const Icon(Icons.business_outlined,size:16),label:Text(letter!.organ!)),
                          if(letter?.daftar!=null)InputChip(avatar:const Icon(Icons.account_balance_outlined,size:16),label:Text(letter!.daftar!)),
                          if (letter != null) ...letter.projects.map((e)=>InputChip(label:Text(e))),
                        ]),
                        if(letter?.customers.isNotEmpty==true)...[
                          const SizedBox(height:8),
                          Text('صاحب: ${letter!.customers.join('، ')}',style:Theme.of(context).textTheme.bodyMedium),
                        ],
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
