import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:journal/user_store.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:http/http.dart' as http;
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
    // cloudFilePath =
    //     'recordings/${UserStore.instance.uid}/${widget.entryKey}.m4a';
    getApplicationDocumentsDirectory().then((dir) {
      localFilePath = '${dir.path}/${widget.entryKey}.mp3';
      print(localFilePath);
      File file = File(localFilePath);
      setState(() {
        isLoading = false;
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

  // Future<void> getRecordingIfExists() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //   try {
  //     // Get the download URL from Firebase Storage

  //     final ref = FirebaseStorage.instance.ref().child(localFilePath);
  //     final url = await ref.getDownloadURL();
  //     // Download the file
  //     final http.Response downloadData = await http.get(Uri.parse(url));
  //     final bytes = downloadData.bodyBytes;

  //     // Write the file to the local path
  //     final file = File(localFilePath);
  //     await file.writeAsBytes(bytes);
  //   } catch (e) {
  //     print('File does not exist in Firebase Storage.');
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> startRecording() async {
    if (await audioRecord.hasPermission() && !localFileExists) {
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

    Source src = UrlSource(localFilePath);
    await audioPlayer.play(src, volume: 1);
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

  // Future<void> uploadAndDeleteRecording() async {
  //   File file = File(localFilePath);
  //   try {
  //     await FirebaseStorage.instance.ref(cloudFilePath).putFile(file);
  //     await UserStore.instance.saveEntry(
  //         widget.entryKey, widget.entry.fromRecording(cloudFilePath));
  //     file.deleteSync();
  //   } on FirebaseException catch (e) {
  //     print('Error occurred during upload: $e');
  //   }
  // }

  Future<void> deleteRecording() async {
    if (localFilePath.isNotEmpty) {
      File file = File(localFilePath);
      if (localFileExists) {
        file.deleteSync();
        setState(() {
          localFileExists = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Recording with Firebase'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            !localFileExists
                ? IconButton(
                    icon: !isRecording
                        ? const Icon(
                            Icons.mic_none,
                            color: Colors.red,
                            size: 50,
                          )
                        : const Icon(Icons.fiber_manual_record,
                            color: Colors.red, size: 50),
                    onPressed: isRecording ? stopRecording : startRecording,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: !isPlaying
                            ? Icon(Icons.play_circle,
                                color: Colors.green, size: 50)
                            : Icon(Icons.pause_circle,
                                color: Colors.green, size: 50),
                        onPressed: !isPlaying ? playRecording : pauseRecording,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 50),
                        onPressed: deleteRecording,
                      ),
                      // IconButton(
                      //   icon: const Icon(Icons.trending_up,
                      //       color: Colors.green, size: 50),
                      //   onPressed: uploadAndDeleteRecording,
                      // ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
