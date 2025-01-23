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
      debugShowCheckedModeBanner: false,
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
  double? confidencePercent;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final String apiUrl = 'https://1ff4-177-107-116-215.ngrok-free.app/predict';

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
      });
      await _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File image) async {
    setState(() {
      _isLoading = true;
    });
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        setState(() {
          _result =
              jsonResponse['predicted_class'] ?? 'Resultado não encontrado';
          _additionalInfo = jsonResponse['confidence'] ?? 0.0;
          confidencePercent = double.parse(_additionalInfo.toString()) * 100;
          _isLoading = false;
        });
      } else {
        setState(() {
          _result = 'Erro: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Erro ao enviar a imagem: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Classificador de Imagens AgroStage IA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
        backgroundColor: Colors.cyan,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'info') {
                showAboutDialog(
                  context: context,
                  applicationName: 'AgroStage IA',
                  applicationVersion: '0.1.0',
                  applicationIcon:
                      Icon(Icons.agriculture, size: 20, color: Colors.cyan),
                  children: [
                    Text('Desenvolvido por Vinicius Tessele'),
                  ],
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'info',
                  child: Text('Sobre'),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: Image(
                  image: AssetImage('assets/images/IA.png'),
                ),
              ),
              SizedBox(height: 13),
              Center(
                child: Text(
                  'O  momento para dessecação na soja é no estágio R7.2',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 9, 172, 193)),
                ),
              ),
              Image(
                image: AssetImage('assets/images/soja.png'),
              ),
              SizedBox(height: 10),
              if (_image != null)
                Image.file(
                  _image!,
                  height: 200,
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text('Nenhuma imagem selecionada')),
                ),
              SizedBox(height: 10),
              if (_isLoading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
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
              SizedBox(height: 10),
              if (_result != null)
                Text(
                  'Resultado: $_result',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              if (_result != null)
                Text(
                  'Acurácia: ${confidencePercent?.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
