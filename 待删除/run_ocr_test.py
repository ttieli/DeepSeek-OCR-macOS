#!/usr/bin/env python3
"""
DeepSeek-OCR 文档转换测试脚本
用于测试图片OCR识别并转换为Markdown格式
"""

import os
import sys
from pathlib import Path

# 添加项目路径
project_dir = Path(__file__).parent / "DeepSeek-OCR"
if project_dir.exists():
    sys.path.insert(0, str(project_dir))

print("=" * 60)
print("DeepSeek-OCR 文档转换测试")
print("=" * 60)
print()

# 检查环境
try:
    import torch
    print(f"✓ PyTorch 版本: {torch.__version__}")

    # 根据 Hugging Face 讨论 #20 和 #21：
    # CPU 模式在 macOS 上性能更好（3GB内存 vs MPS的19GB）
    # MPS fallback 会导致数值精度问题
    if torch.backends.mps.is_available():
        print("ℹ MPS 可用，但使用 CPU 模式以获得更好的兼容性")
        print("  （MPS fallback 会导致精度问题，CPU 模式更稳定）")
    device = "cpu"
    print(f"✓ 使用设备: {device}")
    print()
except ImportError as e:
    print(f"❌ 导入错误: {e}")
    print("请确保已激活 conda 环境: conda activate deepseek-ocr")
    sys.exit(1)

# 配置环境变量
# 注意：直接使用 CPU 模式，不需要 MPS fallback

# 检查图片
test_image_dir = Path(__file__).parent / "test_images"
if not test_image_dir.exists():
    test_image_dir.mkdir(parents=True)
    print(f"⚠ 测试图片目录已创建: {test_image_dir}")
    print("请将测试图片放入该目录")
    sys.exit(0)

# 查找测试图片
image_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.webp']
test_images = []
for ext in image_extensions:
    test_images.extend(test_image_dir.glob(f"*{ext}"))

if not test_images:
    print(f"❌ 在 {test_image_dir} 中未找到测试图片")
    print(f"支持的格式: {', '.join(image_extensions)}")
    sys.exit(1)

print(f"找到 {len(test_images)} 张测试图片:")
for img in test_images:
    print(f"  - {img.name}")
print()

# 加载模型
print("正在加载 DeepSeek-OCR 模型...")
print("(首次运行会从 Hugging Face 下载模型，约 10GB，请耐心等待)")
print()

try:
    from transformers import AutoModel, AutoTokenizer

    model_name = 'deepseek-ai/DeepSeek-OCR'

    print("加载分词器...")
    tokenizer = AutoTokenizer.from_pretrained(
        model_name,
        trust_remote_code=True
    )

    print("加载模型...")
    model = AutoModel.from_pretrained(
        model_name,
        trust_remote_code=True,
        use_safetensors=True
    )

    # 使用 bfloat16 减少内存占用
    model = model.eval().to(torch.bfloat16).to(device)
    print(f"✓ 模型加载成功，使用设备: {device}")
    print()

except Exception as e:
    print(f"❌ 模型加载失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# 创建输出目录
output_dir = Path(__file__).parent / "ocr_output"
output_dir.mkdir(exist_ok=True)

# 提示词选择
print("=" * 60)
print("选择识别模式")
print("=" * 60)
print()
print("请选择 OCR 识别模式：")
print()
print("  1. 文档转 Markdown（推荐）")
print("     - 保留文档格式和结构")
print("     - 适用于：文档、PPT、报告")
print()
print("  2. 普通 OCR")
print("     - 提取所有文字内容")
print("     - 适用于：一般文字识别")
print()
print("  3. 无布局 OCR")
print("     - 仅提取文字，不保留布局")
print("     - 适用于：纯文本提取")
print()
print("  4. 图表解析")
print("     - 解析图表、图形内容")
print("     - 适用于：图表、统计图、流程图")
print()
print("  5. 详细描述")
print("     - 获取图片的详细描述")
print("     - 适用于：理解图片内容")
print()

# 获取用户选择
while True:
    try:
        choice = input("请输入选项（1-5）[默认: 1]: ").strip()
        if choice == "":
            choice = "1"
        choice_num = int(choice)
        if 1 <= choice_num <= 5:
            break
        else:
            print("❌ 请输入 1-5 之间的数字")
    except ValueError:
        print("❌ 请输入有效的数字")
    except KeyboardInterrupt:
        print("\n\n已取消")
        sys.exit(0)

# 根据选择设置提示词
prompt_map = {
    1: ("<image>\n<|grounding|>Convert the document to markdown.", "文档转 Markdown"),
    2: ("<image>\n<|grounding|>OCR this image.", "普通 OCR"),
    3: ("<image>\nFree OCR.", "无布局 OCR"),
    4: ("<image>\nParse the figure.", "图表解析"),
    5: ("<image>\nDescribe this image in detail.", "详细描述")
}

prompt, mode_name = prompt_map[choice_num]
print()
print(f"✓ 已选择: {mode_name}")
print()

# 处理每张图片
print("=" * 60)
print("开始 OCR 识别...")
print("=" * 60)
print()

for idx, image_file in enumerate(test_images, 1):
    print(f"[{idx}/{len(test_images)}] 处理: {image_file.name}")
    print(f"  识别模式: {mode_name}")

    # 为每张图片创建单独的输出目录
    img_output_dir = output_dir / image_file.stem
    img_output_dir.mkdir(exist_ok=True)

    try:
        # 执行推理
        print("  正在识别...")
        result = model.infer(
            tokenizer,
            prompt=prompt,
            image_file=str(image_file),
            output_path=str(img_output_dir),
            base_size=1024,      # 基础分辨率
            image_size=640,      # 图像尺寸
            crop_mode=True,      # 启用裁剪模式
            save_results=True,   # 保存结果
            test_compress=True   # 测试压缩
        )

        # 保存识别结果到文本文件
        result_file = img_output_dir / f"{image_file.stem}_result.md"
        with open(result_file, 'w', encoding='utf-8') as f:
            f.write(f"# OCR 识别结果\n\n")
            f.write(f"**原始图片**: {image_file.name}\n\n")
            f.write(f"**识别模式**: {mode_name}\n\n")
            f.write(f"**识别时间**: {__import__('datetime').datetime.now()}\n\n")
            f.write(f"**使用设备**: {device}\n\n")
            f.write(f"---\n\n")
            if isinstance(result, str):
                f.write(result)
            else:
                f.write(str(result))

        print(f"  ✓ 识别完成")
        print(f"  ✓ 结果已保存到: {img_output_dir}")
        print(f"  ✓ Markdown 文件: {result_file.name}")
        print()

    except Exception as e:
        print(f"  ❌ 识别失败: {e}")
        import traceback
        traceback.print_exc()
        print()
        continue

print("=" * 60)
print("OCR 识别完成!")
print("=" * 60)
print()
print(f"输出目录: {output_dir}")
print()
print("你可以查看输出目录中的 Markdown 文件来查看识别结果")
