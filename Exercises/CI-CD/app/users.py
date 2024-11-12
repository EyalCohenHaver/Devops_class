import requests

def get_users():
    responce = requests.get('https://dummyjson.com/users?limit=100')
    users = responce.json().get('users', [])
    return users

def print_users(users):
    for user in users:
        print(user['firstName'])

def main():
    users = get_users()
    print_users(users)

if __name__ == "__main__":
    main()