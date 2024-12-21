from flask import Flask, request, jsonify
from PIL import Image
from ultralytics import YOLO
from difflib import get_close_matches

app = Flask(__name__)

# Yemek bilgileri
food_data = {
    "Arnavut Cigeri": {"type": "Ana Yemek", "calories": 320, "price": 100},
    "Ayran": {"type": "İçecek", "calories": 60, "price": 33},
    "Burma Kadayif": {"type": "Tatlı", "calories": 250, "price": 33},
    "Cikolatali Baklava": {"type": "Tatlı", "calories": 300, "price": 33},
    "Coban Salata": {"type": "Salata", "calories": 120, "price": 33},
    "Duble Salata": {"type": "Salata", "calories": 180, "price": 33},
    "Ekmek": {"type": "-", "calories": 97.5, "price": 5},
    "Ekmek kadayifi": {"type": "Tatlı", "calories": 290, "price": 33},
    "Elma": {"type": "Meyve", "calories": 52, "price": 33},
    "Fanta": {"type": "İçecek", "calories": 120, "price": 33},
    "Firinda Patates": {"type": "Yardımcı Yemek", "calories": 180, "price": 33},
    "Icli kofte": {"type": "Ana Yemek", "calories": 250, "price": 100},
    "Joleli kek": {"type": "Tatlı", "calories": 200, "price": 33},
    "Kabak Tatlisi": {"type": "Tatlı", "calories": 200, "price": 33},
    "Kasik Salata": {"type": "Salata", "calories": 100, "price": 33},
    "Kirmizi Mercimek Corba": {"type": "Çorba", "calories": 150, "price": 26},
    "Kola": {"type": "İçecek", "calories": 140, "price": 33},
    "Kuru Fasulye": {"type": "Ana Yemek", "calories": 300, "price": 100},
    "Manti": {"type": "Ana Yemek", "calories": 350, "price": 100},
    "Muhallebili Revani": {"type": "Tatlı", "calories": 280, "price": 33},
    "Muz": {"type": "Meyve", "calories": 105, "price": 33},
    "Pilav": {"type": "Yardımcı Yemek", "calories": 210, "price": 33},
    "Pizza": {"type": "Ana Yemek", "calories": 400, "price": 100},
    "Portakal": {"type": "Meyve", "calories": 62, "price": 33},
    "Pureli Sinitzel": {"type": "Ana Yemek", "calories": 320, "price": 100},
    "Sebze Corbasi": {"type": "Çorba", "calories": 100, "price": 26},
    "Sobiyet": {"type": "Tatlı", "calories": 270, "price": 33},
    "Soguk Cay": {"type": "İçecek", "calories": 90, "price": 33},
    "Soslu Spagetti": {"type": "Yardımcı Yemek", "calories": 350, "price": 33},
    "Soslu Makarna": {"type": "Yardımcı Yemek", "calories": 350, "price": 33},
    "Spagetti": {"type": "Yardımcı Yemek", "calories": 300, "price": 33},
    "Su": {"type": "İçecek", "calories": 0, "price": 5},
    "Tavuk Sote": {"type": "Ana Yemek", "calories": 300, "price": 100},
    "Taze Fasulye": {"type": "Ana Yemek", "calories": 180, "price": 100},
    "Yesil Mercimek Corbasi": {"type": "Çorba", "calories": 150, "price": 26}
}
# En yakın eşleşme fonksiyonu
def find_closest_label(label, food_data):
    matches = get_close_matches(label, food_data.keys(), n=1, cutoff=0.6)
    return matches[0] if matches else None

# YOLOv8 modelinizi yükleyin
model = YOLO(r'C:\\Users\\Irem\\OneDrive\\Belgeler\\GitHub\\veriMadeniProje\\lib\\assets\\best.pt')  # Model yolunu doğru belirtin

@app.route('/')
def home():
    return 'Ana sayfa çalışıyor!'

@app.route('/analyze', methods=['POST'])
def analyze():
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided'}), 400

        # Fotoğrafı al
        image_file = request.files['image']
        image = Image.open(image_file.stream)

        # Model üzerinde tahmin yapın
        results = model(image)

        # Tahmin sonuçlarını almak için sonuçlar listesini işleyelim
        predictions = []
        total_price = 0

        for result in results:
            if hasattr(result, 'boxes') and result.boxes is not None:
                for box, cls, score in zip(result.boxes.xywh, result.boxes.cls, result.boxes.conf):
                    label = result.names[int(cls)].strip().title()  # Etiketi normalize et
                    print(f"Detected label: {label}")  # Tahmini kontrol et

                    # Etiketi bulmaya çalış
                    closest_label = find_closest_label(label, food_data)
                    if closest_label:
                        food_info = food_data[closest_label]
                    else:
                        food_info = {"type": "Bilinmiyor", "calories": 0, "price": 0}

                    # Tahmin edilen bilgileri ekle
                    total_price += food_info['price']
                    predictions.append({
                        'label': label,
                        'type': food_info['type'],
                        'calories': food_info['calories'],
                        'price': food_info['price'],
                        'confidence': float(score) * 100,  # Oranı yüzde formatına çevir
                        'box': box.tolist()  # Kutu bilgileri
                    })

        return jsonify({'predictions': predictions, 'total_price': total_price})

    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='192.168.1.35', port=5000)
