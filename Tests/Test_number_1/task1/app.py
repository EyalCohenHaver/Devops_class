from flask import Flask
import requests

app = Flask(__name__)

@app.route("/")
def show_me_a_joke():
    r = requests.get('https://api.chucknorris.io/jokes/random')
    return r.json()["value"]

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)