import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

void downloadFile(String content, String fileName) {
  downloadFileLink(content, fileName);
}
