import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultadosPage extends StatelessWidget {
  final String player1Id;

  const ResultadosPage({Key? key, required this.player1Id}) : super(key: key);

  Future<List<Map<String, dynamic>>> _obtenerResultados() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('sala')
        .doc(player1Id)
        .collection('jugadores')
        .get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados del Juego'),
      ),
      body: FutureBuilder(
        future: _obtenerResultados(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay resultados disponibles.'));
          }

          List<Map<String, dynamic>> resultados = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Resultados de los Jugadores",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: resultados.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> jugador = resultados[index];
                      Map<String, dynamic> respuestas = jugador['respuestas'];
                      String nombreJugador = "Jugador ${index + 1}";
                      int puntuacion = calcularPuntuacion(respuestas);

                      return _buildScoreCard(
                        nombreJugador,
                        respuestas,
                        puntuacion,
                        index.isEven ? Colors.blue : Colors.green,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int calcularPuntuacion(Map<String, dynamic> respuestas) {
    int puntuacion = 0;
    respuestas.forEach((categoria, palabra) {
      if (palabra != 'Palabra no válida') {
        puntuacion += 100;
      }
    });
    return puntuacion;
  }

  Widget _buildScoreCard(String nombreJugador, Map<String, dynamic> respuestas, int puntuacion, Color color) {
    return Card(
      color: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombreJugador,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            SizedBox(height: 10),
            Column(
              children: respuestas.entries.map((entry) {
                bool valida = entry.value != 'Palabra no válida';
                return ListTile(
                  leading: Icon(
                    valida ? Icons.check_circle : Icons.cancel,
                    color: valida ? Colors.green : Colors.red,
                  ),
                  title: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      fontSize: 18,
                      color: valida ? Colors.green : Colors.red,
                    ),
                  ),
                );
              }).toList(),
            ),
            Divider(),
            Text(
              "Puntuación: $puntuacion",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
