from flask import Flask, request, jsonify
from PIL import Image
from ultralytics import YOLO

app = Flask(__name__)

# YOLOv8 modelinizi yükleyin
model = YOLO(r'C:\Users\Irem\OneDrive\Belgeler\GitHub\veriMadeniProje\lib\assets\best.pt')  # Model yolunu doğru belirtin

@app.route('/')
def home():
    return 'Ana sayfa çalışıyor!'

@app.route('/favicon.ico')
def favicon():
    return '', 204  # Favicon isteğine yanıt vermemek için boş yanıt dönebiliriz

@app.route('/test', methods=['GET'])
def test():
    return jsonify({'message': 'Bağlantı başarılı!'})

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
        for result in results:
            if hasattr(result, 'boxes'):  # `result` objesinin `boxes` özelliği olup olmadığını kontrol edelim
                for box, cls, score in zip(result.boxes.xywh, result.boxes.cls, result.boxes.conf):
                    predictions.append({
                        'label': result.names[int(cls)],  # Etiketin adı
                        'confidence': float(score),  # Skor
                        'box': box.tolist()  # Kutu bilgileri
                    })
            else:
                return jsonify({'error': 'No valid predictions found'}), 500

        return jsonify({'predictions': predictions})

    except Exception as e:
        # Hata mesajını yazdır
        print(f"Error: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    # Flask sunucusunu belirli IP ve portta çalıştırın
    app.run(debug=True, host='192.168.1.35', port=5000)
