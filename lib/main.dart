import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Endereco> buscaEndereco(String cep) async {
  final resposta = await http.get(
    Uri.parse('https://viacep.com.br/ws/$cep/json/'),
    headers: {'Accept': 'application/json'},
  );

  if (resposta.statusCode == 200) {
    final Map<String, dynamic> dados = jsonDecode(resposta.body);
    if (dados.containsKey('erro')) {
      throw Exception('CEP não encontrado.');
    }
    return Endereco.fromJson(dados);
  } else {
    throw Exception('Falha ao carregar endereço.');
  }
}

class Endereco {
  final String rua;
  final String bairro;
  final String cidade;
  final String estado;

  const Endereco({
    required this.rua,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'logradouro': String logradouro,
        'bairro': String bairro,
        'localidade': String localidade,
        'uf': String uf
      } =>
        Endereco(
          rua: logradouro,
          bairro: bairro,
          cidade: localidade,
          estado: uf,
        ),
      _ => throw const FormatException('Falha no carregamento...'),
    };
  }
}

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();

  String rua = '';
  String bairro = '';
  String cidade = '';
  String estado = '';
  String numero = '';
  bool carregando = false;
  String mensagemErro = '';

  @override
  void initState() {
    super.initState();
    carregarDadosSalvos();
  }

  Future<void> carregarDadosSalvos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cepController.text = prefs.getString('cep') ?? '';
      _numeroController.text = prefs.getString('numero') ?? '';
      numero = prefs.getString('numero') ?? '';
      rua = prefs.getString('rua') ?? '';
      bairro = prefs.getString('bairro') ?? '';
      cidade = prefs.getString('cidade') ?? '';
      estado = prefs.getString('estado') ?? '';
    });
  }

  Future<void> buscarESalvar() async {
    setState(() {
      carregando = true;
      mensagemErro = '';
    });

    try {
      final cepLimpo = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final endereco = await buscaEndereco(cepLimpo);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cep', _cepController.text);
      await prefs.setString('numero', _numeroController.text);
      await prefs.setString('rua', endereco.rua);
      await prefs.setString('bairro', endereco.bairro);
      await prefs.setString('cidade', endereco.cidade);
      await prefs.setString('estado', endereco.estado);

      setState(() {
        numero = _numeroController.text;
        rua = endereco.rua;
        bairro = endereco.bairro;
        cidade = endereco.cidade;
        estado = endereco.estado;
      });
    } catch (e) {
      setState(() {
        mensagemErro = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  Future<void> apagarDados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cep');
    await prefs.remove('numero');
    await prefs.remove('rua');
    await prefs.remove('bairro');
    await prefs.remove('cidade');
    await prefs.remove('estado');

    setState(() {
      _cepController.clear();
      _numeroController.clear();
      rua = '';
      bairro = '';
      cidade = '';
      estado = '';
      numero = '';
      mensagemErro = '';
    });
  }

  @override
  void dispose() {
    _cepController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Consulta e Registro de Endereço',
      home: Scaffold(
        appBar: AppBar(title: const Text('Endereço & SharedPreferences')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _cepController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CEP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _numeroController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Número da Casa',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: carregando ? null : buscarESalvar,
                      child: Text(carregando ? 'Carregando...' : 'Buscar e Salvar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade900,
                      ),
                      onPressed: apagarDados,
                      child: const Text('Apagar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (mensagemErro.isNotEmpty)
                Text(
                  mensagemErro,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              if (rua.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Dados Registrados:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Rua: $rua'),
                Text('Número: $numero'),
                Text('Bairro: $bairro'),
                Text('Cidade: $cidade'),
                Text('Estado: $estado'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}