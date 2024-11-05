import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
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

  Future<void> _savePlayerData() async {
    String playerId = Random().nextInt(1000000).toString();
    String playerName = _nameController.text;

    if (playerName.isNotEmpty) {
      await FirebaseFirestore.instance.collection('players').doc(playerId).set({
        'name': playerName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
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
