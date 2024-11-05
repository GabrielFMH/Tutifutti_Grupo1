import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import 'partida.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutifruti',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Tutifruti'),
        ),
        body: const Center(
          child: HomePage(),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSearching = false;
  final TextEditingController _nameController = TextEditingController();
  Timer? _timer;
  String? _playerId;
  String? _playerName;

  Future<void> _savePlayerData() async {
    _playerId = Random().nextInt(1000000).toString();
    _playerName = _nameController.text.trim();

    if (_playerName != null && _playerName!.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('players')
          .doc(_playerId)
          .set({
        'name': _playerName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _startMatching();
    }
  }

  void _startMatching() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _matchPlayers();
    });
  }

  Future<void> _matchPlayers() async {
    CollectionReference playersCollection =
        FirebaseFirestore.instance.collection('players');
    QuerySnapshot playersSnapshot = await playersCollection
        .orderBy('timestamp', descending: true)
        .limit(2)
        .get();

    if (playersSnapshot.docs.length == 2) {
      var player1 = playersSnapshot.docs[0];
      var player2 = playersSnapshot.docs[1];

      if (player1.id == _playerId || player2.id == _playerId) {
        _timer?.cancel();
        await FirebaseFirestore.instance.collection('sala').add({
          'player1': {'id': player1.id, 'name': player1['name']},
          'player2': {'id': player2.id, 'name': player2['name']},
          'timestamp': FieldValue.serverTimestamp(),
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartidaPage(
              player1Id: player1.id,
              player1Name: player1['name'],
              player2Id: player2.id,
              player2Name: player2['name'],
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Escribe tu nombre',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    isSearching = true;
                  });
                  await _savePlayerData();
                },
                child: const Text('Jugar'),
              ),
            ],
          ),
        ),
        if (isSearching)
          Positioned(
            bottom: 16,
            right: 16,
            child: const Text(
              'Buscando partida..',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
