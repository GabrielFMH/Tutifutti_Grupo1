import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'resultado.dart'; // Importa el nuevo archivo de resultados

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
  bool terminado = false; 
  bool esperandoJugador = true; 
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

  Future<void> _esperarSegundoJugador() async {
    final salaRef = FirebaseFirestore.instance.collection('sala').doc(widget.player1Id);
    salaRef.snapshots().listen((salaDoc) async {
      if (salaDoc.exists) {
        if (salaDoc.data()?['player1'] != null && salaDoc.data()?['player2'] != null) {
          if (salaDoc.data()?['letraInicial'] != null) {
            setState(() {
              letraInicial = salaDoc['letraInicial'];
              esperandoJugador = false; 
            });
          } else {
            letraInicial = generarLetraInicial();
            await salaRef.update({'letraInicial': letraInicial});
            setState(() {
              esperandoJugador = false;
            });
          }
        }
      } else {
        await salaRef.set({
          'player1': widget.player1Name,
          'player2': widget.player2Name,
          'letraInicial': null,
          'terminado': false,
        });
      }
    });
  }

  void _escucharEstadoPartida() {
    FirebaseFirestore.instance.collection('sala').doc(widget.player1Id).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot['terminado'] == true) {
        setState(() {
          terminado = true;
        });
      }
    });
  }

  String generarLetraInicial() {
    const letras = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    return letras[Random().nextInt(letras.length)];
  }

  Future<bool> verificarOrtografia(String palabra) async {
    final response = await http.post(
      Uri.parse('https://api.languagetoolplus.com/v2/check'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'text': palabra, 'language': 'es'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['matches'].isEmpty; 
    } else {
      throw Exception('Error al verificar la ortografía');
    }
  }

  Future<void> _guardarDatosJugador() async {
    Map<String, String> palabras = {};
    for (var entry in campos.entries) {
      String categoria = entry.key;
      String palabra = entry.value.text.trim();
      bool esValida = await verificarOrtografia(palabra);
      palabras[categoria] = esValida ? palabra : 'Palabra no válida';
    }

    await FirebaseFirestore.instance
        .collection('sala')
        .doc(widget.player1Id)
        .collection('jugadores')
        .doc(widget.player1Id)
        .set({
      'respuestas': palabras,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

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
                            enabled: !terminado, 
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: terminado ? null : _bastaButtonPressed,
                    child: const Text('BASTA'),
                  ),
                ],
              ),
            ),
    );
  }
}
