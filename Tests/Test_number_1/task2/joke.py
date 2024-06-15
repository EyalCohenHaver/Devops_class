import requests

response = requests.get("https://official-joke-api.appspot.com/random_joke")
if response.status_code == 200:
    joke = response.json()
    print(joke['setup'])
    print(joke['punchline'])
else:
    print("Failed to fetch joke")
