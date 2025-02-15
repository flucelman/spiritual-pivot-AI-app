# settings.py
TORTOISE_ORM = {
    'connections': {
        'default': {
            'engine': 'tortoise.backends.mysql',  # MySQL or Mariadb
            'credentials': {
                'host': 'localhost',
                'port': '3306',
                'user': 'root',
                'password': '333965lq',  # 请确保这个密码是正确的
                'database': '灵枢ai',
                'minsize': 1,
                'maxsize': 5,
                'charset': 'utf8mb4',
                "echo": True
            }
        },
    },
    'apps': {
        'models': {
            'models': ['app.mysql.models', "aerich.models"],  # 修改这里
            'default_connection': 'default'
        }
    },
    'use_tz': False,
    'timezone': 'Asia/Shanghai'
}

def get_tortoise_config():
    return TORTOISE_ORM
