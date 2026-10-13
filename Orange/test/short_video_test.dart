import 'package:flutter_test/flutter_test.dart';
import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/model/social/short_video/short_video_model.dart';
import 'package:ketua_ui/screen/short_video_screen/short_video_view_model.dart';

class _VideoApi extends ApiProvider {
  bool fail = true;
  @override
  Future<Map<String,dynamic>> shortVideoFeed({int start=0,int count=10}) async {
    if (fail) throw StateError('offline');
    return {'status':true,'data':[{'id':'7','video':'fixture.mp4','likes_count':'2','is_liked':'1'}]};
  }
  @override
  Future<Map<String,dynamic>> shortVideoLike(int id) async => throw StateError('offline');
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('video numeric strings parse without crashing', () {
    final v=ShortVideoModel.fromJson({'id':'9','duration_sec':'5','likes_count':'2','views_count':'3','is_liked':'1'});
    expect(v.id,9);expect(v.durationSec,5);expect(v.isLiked,true);
  });
  test('failed feed exits loading and can retry; failed like preserves confirmed count', () async {
    final api=_VideoApi();final model=ShortVideoViewModel(api:api);
    await model.init();expect(model.failed,true);expect(model.isLoading,false);
    api.fail=false;await model.fetchFeed(reset:true);
    expect(model.failed,false);expect(model.videos.length,1);
    await model.toggleLike(model.videos.first);
    expect(model.videos.first.likesCount,2);expect(model.videos.first.isLiked,true);
    model.dispose();
  });
}
