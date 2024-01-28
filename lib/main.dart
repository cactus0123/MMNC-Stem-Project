import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

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

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isRecording = false;

  //Declaring record here, ? means possible null, necessary in Dart
  AudioRecorder? record;
  String? path;

  final socket = io.io(
      'https://desolate-mesa-93969-086416f0bdb9.herokuapp.com/',
      <String, dynamic>{
        'transports': ['websocket']
      });

  @override
  void initState() {
    super.initState();
    socket.onConnect((_) {
      log('Connected to the server');
    });

    socket.on('server_message', (data) {
      log('Received message from server: $data');
    });
  }

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

  var counter = 0;
  Stream<List<int>> _readFileAsChunks(String path) async* {
    final file = File(path);
    const chunkSize = 1024 * 10;

    final logFile = file.openSync(mode: FileMode.read);
    while (true) {
      final chunk = logFile.readSync(chunkSize);
      if (chunk.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 1500));
      } else {
        yield chunk;
        counter++;
        log(counter.toString());
      }
    }
  }

  Future<void> startRecording() async {
    try {
      if (await getPermissions()) {
        //This is to start the recording
        record = AudioRecorder();
        // Get the directory to save the audio file\
        path = '/storage/emulated/0/Download/MMNC_Audio/recording.aac';
        log("File Path: $path");

        await record!.start(
            const RecordConfig(), //! is used to refer to the initialized record
            path: path!);

        final chunkStream = _readFileAsChunks(path!);
        chunkStream.listen((chunk) {
          log("sending out chunk $counter");
          socket.emit('pushChunks', {'data': chunk, 'count': counter});
          log("finished sending out chunk $counter");
        });
      } else {
        log('permission denied');
      }

      try {
        socket.emit("audioStarted", "The audio recording has started");
      } catch (e) {
        log(e.toString());
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
      //final chunks = _chunkAudio(path!);
      socket.emit("audioEnded", "Recording Stopped");

      /*
      
      for (var i = 0; i < chunks.length; i++) {
        socket.emit('pushChunks', chunks[i]);
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
