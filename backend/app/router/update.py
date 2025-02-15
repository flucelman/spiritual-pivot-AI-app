from fastapi import APIRouter, Request, Response
from fastapi.responses import FileResponse
import os
from typing import Optional

router = APIRouter()

# APK文件存储路径
APK_DIR = "app/static/apk"
if not os.path.exists(APK_DIR):
    os.makedirs(APK_DIR)

class AppVersion:
    def __init__(self):
        self.current_version = "1.0.6"  # 当前最新版本号
        # 自动获取APK目录中的文件名
        apk_files = [f for f in os.listdir(APK_DIR) if f.endswith('.apk')]
        self.apk_filename = apk_files[0] if apk_files else None  # 获取app/static/apk第一个APK文件名
        self.force_update = False  # 是否强制更新
        self.update_description = """
            1.修改应用logo

            2.修复设置中心的温度bug
            """  # 更新说明
        self.min_version = "1.0.6"  # 最低支持版本

def compare_versions(version1: str, version2: str) -> int:
    """
    比较两个版本号
    返回: -1 如果 version1 < version2
          0 如果 version1 == version2
          1 如果 version1 > version2
    """
    v1_parts = list(map(int, version1.split('.')))
    v2_parts = list(map(int, version2.split('.')))
    
    # 确保两个版本号长度相同
    while len(v1_parts) < len(v2_parts):
        v1_parts.append(0)
    while len(v2_parts) < len(v1_parts):
        v2_parts.append(0)
    
    for i in range(len(v1_parts)):
        if v1_parts[i] < v2_parts[i]:
            return -1
        elif v1_parts[i] > v2_parts[i]:
            return 1
    return 0

@router.get("/check")
async def check_update(current_version: Optional[str] = None):
    """检查更新接口"""
    app_info = AppVersion()
    
    if not current_version:
        return {"error": "请提供当前版本号"}
    
    try:
        # 比较版本号
        version_comparison = compare_versions(current_version, app_info.current_version)
        need_update = version_comparison < 0
        
        # 检查是否低于最低支持版本
        force_update = compare_versions(current_version, app_info.min_version) < 0
        
        return {
            "need_update": need_update,
            "latest_version": app_info.current_version,
            "force_update": force_update or app_info.force_update,
            "update_description": app_info.update_description,
            "download_url": f"/api/update/download" if need_update else None
        }
    except ValueError:
        return {"error": "版本号格式错误"}

@router.get("/download")
async def download_apk():
    """下载APK接口"""
    app_info = AppVersion()
    if not app_info.apk_filename:
        return {"error": "APK目录中没有找到APK文件"}
    
    file_path = os.path.join(APK_DIR, app_info.apk_filename)
    
    if not os.path.exists(file_path):
        return {"error": "APK文件不存在"}
    
    return FileResponse(
        path=file_path,
        filename=app_info.apk_filename,
        media_type='application/vnd.android.package-archive'
    )

