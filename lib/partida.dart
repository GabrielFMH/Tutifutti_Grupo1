import 'package:flutter/material.dart';

class PartidaPage extends StatelessWidget {
  final String player1Id;
  final String player1Name;
  final String player2Id;
  final String player2Name;

  const PartidaPage({
    super.key,
    required this.player1Id,
    required this.player1Name,
    required this.player2Id,
    required this.player2Name,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partida Tutifruti'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jugador 1: $player1Name (ID: $player1Id)',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Jugador 2: $player2Name (ID: $player2Id)',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}