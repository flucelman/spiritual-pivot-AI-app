import pytesseract
from PIL import Image
import os
import cv2
import numpy as np

pytesseract.pytesseract.tesseract_cmd = r'E:\tesseractOcr\tesseract.exe'

def preprocess_image(image):
    """
    图像预处理函数
    """
    # 转换为灰度图
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # 自适应阈值二值化
    binary = cv2.adaptiveThreshold(
        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
        cv2.THRESH_BINARY, 11, 2
    )
    
    # 降噪
    denoised = cv2.fastNlMeansDenoising(binary)
    
    return denoised

def ocr_image(image_path, lang='chi_sim'):
    """
    使用Tesseract进行图片OCR识别
    
    Args:
        image_path: 图片路径
        lang: 识别语言，默认为英语+简体中文('eng+chi_sim')
        
    Returns:
        识别出的文本内容
    """
    try:
        # 获取当前文件所在目录
        current_dir = os.path.dirname(os.path.abspath(__file__))
        # 构建图片的完整路径并进行路径规范化
        full_image_path = os.path.normpath(os.path.join(current_dir, image_path))
        
        # 检查文件是否存在
        if not os.path.exists(full_image_path):
            print(f"文件不存在: {full_image_path}")
            return None
            
        # 使用OpenCV读取图片
        img = cv2.imdecode(np.fromfile(full_image_path, dtype=np.uint8), cv2.IMREAD_COLOR)
        
        if img is None:
            print(f"无法读取图片: {full_image_path}")
            return None
        
        # 图像预处理
        processed_img = preprocess_image(img)
        
        # 将OpenCV图像格式转换为PIL格式
        pil_img = Image.fromarray(processed_img)
        
        # 使用Tesseract进行OCR识别
        # 添加额外的配置参数以提高识别准确度
        custom_config = r'--oem 3 --psm 6'
        text = pytesseract.image_to_string(
            pil_img, 
            lang=lang,
            config=custom_config
        )
        
        return text.strip()
        
    except Exception as e:
        print(f"OCR识别出错: {str(e)}")
        return None

def test_ocr():
    """
    测试OCR功能
    """
    # 测试中英文混合识别
    result = ocr_image("image.png")
    print("识别结果:", result)

if __name__ == "__main__":
    test_ocr()
