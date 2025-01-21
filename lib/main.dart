import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Classifier AgroStage IA',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ImageClassifierScreen(),
    );
  }
}

class ImageClassifierScreen extends StatefulWidget {
  @override
  _ImageClassifierScreenState createState() => _ImageClassifierScreenState();
}

class _ImageClassifierScreenState extends State<ImageClassifierScreen> {
  File? _image;
  String? _result;
  String? _additionalInfo;
  final ImagePicker _picker = ImagePicker();
  final String apiUrl = 'https://1ff4-177-107-116-215.ngrok-free.app/predict';

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null; // Limpa o resultado anterior
      });
      await _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File image) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        setState(() {
          _result = jsonResponse['predicted_class']+'-'+jsonResponse['confidence']?? 'Resultado não encontrado';
        });
      } else {
        setState(() {
          _result = 'Erro: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Erro ao enviar a imagem: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Classificador de Imagens'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Exibe a imagem selecionada
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(child: Text('Nenhuma imagem selecionada')),
              ),
            SizedBox(height: 16),
            // Botões para capturar ou selecionar imagem
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Câmera'),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text('Galeria'),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Exibe o resultado da API
            if (_result != null)
              Text(
                'Resultado: $_result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
