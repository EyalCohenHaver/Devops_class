from flask import Flask
from redis import Redis

app = Flask(__name__)
redis = Redis(host='localhost', port=6379)

@app.route('/')
def index():
    # Increment the visit count in Redis
    redis.incr('visits')
    # Get the current visit count from Redis
    visits = redis.get('visits').decode('utf-8')
    return f'Hello! You have visited this page {visits} times.'

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)