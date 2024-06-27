import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:journal/widgets/entry_actions.dart';
import 'package:record/record.dart';

import 'package:journal/user_store.dart';
// ref https://medium.com/@moeed366/uploading-and-recording-audio-in-flutter-124d95ec249f

class AudioEntryPage extends StatefulWidget {
  final String entryKey;
  final Map<String, Tag> tags;
  final Entry entry;
  const AudioEntryPage(this.tags, this.entryKey, this.entry);

  @override
  _AudioEntryPageState createState() => _AudioEntryPageState();
}

class _AudioEntryPageState extends State<AudioEntryPage> {
  late AudioRecorder audioRecord;
  late AudioPlayer audioPlayer;
  late String cloudFilePath;
  late String localFilePath;
  bool isRecording = false;
  bool isPlaying = false;
  bool isLoading = true;
  bool localFileExists = false;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    audioRecord = AudioRecorder();
    UserStore.instance
        .setupLocalRecording(widget.entryKey, widget.entry)
        .then((localPath) {
      // print(localPath);
      File file = File(localPath);
      setState(() {
        isLoading = false;
        localFilePath = localPath;
        localFileExists = file.existsSync();
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    audioRecord.dispose();
    audioPlayer.dispose();
  }

  Future<void> startRecording() async {
    if (await audioRecord.hasPermission()) {
      await audioRecord.start(const RecordConfig(), path: localFilePath);
      setState(() {
        isRecording = true;
      });
    }
  }

  Future<void> stopRecording() async {
    final rec = await audioRecord.stop();
    print(rec);
    audioPlayer.setSourceDeviceFile(localFilePath);
    setState(() {
      isRecording = false;
      localFileExists = true;
    });
  }

  Future<void> playRecording() async {
    setState(() {
      isPlaying = true;
    });

    Source src = DeviceFileSource(localFilePath);
    await audioPlayer.play(src);
    // Add an event listener to be notified when the audio playback completes
    audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.completed) {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  Future<void> pauseRecording() async {
    await audioPlayer.pause();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
      ),
      body: Center(
        child: Column(children: [
          EntryActions(widget.entryKey, widget.entry),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              !localFileExists
                  ? IconButton(
                      icon: !isRecording
                          ? Icon(
                              Icons.mic_none,
                              color: color,
                              size: 50,
                            )
                          : Icon(Icons.stop, color: color, size: 50),
                      onPressed: isRecording ? stopRecording : startRecording,
                    )
                  : Row(
                      children: [
                        IconButton(
                          icon: !isPlaying
                              ? Icon(Icons.play_circle, color: color, size: 50)
                              : Icon(Icons.pause_circle,
                                  color: color, size: 50),
                          onPressed:
                              !isPlaying ? playRecording : pauseRecording,
                        ),
                      ],
                    ),
            ],
          ),
        ]),
      ),
    );
  }
}
