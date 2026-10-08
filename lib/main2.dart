import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EditorMarkdown(),
    );
  }
}

class EditorMarkdown extends StatefulWidget {
  const EditorMarkdown({super.key});

  @override
  State<EditorMarkdown> createState() => _EditorMarkdownState();
}

class _EditorMarkdownState extends State<EditorMarkdown> {
  final TextEditingController _controlador = TextEditingController();

  Future<File> get _obterFicheiro async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/organiza.md');
  }

  @override
  void initState() {
    super.initState();
    _lerTexto();
  }

  Future<void> _lerTexto() async {
    try {
      final ficheiro = await _obterFicheiro;
      if (await ficheiro.exists()) {
        final conteudo = await ficheiro.readAsString();
        setState(() {
          _controlador.text = conteudo;
        });
      }
    } catch (_) {}
  }

  Future<void> _salvarTexto() async {
    final ficheiro = await _obterFicheiro;
    await ficheiro.writeAsString(_controlador.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ficheiro organiza.md guardado com sucesso!')),
      );
    }
  }

  Future<void> _apagarTexto() async {
    final ficheiro = await _obterFicheiro;
    if (await ficheiro.exists()) {
      await ficheiro.delete();
    }

    setState(() {
      _controlador.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conteúdo e ficheiro apagados!')),
      );
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar organiza.md'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controlador,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Escreva aqui o seu texto Markdown...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _salvarTexto,
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade900,
                    ),
                    onPressed: _apagarTexto,
                    icon: const Icon(Icons.delete),
                    label: const Text('Apagar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
