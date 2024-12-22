
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
  double _normalTotalPrice = 0.0; // Toplam fiyat
  double _specialControlPrice = 0.0; // Özel kontrol fiyatı
  double _totalCalories = 0.0; // Toplam kalori

  // Fotoğraf yükleme işlemi
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _resetCalculations(); // Yeni fotoğraf seçildiğinde hesaplamaları sıfırla
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçimi iptal edildi.')),
      );
    }
  }

  // Hesaplamaları sıfırlama
  void _resetCalculations() {
    _normalTotalPrice = 0.0;
    _specialControlPrice = 0.0;
    _totalCalories = 0.0;
    _predictions = [];
    _result = '';
  }

  // Fotoğrafı sunucuya gönderme
  Future<void> _sendImageToServer() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen bir fotoğraf yükleyin!')),
      );
      return;
    }

    // Analiz başında hesaplamaları sıfırla
    setState(() {
      _resetCalculations();
    });

    final uri = Uri.parse('http://192.168.1.35:5000/analyze'); // Sunucu URL'si

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', _image!.path));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var data = jsonDecode(responseBody); // Sunucudan gelen veriyi çözümle

        if (data['predictions'] != null && data['predictions'].isNotEmpty) {
          double totalCalories = 0.0;
          double newSpecialControlPrice = 0.0;

          // Normal yemeklerin fiyatlarını ve kalorilerini hesapla
          for (var prediction in data['predictions']) {
            _normalTotalPrice += prediction['price'];
            totalCalories += prediction['calories'];
          }

          // Özel kontrol fiyatını belirle
          if (data['predictions'].any((p) => p['type'] == 'Ana Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Yardımcı Yemek') &&
              data['predictions'].any(
                  (p) => ['Tatlı', 'Meyve', 'İçecek'].contains(p['type']))) {
            newSpecialControlPrice = 132;
          } else if (data['predictions'].any((p) => p['type'] == 'Ana Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Yardımcı Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Su') &&
              data['predictions'].any((p) => p['type'] == 'Ekmek')) {
            newSpecialControlPrice = 106;
          } else if (data['predictions']
                  .any((p) => p['type'] == 'Etsiz Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Yardımcı Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Ekmek') &&
              data['predictions'].any((p) => p['type'] == 'Su')) {
            newSpecialControlPrice = 73;
          } else if (data['predictions']
                  .any((p) => p['type'] == 'Etsiz Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Ekmek') &&
              data['predictions'].any((p) => p['type'] == 'Su')) {
            newSpecialControlPrice = 53;
          }

          setState(() {
            _predictions = data['predictions'];
            _totalCalories = totalCalories;
            _specialControlPrice = newSpecialControlPrice;
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

  double _calculateSavings() {
    if (_normalTotalPrice > 0 && _specialControlPrice > 0) {
      return (_normalTotalPrice - _specialControlPrice) /
          _normalTotalPrice *
          100;
    }
    return 0.0; // Eğer normal toplam veya özel kontrol fiyatı sıfırsa tasarruf oranı sıfırdır.
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
                            leading: Text(prediction['label']),
                            title: Text('Tür: ${prediction['type']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Kalori: ${prediction['calories']} kcal'),
                                Text(
                                    'Güven: ${prediction['confidence'].toStringAsFixed(2)}%'),
                              ],
                            ),
                            trailing: Text('₺${prediction['price']}'),
                          ),
                        );
                      }).toList(),
                    )
                  : Container(),
              SizedBox(height: 20),
              _predictions.isNotEmpty
                  ? Column(
                      children: [
                        Text(
                          'Normal Toplam Fiyat: ₺$_normalTotalPrice',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Toplam Kalori: ${_totalCalories.toStringAsFixed(2)} kcal',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Menü Fiyatı: ₺$_specialControlPrice',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Tasarruf Oranı: ${_calculateSavings().toStringAsFixed(2)}%',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
