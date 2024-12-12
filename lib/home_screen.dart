import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;

  // Fotoğraf yükleme işlemi
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TATS - Tepsi Analiz Sistemi'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? Text('Henüz bir fotoğraf seçilmedi.')
                : Image.file(_image!),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Fotoğraf Yükle'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_image != null) {
                  print('Yemek analizi yapılıyor...');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lütfen bir fotoğraf yükleyin!')),
                  );
                }
              },
              child: Text('Yemek Analizi Yap'),
            ),
          ],
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
