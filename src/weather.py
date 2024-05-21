from flask import Flask, jsonify
import requests

app = Flask(__name__)

@app.route('/weather/<location>', methods=['GET'])
def get_weather(location):
    url = f'https://api.open-meteo.com/v1/forecast?latitude={location.split(",")[0]}&longitude={location.split(",")[1]}&current_weather=true'
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        weather_data = {
            'temperature': data['current_weather']['temperature'],
            'windspeed': data['current_weather']['windspeed'],
            'winddirection': data['current_weather']['winddirection'],
            'weathercode': data['current_weather']['weathercode']
        }
        return jsonify(weather_data)
    else:
        return jsonify({'error': 'Failed to retrieve weather data'}), 500

if __name__ == '__main__':
    app.run(debug=True)
