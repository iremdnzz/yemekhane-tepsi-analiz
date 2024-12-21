import 'dart:convert'; // JSON işleme için
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String _result = ''; // Sunucudan gelen sonucu göstermek için
  List _predictions = []; // Tahmin sonuçları

  // Fotoğraf yükleme işlemi
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçimi iptal edildi.')),
      );
    }
  }

  // Fotoğrafı sunucuya gönderme
  Future<void> _sendImageToServer() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir fotoğraf yükleyin!')),
      );
      return;
    }

    final uri = Uri.parse('http://192.168.1.35:5000/analyze'); // Sunucu URL'si

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', _image!.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var data = jsonDecode(responseBody); // Sunucudan gelen veriyi çözümle

        if (data['predictions'] != null && data['predictions'].isNotEmpty) {
          setState(() {
            _predictions = data['predictions']; // Tahminleri ekrana yazdır
            _result = 'Analiz başarıyla tamamlandı!';
          });
        } else {
          setState(() {
            _predictions = [];
            _result = 'Tahmin sonuçları bulunamadı.';
          });
        }
      } else {
        setState(() {
          _result = 'Sunucu hatası, kod: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Bağlantı hatası: $e';
      });
      print('Hata: $e'); // Debug için konsola yazdır
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TATS - Tepsi Analiz Sistemi'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null
                  ? Text('Henüz bir fotoğraf seçilmedi.')
                  : Image.file(
                      _image!,
                      width: 300,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Fotoğraf Yükle'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendImageToServer,
                child: Text('Yemek Analizi Yap'),
              ),
              SizedBox(height: 20),
              _result.isNotEmpty
                  ? Text(
                      'Sonuç: $_result',
                      style: TextStyle(fontSize: 18),
                    )
                  : Container(),
              SizedBox(height: 20),
              _predictions.isNotEmpty
                  ? Column(
                      children: _predictions.map<Widget>((prediction) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Etiket: ${prediction['label']}'),
                            subtitle: Text(
                                'Skor: ${prediction['confidence'].toStringAsFixed(2)}'),
                          ),
                        );
                      }).toList(),
                    )
                  : (_result.isNotEmpty
                      ? Text(
                          'Hiçbir tahmin bulunamadı.',
                          style: TextStyle(color: Colors.grey),
                        )
                      : Container()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Sonuçlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'İstatistikler',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            // Sonuçlar ekranına yönlendirme
          } else if (index == 2) {
            // İstatistikler ekranına yönlendirme
          }
        },
      ),
    );
  }
}
