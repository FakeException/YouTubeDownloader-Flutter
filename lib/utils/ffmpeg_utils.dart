import 'dart:io';

import 'package:ffmpeg_helper/ffmpeg/args/custom_arg.dart';
import 'package:ffmpeg_helper/ffmpeg/ffmpeg_command.dart';
import 'package:ffmpeg_helper/ffmpeg/ffmpeg_input.dart';
import 'package:ffmpeg_helper/helpers/ffmpeg_helper_class.dart';

void mergeVideoAndAudio(FFMpegHelper ffmpeg, String inputVideo,
    String inputAudio, String outputFilePath, Function(File?)? onComplete) {
  ffmpeg.runAsync(
      FFMpegCommand(
        inputs: [FFMpegInput.asset(inputVideo), FFMpegInput.asset(inputAudio)],
        args: [
          const CustomArgument(["-c:v", "copy"]),
          const CustomArgument(["-c:a", "aac"]),
          const CustomArgument(["-strict", "experimental"]),
        ],
        outputFilepath: outputFilePath,
      ),
      onComplete: onComplete);
}

void wavToMp3(FFMpegHelper ffmpeg, String inputAudio, String outputFilePath,
    Function(File?)? onComplete) {
  ffmpeg.runAsync(
      FFMpegCommand(
        inputs: [FFMpegInput.asset(inputAudio)],
        args: [
          const CustomArgument(["-codec:a", "libmp3lame"]),
          const CustomArgument(["-q:a", "2"]),
        ],
        outputFilepath: outputFilePath,
      ),
      onComplete: onComplete);
}
