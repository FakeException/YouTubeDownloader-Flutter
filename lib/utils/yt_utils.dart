bool checkIfYouTubeURL(String url) {
  try {
    Uri uri = Uri.parse(url);

    // Check if the host is youtube.com or youtu.be
    if (uri.host == 'www.youtube.com' || uri.host == 'youtu.be') {
      // Check if the path contains 'watch' and 'v' parameter
        return true;
    }
  } catch (_) {
    // Parsing error, not a valid URL
    return false;
  }

  return false;
}

String convertToYouTubeURL(String shortURL) {
  // Check if the URL starts with "https://youtu.be/"
  if (shortURL.startsWith("https://youtu.be/")) {
    // Split the URL at the '/' character to get the video ID
    List<String> parts = shortURL.split("/");
    if (parts.length > 3) {
      // Extract the video ID from the URL
      String videoID = parts[3].split("?")[0];

      // Create the full YouTube URL
      String fullURL = "https://www.youtube.com/watch?v=$videoID";

      return fullURL;
    }
  }

  // If the input URL is not in the expected format, return it unchanged
  return shortURL;
}