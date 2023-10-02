bool checkIfYouTubeURL(String url) {
  // Regular expression pattern to match YouTube video URLs (including youtu.be)
  RegExp regExp = RegExp(
      r'^https?://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]+)(\?.*)?$');

  // Check if the URL matches the pattern
  return regExp.hasMatch(url);
}

String convertToYouTubeURL(String url) {
  // Regular expression pattern to match youtu.be URLs and capture the video ID
  RegExp regExp = RegExp(
      r'^https?://(?:www\.)?youtu\.be/(watch\?v=)?([a-zA-Z0-9_-]+)(\?.*)?$');

  // Check if the URL matches the youtu.be pattern
  if (regExp.hasMatch(url)) {
    // Extract the video ID from the URL
    String videoId = regExp.firstMatch(url)!.group(2)!;

    // Construct the converted youtube.com URL without query parameters
    String convertedURL = 'https://www.youtube.com/watch?v=$videoId';

    return convertedURL;
  }

  // If the URL is not a youtu.be URL, return it unchanged
  return url;
}