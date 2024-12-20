import requests

# Resminizin yolunu burada belirtin
image_path = 'C:/Users/Irem/OneDrive/Masaüstü/veri/IMG-20241217-WA0038.jpg'

# Flask sunucusunun adresi
url = 'http://127.0.0.1:5000/analyze'

# Dosyayı açın
files = {'image': open(image_path, 'rb')}  # Resminizi buraya ekleyin

# Sunucuya istek gönderin
response = requests.post(url, files=files)

# Sunucudan gelen cevabı kontrol edin
if response.status_code == 200:
    print(response.json())  # Tahmin sonuçlarını yazdır
else:
    print(f"Error: {response.status_code}")
