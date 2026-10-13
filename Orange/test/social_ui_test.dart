import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketua_ui/common/animated_gift_card.dart';
import 'package:ketua_ui/common/full_image_view_shimmer.dart';
import 'package:ketua_ui/model/setting_model.dart';
void main() {
 testWidgets('Gift card shows name and price and responds to selection', (tester) async {
  var selected=false;
  await tester.pumpWidget(MaterialApp(home:MediaQuery(data:const MediaQueryData(disableAnimations:true),child:Scaffold(body:SizedBox(width:160,height:170,child:AnimatedGiftCard(gift:Gifts(id:1,name:'Heartbeat',coinPrice:50),onTap:()=>selected=true))))));
  expect(find.text('Heartbeat'),findsOneWidget);expect(find.text('50 coins'),findsOneWidget);
  await tester.tap(find.text('Heartbeat'));expect(selected,isTrue);expect(tester.takeException(),isNull);
 });
 testWidgets('Discovery radar honours reduced motion and has clear copy', (tester) async {
  await tester.pumpWidget(const MaterialApp(home:MediaQuery(data:MediaQueryData(disableAnimations:true),child:Scaffold(body:Column(children:[FullImageViewShimmer()])))));
  await tester.pumpAndSettle();expect(find.text('Finding your next connection'),findsOneWidget);expect(find.text('Meet. Vibe. Connect.'),findsOneWidget);expect(tester.takeException(),isNull);
 });
}
