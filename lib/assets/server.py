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
            print(f"Result: {result}")  # Sonuçları yazdırmak için
            if hasattr(result, 'boxes'):  # `result` objesinin `boxes` özelliği olup olmadığını kontrol edelim
                boxes = result.boxes.xywh  # Kutu bilgileri
                labels = result.names  # Etiketler
                scores = result.scores  # Skorlar

                for i in range(len(boxes)):
                    predictions.append({
                        'label': labels[int(result.cls[i])],  # Etiketin adı
                        'confidence': scores[i],  # Skor
                        'box': boxes[i].tolist()  # Kutu bilgileri
                    })
            else:
                print("No boxes found in the result")  # Eğer `boxes` bulunmazsa
                return jsonify({'error': 'No valid predictions found'}), 500
        
        return jsonify({'predictions': predictions})

    except Exception as e:
        # Hata mesajını daha ayrıntılı olarak yazdıralım
        print(f"Error: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
