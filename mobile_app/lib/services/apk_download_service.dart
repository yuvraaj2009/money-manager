import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/api_constants.dart';

class ApkDownloadService {
  CancelToken? _cancelToken;

  /// Download the APK from [apkPath] (e.g. "/download/apk") and report progress.
  /// Returns the local file path on success.
  Future<String> downloadApk(
    String apkPath, {
    void Function(int received, int total)? onProgress,
  }) async {
    _cancelToken = CancelToken();
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/money-manager-update.apk';

    final url = '${ApiConstants.baseUrl}$apkPath';
    await Dio().download(
      url,
      savePath,
      cancelToken: _cancelToken,
      onReceiveProgress: onProgress,
    );
    return savePath;
  }

  /// Open the downloaded APK to trigger the Android package installer.
  Future<void> installApk(String filePath) async {
    await OpenFilex.open(filePath);
  }

  /// Cancel an in-progress download.
  void cancel() {
    _cancelToken?.cancel('User cancelled download');
    _cancelToken = null;
  }
}
