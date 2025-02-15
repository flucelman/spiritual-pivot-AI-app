from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse
import os
import json
from openai import OpenAI
from fastapi import HTTPException
from starlette.background import BackgroundTask
from starlette.concurrency import iterate_in_threadpool

router = APIRouter()

async def stream_response(response, request: Request):
    try:
        async for chunk in iterate_in_threadpool(response):
            if await request.is_disconnected():
                # 客户端断开连接，停止生成
                response.close()
                return
                
            if chunk and chunk.choices:
                data = {}
                
                # 获取推理内容（如果有）
                if hasattr(chunk.choices[0].delta, 'reasoning_content') and chunk.choices[0].delta.reasoning_content:
                    data['reasoning_content'] = chunk.choices[0].delta.reasoning_content
                else:
                    data['reasoning_content'] = ''
                    
                # 获取普通内容（如果有）
                if chunk.choices[0].delta.content:
                    data['content'] = chunk.choices[0].delta.content
                else:
                    data['content'] = ''
                
                # 只有当至少有一种内容存在时才发送
                if data['content'] or data['reasoning_content']:
                    yield f"data: {json.dumps(data)}\n\n"
                    
    except ConnectionResetError:
        print("客户端已断开连接")
        response.close()
        return
    except Exception as e:
        print(f"流式响应出错: {e}")
        response.close()
        return

@router.post("/")
async def chat(request: Request):
    try:
        data = await request.json()
        model_name = data.get("model_name")
        prompt = data.get("prompt")
        messages = data.get("messages", [])
        max_tokens = data.get("max_tokens", 4096)
        temperature = data.get("temperature", 0.7)
        # 转换消息格式
        formatted_messages = []
        
        # 添加系统提示词
        if prompt:
            formatted_messages.append({"role": "system", "content": prompt})
        
        # 直接添加消息历史，因为已经是正确的格式
        formatted_messages.extend(messages)

        
        # 选择模型和配置
        if model_name == "DeepSeek-R1":
            api_key = os.getenv("deepseek_api_key")
            base_url = os.getenv("deepseek_url")
            model = "ep-20250209190801-s22n6"
        elif model_name == "DeepSeek-v3":
            api_key = os.getenv("deepseek_api_key")
            base_url = os.getenv("deepseek_url")
            model = "ep-20250210104447-czrhz"
        elif model_name == "ChatGPT-4o":
            api_key = os.getenv("openai_api_key")
            base_url = os.getenv("openai_url")
            model = "gpt-4o"
        elif model_name == "Claude3.5":
            api_key = os.getenv("claude_api_key")
            base_url = os.getenv("claude_url")
            model = "claude-3-5-sonnet-20241022"
        else:
            return None

        client = OpenAI(
            api_key=api_key,
            base_url=base_url
        )

        response = client.chat.completions.create(
            model=model,
            messages=formatted_messages,
            stream=True,
            max_tokens=max_tokens,
            temperature=temperature,
            timeout=18000
        )

        return StreamingResponse(
            stream_response(response, request),
            media_type="text/event-stream",
            background=BackgroundTask(lambda: print("连接已关闭"))
        )
    except Exception as e:
        print(f"聊天请求出错: {e}")
        raise HTTPException(status_code=500, detail=str(e))
