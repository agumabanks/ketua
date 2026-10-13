import 'package:flutter/material.dart';
import 'package:ketua_ui/generated/l10n.dart';
import 'package:ketua_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:ketua_ui/screen/create_profile_screen/view/find_matches.dart';
import 'package:ketua_ui/screen/preference_screen/preference_screen_view_model.dart';
import 'package:ketua_ui/utils/color_res.dart';
import 'package:stacked/stacked.dart';
class PreferenceScreen extends StatelessWidget {
 const PreferenceScreen({super.key});
 @override Widget build(BuildContext context)=>ViewModelBuilder<PreferenceScreenViewModel>.reactive(onViewModelReady:(m)=>m.init(),viewModelBuilder:()=>PreferenceScreenViewModel(),builder:(context,m,_)=>Scaffold(
  backgroundColor:ColorRes.bgDark,appBar:AppBar(title:const Text('Discovery preferences')),
  body:ListView(padding:const EdgeInsets.all(24),children:[
   const Text('Find your kind of connection.',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900)),const SizedBox(height:12),
   const Text('Choose who appears in your recommendations. Location distances are approximate and your exact coordinates stay private.',style:TextStyle(color:ColorRes.textSecondaryDark)),const SizedBox(height:28),
   Card(color:ColorRes.surfaceDark,child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(S.current.genderPref,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:14),
    Wrap(spacing:8,children:GenderType.values.map((g)=>ChoiceChip(label:Text(g==GenderType.other?'Everyone':g.title),selected:m.selectedGenderPref==g,onSelected:(_)=>m.onChangeGenderPref(g))).toList()),const SizedBox(height:28),
    AgeRangePreference(onChanged:m.onChangeAgeRange,value:m.selectedAgeRange),const SizedBox(height:28),DistancePreference(onChanged:m.onChangeDistance,value:m.selectedDistance),
   ]))),const SizedBox(height:24),FilledButton(onPressed:m.saving?null:m.onSaveTap,child:Text(m.saving?'Saving…':S.current.save)),
  ])));
}
