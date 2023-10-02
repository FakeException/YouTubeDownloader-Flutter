import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_helper/ffmpeg/args/custom_arg.dart';
import 'package:ffmpeg_helper/ffmpeg/exporter.dart';
import 'package:ffmpeg_helper/helpers/ffmpeg_helper_class.dart';
import 'package:ffmpeg_helper/helpers/helper_progress.dart';
import 'package:flutter/material.dart';
import 'package:material_dialogs/dialogs.dart';
import 'package:material_dialogs/widgets/buttons/icon_button.dart';
import 'package:youtube_downloader/utils/yt_utils.dart';
import 'package:youtube_downloader/widgets/drawer.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FFMpegHelper.instance.initialize();
  runApp(const YoutubeDownloader());
}

class YoutubeDownloader extends StatelessWidget {
  const YoutubeDownloader({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'YouTube Downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final yt = YoutubeExplode();

  double? progress = 0;
  String status = "";
  String finalPath = "";
  bool downloading = false;
  bool started = false;
  bool finished = true;
  bool isNotValid = false;
  String formattedDate = "";

  StreamSubscription? videoDownloadSubscription;
  StreamSubscription? audioDownloadSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    deleteTempFolder();
    checkFFMpeg();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      deleteTempFolder();
    }
  }

  Future<void> deleteTempFolder() async {
    final tempDir = await getTemporaryDirectory();
    const folderName = 'youtube_downloader';
    final folderPath = '${tempDir.path}/$folderName';
    final folder = Directory(folderPath);

    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  Future<void> downloadVideoWithAudio(link) async {
    setState(() {
      progress = 0;
      finished = false;
      downloading = true;
      started = true;
    });

    final tempDir = await getTemporaryDirectory();
    var filePath = "${tempDir.path}/youtube_downloader";
    var dir = Directory(filePath);

    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    StreamManifest manifest = await yt.videos.streamsClient.getManifest(link);

    final now = DateTime.now();
    formattedDate =
        '${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}';

    var videoFilePath = "$filePath/video_$formattedDate.mp4";
    var audioFilePath = "$filePath/audio_$formattedDate.mp3";

    var videoInfo = manifest.videoOnly.withHighestBitrate();
    var audioInfo = manifest.audioOnly.withHighestBitrate();

    var totalVideoBytes = videoInfo.size.totalBytes;
    var totalAudioBytes = audioInfo.size.totalBytes;

    var downloadedVideoBytes = 0;
    var downloadedAudioBytes = 0;

    var videoFile = File(videoFilePath);
    var audioFile = File(audioFilePath);

    var videoFileStream = videoFile.openWrite();
    var audioFileStream = audioFile.openWrite();

    Future<void> closeStreams() async {
      await videoFileStream.close();
      await audioFileStream.close();
    }

    Future<void> checkDownloadCompletion() async {
      if (downloadedVideoBytes >= totalVideoBytes &&
          downloadedAudioBytes >= totalAudioBytes) {
        closeStreams();

        setState(() {
          status = "Merging files...";
          downloading = false;
        });

        final downloadPath = await getDownloadPath();
        finalPath = '$downloadPath/$formattedDate.mp4';

        ffmpeg.runAsync(
            FFMpegCommand(
              inputs: [
                FFMpegInput.asset(videoFilePath),
                FFMpegInput.asset(audioFilePath)
              ],
              args: [
                const CustomArgument(["-c:v", "copy"]),
                const CustomArgument(["-c:a", "aac"]),
                const CustomArgument(["-strict", "experimental"]),
              ],
              outputFilepath: finalPath,
            ), onComplete: (file) {
          setState(() {
            finished = true;
            status = "Complete";
          });
        });
      }
    }

    var videoStream = yt.videos.streamsClient.get(videoInfo);
    var audioStream = yt.videos.streamsClient.get(audioInfo);

    videoFileStream.done.then((_) {
      checkDownloadCompletion();
    });

    audioFileStream.done.then((_) {
      checkDownloadCompletion();
    });

    videoDownloadSubscription = videoStream.listen(
      (data) {
        videoFileStream.add(data);
        downloadedVideoBytes += data.length;
        var combinedProgress = (downloadedVideoBytes + downloadedAudioBytes) /
            (totalVideoBytes + totalAudioBytes);

        setState(() {
          progress = combinedProgress;
          status =
              "Downloading Progress: ${(combinedProgress * 100).toStringAsFixed(2)} %";
        });
      },
      onDone: () {
        checkDownloadCompletion();
      },
      onError: (error) {
        status = "Error during video download: $error";
      },
    );

    audioDownloadSubscription = audioStream.listen(
      (data) {
        audioFileStream.add(data);
        downloadedAudioBytes += data.length;
        var combinedProgress = (downloadedVideoBytes + downloadedAudioBytes) /
            (totalVideoBytes + totalAudioBytes);

        setState(() {
          progress = combinedProgress;
          status =
              "Downloading Progress: ${(combinedProgress * 100).toStringAsFixed(2)} %";
        });
      },
      onDone: () {
        checkDownloadCompletion();
      },
      onError: (error) {
        status = "Error during audio download: $error";
      },
    );
  }

  Future<void> downloadAudio(link) async {
    setState(() {
      progress = 0;
      finished = false;
      downloading = true;
      started = true;
    });

    final downloadPath = await getDownloadPath();

    StreamManifest manifest = await yt.videos.streamsClient.getManifest(link);

    final now = DateTime.now();
    formattedDate =
        '${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}';

    finalPath = '$downloadPath/$formattedDate.mp3';

    var audioFilePath = finalPath;

    var audioInfo = manifest.audioOnly.withHighestBitrate();

    var totalAudioBytes = audioInfo.size.totalBytes;

    var downloadedAudioBytes = 0;

    var audioFile = File(audioFilePath);

    var audioFileStream = audioFile.openWrite();

    Future<void> closeStreams() async {
      await audioFileStream.close();
    }

    Future<void> checkDownloadCompletion() async {
      if (downloadedAudioBytes >= totalAudioBytes) {
        closeStreams();

        setState(() {
          finished = true;
          downloading = false;
          status = "Complete";
        });
      }
    }

    var audioStream = yt.videos.streamsClient.get(audioInfo);

    audioFileStream.done.then((_) {
      checkDownloadCompletion();
    });

    audioDownloadSubscription = audioStream.listen(
      (data) {
        audioFileStream.add(data);
        downloadedAudioBytes += data.length;
        var totalProgress = downloadedAudioBytes / totalAudioBytes;

        setState(() {
          progress = totalProgress;
          status =
              "Downloading Progress: ${(totalProgress * 100).toStringAsFixed(2)} %";
        });
      },
      onDone: () {
        checkDownloadCompletion();
      },
      onError: (error) {
        status = "Error during audio download: $error";
      },
    );
  }

  void cancelDownload() {
    if (videoDownloadSubscription != null &&
        audioDownloadSubscription != null) {
      videoDownloadSubscription!.cancel();
      audioDownloadSubscription!.cancel();

      setState(() {
        progress = 0;
        status = "Download canceled";
        downloading = false;
        finished = true;
      });
    }
  }

  bool ffmpegPresent = false;
  ValueNotifier<FFMpegProgress> downloadProgress =
      ValueNotifier<FFMpegProgress>(FFMpegProgress(
    downloaded: 0,
    fileSize: 0,
    phase: FFMpegProgressPhase.inactive,
  ));

  FFMpegHelper ffmpeg = FFMpegHelper.instance;

  Future<void> checkFFMpeg() async {
    bool present = await ffmpeg.isFFMpegPresent();
    ffmpegPresent = present;
    if (!present) {
      downloadFFMpeg();
    }
    setState(() {});
  }

  Future<void> downloadFFMpeg() async {
    FFMpegHelper ffmpeg = FFMpegHelper.instance;

    if (Platform.isWindows) {
      await Dialogs.materialDialog(
          color: Colors.white,
          msg:
              'You need ffmpeg to use YouTube Downloader, click the button below for installing it.',
          title: 'Install FFMpeg',
          context: context,
          barrierDismissible: false,
          actions: [
            IconsButton(
              onPressed: () async {
                Navigator.of(context).pop();

                bool success = await ffmpeg.setupFFMpegOnWindows(
                  onProgress: (FFMpegProgress progress) {
                    downloadProgress.value = progress;
                  },
                );
                setState(() {
                  ffmpegPresent = success;
                });
              },
              text: 'Install',
              iconData: Icons.done,
              color: Colors.blue,
              textStyle: const TextStyle(color: Colors.white),
              iconColor: Colors.white,
            ),
          ]);
    } else if (Platform.isLinux) {
      // show dialog box
      await Dialogs.materialDialog(
          color: Colors.white,
          msg:
              'FFmpeg installation required by user.\nsudo apt-get install ffmpeg\nsudo snap install ffmpeg',
          title: 'Install FFMpeg',
          context: context,
          actions: [
            IconsButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              text: 'Ok',
              iconData: Icons.done,
              color: Colors.blue,
              textStyle: const TextStyle(color: Colors.white),
              iconColor: Colors.white,
            ),
          ]);
    }
  }

  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = Directory.current;
      }
    } catch (err) {
      status = "Cannot get download folder path";
    }
    return directory?.path;
  }

  TextEditingController linkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: const YouTubeDrawer(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(left: 5, right: 5, top: 25),
                child: Text(
                  "Welcome to YouTube Downloader!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  "Paste your YouTube link below for downloading it",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
                ),
              ),
              Visibility(
                visible: Platform.isWindows ? ffmpegPresent : true,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: TextField(
                    controller: linkController,
                    decoration: InputDecoration(
                        labelText: "Video Link",
                        hintText: "YouTube Video URL",
                        errorText: isNotValid
                            ? "Please enter a valid YouTube link"
                            : null,
                        border: const OutlineInputBorder()),
                  ),
                ),
              ),
              SizedBox(
                width: 300,
                child: ValueListenableBuilder(
                  valueListenable: downloadProgress,
                  builder: (BuildContext context, FFMpegProgress value, _) {
                    double? prog;
                    if ((value.downloaded != 0) && (value.fileSize != 0)) {
                      prog = value.downloaded / value.fileSize;
                    } else {
                      prog = 0;
                    }
                    if (value.phase == FFMpegProgressPhase.decompressing) {
                      prog = null;
                    }
                    if (value.phase == FFMpegProgressPhase.inactive) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Installing ffmpeg..."),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(value: prog),
                      ],
                    );
                  },
                ),
              ),
              Visibility(
                visible: Platform.isWindows
                    ? ffmpegPresent && !downloading && finished
                    : !downloading && finished,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (linkController.text.isEmpty ||
                            !checkIfYouTubeURL(linkController.text)) {
                          isNotValid = true;
                        } else {
                          isNotValid = false;
                          String link =
                              convertToYouTubeURL(linkController.text);
                          downloadVideoWithAudio(link);
                        }
                      });
                    },
                    child: const Text("Download Video"),
                  ),
                ),
              ),
              Visibility(
                visible: Platform.isWindows
                    ? ffmpegPresent && !downloading && finished
                    : !downloading && finished,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (linkController.text.isEmpty ||
                            !checkIfYouTubeURL(linkController.text)) {
                          isNotValid = true;
                        } else {
                          isNotValid = false;
                          String link =
                              convertToYouTubeURL(linkController.text);
                          downloadAudio(link);
                        }
                      });
                    },
                    child: const Text("Download Only Audio"),
                  ),
                ),
              ),
              Visibility(
                visible: downloading,
                child: ElevatedButton(
                  onPressed: () => cancelDownload(),
                  child: const Text("Stop Downloading"),
                ),
              ),
              Text(status),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Visibility(
                  visible: finished && started,
                  child: Center(
                      child: Text(
                    "Saved to: $finalPath",
                    textAlign: TextAlign.center,
                  )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                    ),
                    Visibility(
                      visible: progress == 1,
                      child: const Icon(
                        Icons.check,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
