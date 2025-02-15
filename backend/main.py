# main.py
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI
from dotenv import load_dotenv
# tortoise-orm
# from tortoise.contrib.fastapi import register_tortoise
# from app.mysql.settings import TORTOISE_ORM
# from tortoise import Tortoise


# 路由
from app.router.chat import router as chat_router
from app.router.update import router as update_router

# 在应用启动时加载 .env 文件
load_dotenv()


app = FastAPI()
# 注册路由--------------------------------------------------------------------
app.include_router(chat_router, prefix="/api/chat")
app.include_router(update_router, prefix="/api/update")
# 全局变量
reader = None

# 初始化数据库-----------------------------------------------------------------
# async def init():
#     db_url = f"mysql://{TORTOISE_ORM['connections']['default']['credentials']['user']}:" \
#              f"{TORTOISE_ORM['connections']['default']['credentials']['password']}@" \
#              f"{TORTOISE_ORM['connections']['default']['credentials']['host']}:" \
#              f"{TORTOISE_ORM['connections']['default']['credentials']['port']}/" \
#              f"{TORTOISE_ORM['connections']['default']['credentials']['database']}"
    
#     await Tortoise.init(
#         db_url=db_url,
#         modules={'models': ['app.mysql.models']}
#     )
#     await Tortoise.generate_schemas()

# 在这里注册Tortoise
# register_tortoise(
#     app,
#     config=TORTOISE_ORM,
#     generate_schemas=False,
#     add_exception_handlers=True,
# )


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],  # 允许所有方法，包括 POST 和 OPTIONS
    allow_headers=["*"],  # 允许所有头部
)

@app.on_event("startup")
async def startup_event():
    global reader
    # 初始化数据库
    # await init()

@app.on_event("shutdown")
async def shutdown_event():
    # await Tortoise.close_connections()
    pass

if __name__ == '__main__':
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
