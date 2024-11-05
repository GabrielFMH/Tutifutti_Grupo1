import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class PartidaPage extends StatefulWidget {
  final String player1Id;
  final String player1Name;
  final String player2Id;
  final String player2Name;

  const PartidaPage({
    Key? key,
    required this.player1Id,
    required this.player1Name,
    required this.player2Id,
    required this.player2Name,
  }) : super(key: key);

  @override
  _PartidaPageState createState() => _PartidaPageState();
}

class _PartidaPageState extends State<PartidaPage> {
  String letraInicial = '';
  bool terminado = false; // Control para el estado de finalización de la partida
  bool esperandoJugador = true; // Control para esperar al segundo jugador
  Map<String, TextEditingController> campos = {
    'Nombre': TextEditingController(),
    'Apellido': TextEditingController(),
    'Cosa': TextEditingController(),
    'Animal': TextEditingController(),
    'Fruta/Verdura': TextEditingController(),
    'Profesión': TextEditingController(),
    'País': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _esperarSegundoJugador();
    _escucharEstadoPartida();
  }

  // Espera a que se conecte el segundo jugador antes de iniciar la partida
  Future<void> _esperarSegundoJugador() async {
    final salaRef = FirebaseFirestore.instance.collection('sala').doc(widget.player1Id);

    // Escucha cambios en el documento de la sala
    salaRef.snapshots().listen((salaDoc) async {
      if (salaDoc.exists) {
        if (salaDoc.data()?['player1'] != null && salaDoc.data()?['player2'] != null) {
          // Si ambos jugadores están presentes, obtener o generar la letra inicial
          if (salaDoc.data()?['letraInicial'] != null) {
            setState(() {
              letraInicial = salaDoc['letraInicial'];
              esperandoJugador = false; // Ya hay dos jugadores conectados
            });
          } else {
            // Genera una letra inicial si aún no se ha creado
            letraInicial = generarLetraInicial();
            await salaRef.update({
              'letraInicial': letraInicial,
            });
            setState(() {
              esperandoJugador = false;
            });
          }
        }
      } else {
        // Si el documento de la sala aún no existe, créalo con el jugador actual
        await salaRef.set({
          'player1': widget.player1Name,
          'player2': widget.player2Name,
          'letraInicial': null,
          'terminado': false,
        });
      }
    });
  }

  // Escucha cambios en el estado de la partida para desactivar los campos si ha terminado
  void _escucharEstadoPartida() {
    FirebaseFirestore.instance.collection('sala').doc(widget.player1Id).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot['terminado'] == true) {
        setState(() {
          terminado = true;
        });
      }
    });
  }

  // Genera una letra inicial aleatoria
  String generarLetraInicial() {
    const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letras[Random().nextInt(letras.length)];
  }

  // Guarda las respuestas del jugador en Firebase
  Future<void> _guardarDatosJugador() async {
    Map<String, String> palabras = {};
    campos.forEach((key, value) {
      palabras[key] = value.text;
    });

    await FirebaseFirestore.instance
        .collection('sala')
        .doc(widget.player1Id)
        .collection('jugadores')
        .doc(widget.player1Id) // Cambia a widget.player2Id si es el jugador 2
        .set({
      'respuestas': palabras,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Botón "BASTA" que detiene el juego y guarda los resultados
  void _bastaButtonPressed() async {
    await _guardarDatosJugador();
    await FirebaseFirestore.instance
        .collection('sala')
        .doc(widget.player1Id)
        .update({'terminado': true});
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultadosPage(player1Id: widget.player1Id)),
    );
  }

  @override
  void dispose() {
    campos.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.player1Name} vs ${widget.player2Name} - Letra: $letraInicial'),
      ),
      body: esperandoJugador
          ? Center(child: Text('Esperando a que otro jugador se conecte...'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DataTable(
                    columns: [
                      DataColumn(label: Text('Categoría')),
                      DataColumn(label: Text('Palabra')),
                    ],
                    rows: campos.keys.map((key) {
                      return DataRow(cells: [
                        DataCell(Text(key)),
                        DataCell(
                          TextField(
                            controller: campos[key],
                            decoration: InputDecoration(hintText: 'Palabra con $letraInicial'),
                            enabled: !terminado, // Desactiva el campo si el juego terminó
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: terminado ? null : _bastaButtonPressed, // Desactiva el botón si el juego terminó
                    child: const Text('BASTA'),
                  ),
                ],
              ),
            ),
    );
  }
}

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
      appBar: AppBar(title: const Text('Resultados')),
      body: FutureBuilder(
        future: _obtenerResultados(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay resultados disponibles.'));
          }

          List<Map<String, dynamic>> resultados = snapshot.data!;
          return ListView.builder(
            itemCount: resultados.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> resultado = resultados[index];
              return ListTile(
                title: Text('Jugador ${index + 1}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: resultado['respuestas'].entries.map<Widget>((entry) {
                    return Text('${entry.key}: ${entry.value}');
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
