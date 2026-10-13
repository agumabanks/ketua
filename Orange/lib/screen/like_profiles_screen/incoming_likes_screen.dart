import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/common/common_ui.dart';
import 'package:ketua_ui/common/custom_image.dart';
import 'package:ketua_ui/common/ketua_copy.dart';
import 'package:ketua_ui/model/user/registration_user.dart';
import 'package:ketua_ui/screen/subscription_sheet/plans_view.dart';
import 'package:ketua_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:ketua_ui/utils/const_res.dart';

class IncomingLikesScreen extends StatefulWidget {
  const IncomingLikesScreen({super.key});
  @override
  State<IncomingLikesScreen> createState()=>_IncomingLikesScreenState();
}
class _IncomingLikesScreenState extends State<IncomingLikesScreen> {
  Map<String,dynamic>? result;
  List<Map<String,dynamic>> rows=[];
  String sort='recommended';
  int page=1;
  bool loading=false, failed=false, acting=false;
  @override
  void initState(){super.initState();load();}
  String t(String key)=>KetuaCopy.text(context,key);
  Future<void> load({bool more=false}) async {
    if(loading)return;
    setState(()=>loading=true);
    try {
      final next=more?page+1:1;
      final response=await http.get(Uri.parse('${ConstRes.aBaseUrl}likes/incoming?sort=$sort&page=$next'),headers:ApiProvider().authHeaders()).timeout(const Duration(seconds:15));
      final body=jsonDecode(response.body) as Map<String,dynamic>;
      if(response.statusCode!=200 || body['status']!=true)throw StateError('Likes unavailable');
      if(mounted)setState((){result=body;failed=false;page=next;final data=(body['data'] as List).cast<Map<String,dynamic>>();rows=more?[...rows,...data]:data;});
    }catch(_){if(mounted)setState(()=>failed=true);}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> like(UserData user) async {
    if(acting)return;
    setState(()=>acting=true);
    try{
      final response=await ApiProvider().matchLike(user.id);
      CommonUI.snackBar(message:response['status']==true?t(response['matched']==true?'It’s a match!':'Liked'):response['message']);
      if(response['status']==true)await load();
    }catch(_){CommonUI.snackBar(message:t('Unable to load likes'));}
    finally{if(mounted)setState(()=>acting=false);}
  }
  @override
  Widget build(BuildContext context){
    final count=result?['count'] ?? 0;final unlocked=result?['unlocked']==true;
    return RefreshIndicator(onRefresh:()=>load(),child:ListView(padding:const EdgeInsets.all(20),children:[
      Row(children:[Text(t('Likes'),style:const TextStyle(fontSize:34,fontWeight:FontWeight.w900)),const SizedBox(width:12),
        Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),decoration:BoxDecoration(color:ColorRes.surfaceDark,borderRadius:BorderRadius.circular(20)),child:Text('$count',style:const TextStyle(fontWeight:FontWeight.w700)))]),
      const SizedBox(height:20),
      SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
        for(final entry in {'recommended':'Recommended','recent':'Most recent','stars':'Stars'}.entries)Padding(padding:const EdgeInsets.only(right:10),child:ChoiceChip(label:Text(t(entry.value)),selected:sort==entry.key,onSelected:loading?null:(_){setState(()=>sort=entry.key);load();})),
      ])),
      const SizedBox(height:20),
      if(failed)...[Text(t('Unable to load likes')),TextButton(onPressed:()=>load(),child:Text(t('Retry')))]
      else if(result==null)const Center(child:CircularProgressIndicator())
      else if(count==0)Padding(padding:const EdgeInsets.symmetric(vertical:48),child:Column(children:[const Icon(Icons.favorite_outline,size:64,color:ColorRes.ketuaAccent),const SizedBox(height:20),Text(t('No likes yet'),style:const TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:10),Text(t('Your next connection is on its way.'),textAlign:TextAlign.center)]))
      else ...[
        if(!unlocked)GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:result?['preview_count'] ?? 0,
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisExtent:240,crossAxisSpacing:14,mainAxisSpacing:14),
          itemBuilder:(_,i)=>Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(28),gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[ColorRes.ketuaAccent.withValues(alpha:.3),const Color(0xFF26232E),const Color(0xFF425A75)])),child:const Center(child:Icon(Icons.lock_outline,color:Colors.white70,size:36))))
        else GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:rows.length,
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisExtent:320,crossAxisSpacing:14,mainAxisSpacing:14),itemBuilder:(_,i){
            final row=rows[i];final user=UserData.fromJson(row);
            return ClipRRect(borderRadius:BorderRadius.circular(28),child:Stack(fit:StackFit.expand,children:[
              CustomImage(image:user.profileImage,fullname:user.fullname,width:double.infinity,height:320,radius:0),
              const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.center,end:Alignment.bottomCenter,colors:[Colors.transparent,Colors.black]))),
              Positioned(top:12,right:12,child:Icon(row['star']==true?Icons.star_rounded:Icons.favorite_rounded,color:row['star']==true?const Color(0xFFAEC8FF):ColorRes.ketuaAccent)),
              Positioned(left:14,right:14,bottom:14,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[Expanded(child:Text('${user.fullname ?? ''}, ${user.age}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Colors.white))),if(user.isVerified==2)const Icon(Icons.verified,color:Colors.white,size:20)]),
                const SizedBox(height:8),Row(children:[Expanded(child:IconButton(tooltip:t('View profile'),onPressed:()=>Get.to(()=>UserDetailScreen(userData:user)),icon:const Icon(Icons.person_outline,color:Colors.white))),Expanded(child:IconButton(tooltip:t('Like back'),onPressed:acting?null:()=>like(user),icon:const Icon(Icons.favorite,color:ColorRes.ketuaAccent)))]),
              ])),
            ]));
          }),
        const SizedBox(height:20),
        if(!unlocked)ElevatedButton(onPressed:()=>Get.bottomSheet(const PlansView(),isScrollControlled:true),child:Text(t('Unlock with Gold'))),
        if(unlocked && result?['has_more']==true)TextButton(onPressed:loading?null:()=>load(more:true),child:Text(t('Load more'))),
      ],
      if(loading && result!=null)const LinearProgressIndicator(),
    ]));
  }
}
