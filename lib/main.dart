import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

void main() async {
  // Run the server and the Flutter app concurrently
  await Future.wait([
    runWebSocketServer(),
    runFlutterApp(),
  ]);
}

Future<void> runWebSocketServer() async {
  final server = await HttpServer.bind('localhost', 8080);
  print('WebSocket server is running on ws://localhost:8080');

  server.transform(WebSocketTransformer()).listen(handleClient);
}

final List<WebSocket> clients = [];

void handleClient(WebSocket client) {
  clients.add(client);
  print('New client connected. Total clients: ${clients.length}');

  client.listen(
    (data) {
      print('Received: $data');
      // Broadcast received data to all other clients
      for (var otherClient in clients) {
        if (otherClient != client) {
          otherClient.add(data);
        }
      }
    },
    onDone: () {
      print('Client disconnected');
      clients.remove(client);
    },
    onError: (error) {
      print('Error: $error');
      clients.remove(client);
    },
  );
}

Future<void> runFlutterApp() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multiplayer Chess',
      home: ChessGamePage(),
    );
  }
}

class ChessGamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chess Game')),
      body: Center(
        child: Text('Chess Game UI goes here.'),
      ),
    );
  }
}
