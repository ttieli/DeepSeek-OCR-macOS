#!/usr/bin/env python3
"""
DeepSeek-OCR 文档转换测试脚本（MPS 优化版本）
用于测试图片OCR识别并转换为Markdown格式 - 专门针对 macOS MPS
"""

import os
import sys
from pathlib import Path
import torch

# 添加项目路径
project_dir = Path(__file__).parent / "DeepSeek-OCR"
if project_dir.exists():
    sys.path.insert(0, str(project_dir))

print("=" * 60)
print("DeepSeek-OCR 文档转换测试 (MPS 版本)")
print("=" * 60)
print()

# 检查环境
try:
    print(f"✓ PyTorch 版本: {torch.__version__}")

    if torch.backends.mps.is_available():
        print("✓ MPS (Metal Performance Shaders) 可用")
        device = "mps"
    else:
        print("⚠ MPS 不可用，使用 CPU")
        device = "cpu"
    print()
except ImportError as e:
    print(f"❌ 导入错误: {e}")
    print("请确保已激活 conda 环境: conda activate deepseek-ocr")
    sys.exit(1)

# 配置环境变量
os.environ["PYTORCH_MPS_HIGH_WATERMARK_RATIO"] = "0.0"

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
    from PIL import Image

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

    # 使用 bfloat16 并移动到 MPS 设备
    print(f"将模型移动到 {device} 设备...")
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

# 处理每张图片
print("=" * 60)
print("开始 OCR 识别...")
print("=" * 60)
print()

# 由于原始 infer 方法硬编码了 CUDA，我们需要使用替代方法
# 使用 CPU/MPS 兼容的方式
print("⚠ 注意: 由于 DeepSeek-OCR 官方代码硬编码了 CUDA 设备，")
print("   在 macOS (MPS) 上需要使用 CPU 模式或修改源码。")
print()
print("🔄 尝试使用 CPU 模式进行测试...")
print()

# 重新加载模型到 CPU
try:
    print("重新加载模型到 CPU...")
    model = model.to("cpu")
    device = "cpu"
    print("✓ 已切换到 CPU 模式")
    print()

    for idx, image_file in enumerate(test_images, 1):
        print(f"[{idx}/{len(test_images)}] 处理: {image_file.name}")

        # 准备提示词 - 文档转换为 Markdown
        prompt = "<image>\n<|grounding|>Convert the document to markdown."

        # 为每张图片创建单独的输出目录
        img_output_dir = output_dir / image_file.stem
        img_output_dir.mkdir(exist_ok=True)

        try:
            # 执行推理 - 使用 CPU
            print("  正在识别（CPU 模式，可能较慢）...")

            # 注意：这里需要修改 infer 调用或直接调用底层方法
            # 由于原始代码有 CUDA 依赖，我们先尝试直接调用
            result = model.infer(
                tokenizer,
                prompt=prompt,
                image_file=str(image_file),
                output_path=str(img_output_dir),
                base_size=1024,
                image_size=640,
                crop_mode=True,
                save_results=True,
                test_compress=True
            )

            # 保存识别结果到文本文件
            result_file = img_output_dir / f"{image_file.stem}_result.md"
            with open(result_file, 'w', encoding='utf-8') as f:
                f.write(f"# OCR 识别结果\n\n")
                f.write(f"**原始图片**: {image_file.name}\n\n")
                f.write(f"**识别时间**: {__import__('datetime').datetime.now()}\n\n")
                f.write(f"**设备**: {device}\n\n")
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
            print()
            print("💡 提示: DeepSeek-OCR 源码需要修改以支持 macOS MPS")
            print("   请参考下方的修复方案")
            import traceback
            traceback.print_exc()
            print()
            break

except Exception as e:
    print(f"❌ 切换到 CPU 失败: {e}")
    import traceback
    traceback.print_exc()

print("=" * 60)
print("测试结束")
print("=" * 60)
print()
print(f"输出目录: {output_dir}")
print()
print("⚠ 如果遇到 CUDA 错误，请查看下方的修复方案...")
print()
