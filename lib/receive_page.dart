import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/material.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});
  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  bool isConnected = false;
  List<int> audioChunks = [];

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

    socket.emit("register", "receiver");

    socket.on("audioStream", (data) {
      if (data is Map) {
        audioChunks.addAll(data['data']);
        log("Received chunk from server: $data['count']");
      } else {
        log('Data does not contain a "data" key');
      }
    });

    socket.on('server_message', (data) {
      log('Received message from server: $data');
    });

    setState(() {
      isConnected = true;
    });
  }

  Future<void> saveAudio(List<int> data) async {
    try {
      //Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath =
          '/storage/emulated/0/Download/Audio/saved_chunk_file.wav';
      log('File path: $filePath');
      File recordedFile = File(filePath);

      var channels = 2;
      var sampleRate = 44100;

      int byteRate = ((16 * sampleRate * channels) / 8).round();

      var size = data.length;

      var fileSize = size + 36;

      Uint8List header = Uint8List.fromList([
        // "RIFF"
        82, 73, 70, 70,
        fileSize & 0xff,
        (fileSize >> 8) & 0xff,
        (fileSize >> 16) & 0xff,
        (fileSize >> 24) & 0xff,
        // WAVE
        87, 65, 86, 69,
        // fmt
        102, 109, 116, 32,
        // fmt chunk size 16
        16, 0, 0, 0,
        // Type of format
        1, 0,
        // One channel
        channels, 0,
        // Sample rate
        sampleRate & 0xff,
        (sampleRate >> 8) & 0xff,
        (sampleRate >> 16) & 0xff,
        (sampleRate >> 24) & 0xff,
        // Byte rate
        byteRate & 0xff,
        (byteRate >> 8) & 0xff,
        (byteRate >> 16) & 0xff,
        (byteRate >> 24) & 0xff,
        // Uhm
        ((16 * channels) / 8).round(), 0,
        // bitsize
        16, 0,
        // "data"
        100, 97, 116, 97,
        size & 0xff,
        (size >> 8) & 0xff,
        (size >> 16) & 0xff,
        (size >> 24) & 0xff,
        ...data
      ]);
      await recordedFile.writeAsBytes(header, flush: true);
    } catch (e) {
      log('Error saving audio: $e');
    }
  }

  Future<void> saveReceivedAudio(List<int> chunks) async {
    if (chunks.isNotEmpty) {
      await saveAudio(chunks);
      chunks.clear(); // Clear the list after saving
    } else {
      log('No audio data received yet.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retrieve Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                child: const Text('Play Audio'),
                onPressed: () => saveReceivedAudio(audioChunks))
          ],
        ),
      ),
    );
  }
}
