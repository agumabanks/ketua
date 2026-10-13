import 'package:ketua_ui/api_provider/api_provider.dart';
import 'package:ketua_ui/model/social/short_video/short_video_model.dart';
import 'package:stacked/stacked.dart';

class ShortVideoViewModel extends BaseViewModel {
  final ApiProvider _api;
  ShortVideoViewModel({ApiProvider? api}) : _api = api ?? ApiProvider();
  List<ShortVideoModel> videos = [];
  int start = 0;
  bool isLoading = false, hasMore = true, failed = false, _closed = false;
  final _liking = <int>{};
  final _viewed = <int>{};

  Future<void> init() => fetchFeed(reset: true);

  Future<void> fetchFeed({bool reset = false}) async {
    if (isLoading || (!reset && !hasMore)) return;
    isLoading = true;
    failed = false;
    notifyListeners();
    try {
      final res = await _api.shortVideoFeed(start: reset ? 0 : start, count: 10)
          .timeout(const Duration(seconds: 15));
      if (res['status'] != true) throw StateError('Feed unavailable');
      final data = res['data'];
      final list = data is List ? data : (data is Map ? (data['videos'] ?? []) as List : []);
      if (_closed) return;
      if (reset) videos = [];
      final seen = videos.map((v) => v.id).toSet();
      for (final row in list) {
        final video = ShortVideoModel.fromJson(row);
        if (video.id != null && seen.add(video.id)) videos.add(video);
      }
      start = (reset ? 0 : start) + list.length;
      hasMore = list.length == 10;
    } catch (_) {
      if (!_closed) failed = true;
    } finally {
      isLoading = false;
      if (!_closed) notifyListeners();
    }
  }

  Future<void> toggleLike(ShortVideoModel video) async {
    final id = video.id;
    if (id == null || !_liking.add(id)) return;
    try {
      final res = await _api.shortVideoLike(id).timeout(const Duration(seconds: 15));
      if (res['status'] == true && !_closed) {
        video.isLiked = res['is_liked'] == true || res['is_liked'] == 1;
        video.likesCount = int.tryParse('${res['likes_count']}') ?? video.likesCount;
        notifyListeners();
      }
    } catch (_) { /* Preserve the last server-confirmed state. */ }
    finally { _liking.remove(id); }
  }

  Future<void> recordView(ShortVideoModel video) async {
    final id = video.id;
    if (id == null || !_viewed.add(id)) return;
    try {
      final res = await _api.shortVideoView(id).timeout(const Duration(seconds: 15));
      if (res['status'] == true && !_closed) {
        video.viewsCount = int.tryParse('${res['views_count']}') ?? video.viewsCount;
        notifyListeners();
      }
    } catch (_) { _viewed.remove(id); }
  }

  Future<void> recordShare(ShortVideoModel video) async {
    if (video.id == null) return;
    try {
      final res = await _api.shortVideoShare(video.id!).timeout(const Duration(seconds: 15));
      if (res['status'] == true && !_closed) {
        video.sharesCount = int.tryParse('${res['shares_count']}') ?? video.sharesCount;
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() { _closed = true; super.dispose(); }
}
