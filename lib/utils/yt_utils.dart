bool checkIfYouTubeURL(String url) {
  try {
    Uri uri = Uri.parse(url);

    // Check if the host is youtube.com or youtu.be
    if (uri.host == 'www.youtube.com' || uri.host == 'youtu.be') {
      // Check if the path contains 'watch' and 'v' parameter
      if (uri.pathSegments.contains('watch') &&
          uri.queryParameters.containsKey('v')) {
        return true;
      }
    }
  } catch (_) {
    // Parsing error, not a valid URL
    return false;
  }

  return false;
}

String convertToYouTubeURL(String url) {
  try {
    Uri uri = Uri.parse(url);

    // Check if the host is youtu.be
    if (uri.host == 'youtu.be') {
      // Get the video ID from the path
      String videoId = uri.pathSegments.first;

      String convertedURL = 'https://www.youtube.com/watch?v=$videoId';

      return convertedURL;
    }
  } catch (_) {

  }

  return url;
}