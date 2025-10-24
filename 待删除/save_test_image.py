#!/usr/bin/env python3
"""
保存测试图片的辅助脚本
"""
import base64
from pathlib import Path

# 这里需要你手动保存图片
# 由于我无法直接访问用户上传的图片，你需要手动将图片保存到 test_images 目录

test_images_dir = Path(__file__).parent / "test_images"
test_images_dir.mkdir(exist_ok=True)

print("=" * 60)
print("测试图片保存说明")
print("=" * 60)
print()
print(f"请将你的测试图片保存到以下目录:")
print(f"  {test_images_dir}")
print()
print("支持的图片格式:")
print("  - JPG/JPEG")
print("  - PNG")
print("  - BMP")
print("  - WEBP")
print()
print("保存完成后，运行以下命令进行 OCR 测试:")
print("  conda activate deepseek-ocr")
print("  python run_ocr_test.py")
print()
