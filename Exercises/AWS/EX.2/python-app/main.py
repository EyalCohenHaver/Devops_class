from flask import Flask, render_template
import requests

app = Flask(__name__)

@app.route('/')
def index():
    response = requests.get('https://blockchain.info/ticker')
    data = response.json()
    btc_usd_price = data['USD']['last']
    return render_template('index.html', price=btc_usd_price)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
