import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isRecording = false;

  //Declaring record here, ? means possible null, necessary in Dart
  AudioRecorder? record;
  String? path;

  //Method to request microphone permission from phone, Future is used for asynchronous computation
  Future<bool> getPermissions() async {
    var status = await Permission.microphone.request();
    return status.isGranted;
  }

  List<Uint8List> _chunkAudio(String path) {
    final file = File(path);
    final bytes = file
        .readAsBytesSync(); //array of all the bytes in the recording as Uint8list
    const chunkSize = 1024 * 10;

    final chunkArr = <Uint8List>[];

    //increments through byte arr by chunkSize
    for (var i = 0; i < bytes.length; i += chunkSize) {
      /*
      each chunk is a collection of bytes
      this collection is defined by the chunkSize
      inal is used to get the upper bound for the bytes given i pos to get a chunk
      */
      final end = i + chunkSize;
      if (end > bytes.length) {
        // checks if the audio recording is shorter than 1 chunkSize to avoid outOfBound
        chunkArr.add(bytes.sublist(i, bytes.length)); //Each sublist is a chunk
      } else {
        chunkArr.add(bytes.sublist(i, end));
      }
    }

    log('Number of chunks: ${chunkArr.length}');
    return chunkArr;
  }

  Future<void> startRecording() async {
    try {
      if (await getPermissions()) {
        record = AudioRecorder(); //initialization of record
        //This is to start the recording

        // Get the directory to save the audio file
        //Directory appDocDir = await getApplicationDocumentsDirectory();
        path = '/storage/emulated/0/Download/MMNC_Audio/recording.aac';
        log("File Path: $path");

        await record!.start(
            const RecordConfig(), //! is used to refer to the initialized record
            path: path!);

        //This is the audio chunking for streaming, the chunks are 8-bit ints which can be converted to audio
        //final stream = record!.startStream(const RecordConfig());
      } else {
        log('permission denied');
      }

      setState(() {
        isRecording = true;
        log(isRecording.toString());
      });
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> stopRecording() async {
    try {
      await record!.stop();
      record!.dispose();

      //Chunk the data
      log("Chunking Start");
      final chunks = _chunkAudio(path!);
      log("Finished Chunking");

      /*
      for (var i = 0; i < chunks.length; i++) {
        log('Size of chunk $i: ${chunks[i].lengthInBytes} bytes');
      }
      */

      setState(() {
        isRecording = false;
        log(isRecording.toString());
      });
    } catch (e) {
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Recorder"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Icon(isRecording ? Icons.stop : Icons.mic),
              onPressed: () {
                if (isRecording) {
                  stopRecording();
                } else {
                  startRecording();
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
