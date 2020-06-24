import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'cache_http_file_service.dart';

const Duration cacheDuration = Duration(hours: 3);

class WeatherCacheManager extends BaseCacheManager {
  static const key = "weatherCache";

  static WeatherCacheManager _instance;

  factory WeatherCacheManager() {
    if (_instance == null) {
      _instance = new WeatherCacheManager._();
    }
    return _instance;
  }

  WeatherCacheManager._()
      : super(key,
            maxAgeCacheObject: cacheDuration,
            fileService: CacheHttpFileService(cacheDuration));

  Future<String> getFilePath() async {
    var directory = await getTemporaryDirectory();
    return path.join(directory.path, key);
  }

  Future<http.Response> getData(String url) async {
    var file = await _instance.getSingleFile(url);
    if (file != null && await file.exists()) {
      var res = await file.readAsString();
      return http.Response(res, 200);
    }
    return http.Response(null, 404);
  }
}
