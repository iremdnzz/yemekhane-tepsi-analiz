import 'dart:convert'; // JSON işleme için
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String _sonuc = ''; // Sunucudan gelen sonucu göstermek için
  List _predictions = []; // Tahmin sonuçları
  double _toplamFiyat = 0.0; // Toplam fiyat
  double _menuFiyat = 0.0; // Özel kontrol fiyatı
  double _toplamKalori = 0.0; // Toplam kalori
  List<Map<String, dynamic>> _statistics = []; // İstatistikler listesi
  int _currentIndex = 0; // Alt menüde seçili sekme

  // Aylık toplam veriler
  double _aylikToplamKalori = 0.0;
  double _aylikToplamFiyat = 0.0;
  double _aylikToplamTasarruf = 0.0;

  // Fotoğraf yükleme işlemi
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _toplamFiyat = 0.0; // Yeni fotoğrafta fiyatları sıfırla
        _menuFiyat = 0.0;
        _toplamKalori = 0.0;
        _predictions = [];
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
          double totalCalories = 0.0;
          double newSpecialControlPrice = 0.0;

          // Normal yemeklerin fiyatlarını ve kalorilerini hesapla
          for (var prediction in data['predictions']) {
            _toplamFiyat += prediction['price'];
            totalCalories += prediction['calories'];
          }

          // Özel kontrol fiyatını belirle
          if (data['predictions'].any((p) => p['type'] == 'Ana Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Yardımcı Yemek') &&
              data['predictions'].any(
                  (p) => ['Tatlı', 'Meyve', 'İçecek'].contains(p['type']))) {
            newSpecialControlPrice =
                132; // Özel kontrol sonucunda belirlenen fiyat
          } else if (data['predictions'].any((p) => p['type'] == 'Ana Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Yardımcı Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Su') &&
              data['predictions'].any((p) => p['type'] == 'Ekmek')) {
            newSpecialControlPrice =
                106; // Ana yemek, yardımcı yemek, su, ekmek varsa
          } else if (data['predictions']
                  .any((p) => p['type'] == 'Etsiz Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Yardımcı Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Ekmek') &&
              data['predictions'].any((p) => p['type'] == 'Su')) {
            newSpecialControlPrice =
                73; // Etsiz yemek, yardımcı yemek, su, ekmek varsa
          } else if (data['predictions']
                  .any((p) => p['type'] == 'Etsiz Yemek') &&
              data['predictions'].any((p) => p['type'] == 'Ekmek') &&
              data['predictions'].any((p) => p['type'] == 'Su')) {
            newSpecialControlPrice = 53; // Etsiz yemek, ekmek, su varsa
          }

          setState(() {
            _predictions = data['predictions']; // Tahminleri ekrana yazdır
            _toplamKalori = totalCalories; // Toplam kaloriyi ekle
            _menuFiyat = newSpecialControlPrice; // Yeni menü fiyatı
            _sonuc = 'Analiz başarıyla tamamlandı!';
          });
        } else {
          setState(() {
            _predictions = [];
            _sonuc = 'Tahmin sonuçları bulunamadı.';
          });
        }
      } else {
        setState(() {
          _sonuc = 'Sunucu hatası, kod: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _sonuc = 'Bağlantı hatası: $e';
      });
      print('Hata: $e'); // Debug için konsola yazdır
    }
  }

  // Kaydet butonuna basıldığında oranları kaydetme
  void _saveStatistics() {
    double currentSavings = _calculateSavings();
    DateTime currentTime =
        DateTime.now().toUtc().add(Duration(hours: 3)); // Türkiye için GMT+3

    setState(() {
      // Yeni kaydı ekle
      _statistics.add({
        'totalPrice': _menuFiyat > 0 ? _menuFiyat : _toplamFiyat,
        'calories': _toplamKalori,
        'savings': currentSavings,
        'timestamp': currentTime, // Kaydetme zamanı
      });

      // Aylık toplamları güncelle
      _aylikToplamKalori += _toplamKalori;
      _aylikToplamFiyat += _menuFiyat > 0 ? _menuFiyat : _toplamFiyat;

      // Ağırlıklı tasarruf oranını hesapla
      double toplamFiyat = 0.0;
      double toplamTasarruf = 0.0;

      for (var stat in _statistics) {
        toplamFiyat += stat['totalPrice'];
        toplamTasarruf += (stat['savings'] / 100) * stat['totalPrice'];
      }

      _aylikToplamTasarruf =
          toplamFiyat > 0 ? (toplamTasarruf / toplamFiyat) * 100 : 0.0;
    });
  }

  // Tasarruf oranını hesaplama
  double _calculateSavings() {
    if (_toplamFiyat > 0 && _menuFiyat > 0) {
      return (_toplamFiyat - _menuFiyat) / _toplamFiyat * 100;
    }
    return 0.0;
  }

  // Alt sekme seçimi
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TATS - Tepsi Analiz Sistemi'),
      ),
      body: _currentIndex == 0
          ? SingleChildScrollView(
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
                    _sonuc.isNotEmpty
                        ? Text(
                            'Sonuç: $_sonuc',
                            style: TextStyle(fontSize: 18),
                          )
                        : Container(),
                    SizedBox(height: 20),
                    _predictions.isNotEmpty
                        ? Column(
                            children: [
                              ..._predictions.map<Widget>((prediction) {
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Text(prediction['label']),
                                    title: Text('Tür: ${prediction['type']}'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Kalori: ${prediction['calories']} kcal'),
                                        Text(
                                            'Güven: ${prediction['confidence'].toStringAsFixed(2)}%'),
                                      ],
                                    ),
                                    trailing: Text('₺${prediction['price']}'),
                                  ),
                                );
                              }),
                              SizedBox(height: 10),
                              Text(
                                'Normal Toplam Fiyat: ₺$_toplamFiyat',
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                'Toplam Kalori: ${_toplamKalori.toStringAsFixed(2)} kcal',
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                'Menü Fiyatı: ₺$_menuFiyat',
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                'Tasarruf Oranı: ${_calculateSavings().toStringAsFixed(2)}%',
                                style: TextStyle(fontSize: 18),
                              ),
                              ElevatedButton(
                                onPressed: _saveStatistics,
                                child: Text('Oranları Kaydet'),
                              ),
                            ],
                          )
                        : Container(),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Aylık Toplam Kalori: ${_aylikToplamKalori.toStringAsFixed(2)} kcal',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Aylık Toplam Fiyat: ₺${_aylikToplamFiyat.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Aylık Toplam Tasarruf: ${_aylikToplamTasarruf.toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _statistics.isEmpty
                      ? Center(child: Text('Henüz kayıtlı istatistik yok.'))
                      : ListView.builder(
                          itemCount: _statistics.length,
                          itemBuilder: (context, index) {
                            var stat = _statistics[index];
                            DateTime timestamp = stat['timestamp'];
                            String formattedDate =
                                DateFormat('yyyy-MM-dd').format(timestamp);
                            String formattedTime =
                                DateFormat('HH:mm:ss').format(timestamp);

                            return ListTile(
                              title: Text(
                                  'Tasarruf: ${stat['savings'].toStringAsFixed(2)}%'),
                              subtitle: Text(
                                  'Fiyat: ₺${stat['totalPrice']}, Kalori: ${stat['calories']} kcal\nKaydedilen Zaman: $formattedDate $formattedTime'),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Anasayfa'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'İstatistikler'),
        ],
      ),
    );
  }
}
