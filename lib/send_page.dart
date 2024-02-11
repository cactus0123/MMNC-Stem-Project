import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

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

    socket.emit("register", "pusher");

    socket.on('server_message', (data) {
      log('Received message from server: $data');
    });
  }

  //Method to request microphone permission from phone, Future is used for asynchronous computation
  Future<bool> getPermissions() async {
    var status1 = await Permission.microphone.request();
    var status2 = await Permission.manageExternalStorage.request();
    return (status1.isGranted && status2.isGranted);
  }

  var counter = 0;
  Stream<List<int>> _readFileAsChunks(String path) async* {
    final file = File(path);
    const chunkSize = 1024 * 16;

    final logFile = file.openSync(mode: FileMode.read);
    while (true) {
      final chunk = logFile.readSync(chunkSize);
      if (chunk.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 1500));
      } else {
        yield chunk;
        setState(() {
          counter++;
        });
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
        Directory? appDocDir;
        try {
          appDocDir = await getApplicationDocumentsDirectory();
        } catch (e) {
          log(e.toString());
        }

        String path = '${appDocDir!.path}/recording.aac';
        //String path = 'storage/emulated/0/Download/MMNC_Audio/recording.aac';
        log("File Path: $path");

        await record!.start(
            const RecordConfig(), //! is used to refer to the initialized record
            path: path);

        final chunkStream = _readFileAsChunks(path);
        chunkStream.listen((chunk) {
          log("sending out chunk $counter");
          final DateTime now = DateTime.now();
          final pushData = {
            'data': chunk,
            'count': counter,
            'time': now.millisecondsSinceEpoch.toString()
          };
          log("chunk $counter: ${pushData['time']}");
          socket.emit('pushChunks', pushData);
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

      socket.emit("audioEnded", "Recording Stopped");

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
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isRecording ? Colors.red : Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                shadowColor: Colors.deepPurpleAccent,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                minimumSize: const Size(100, 100),
              ),
              child: Icon(isRecording ? Icons.stop : Icons.mic),
              onPressed: () {
                if (isRecording) {
                  stopRecording();
                } else {
                  startRecording();
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 200),
              child: Text(
                "Chunks Sent: $counter",
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
