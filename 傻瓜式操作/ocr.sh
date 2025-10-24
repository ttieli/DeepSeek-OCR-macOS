#!/bin/bash

##############################################################################
# DeepSeek-OCR macOS 使用脚本
#
# 功能：
#   - 交互式选择 OCR 模式
#   - 自动处理 test_images/ 中的所有图片
#   - 自动转换 .mmd 为 .md 格式
#   - CPU 优化模式
#
# 使用方法：
#   1. 将图片放入 test_images/ 目录
#   2. bash ocr.sh
#   3. 选择识别模式（1-5）
#   4. 查看 ocr_output/ 目录结果
#
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

##############################################################################
# 检查环境
##############################################################################
echo "============================================================"
echo "DeepSeek-OCR macOS 版"
echo "============================================================"
echo ""

# 激活 Conda 环境
if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniforge3/etc/profile.d/conda.sh"
    conda activate deepseek-ocr
else
    echo -e "${RED}❌ Conda 环境未找到${NC}"
    echo "请先运行: bash install.sh"
    exit 1
fi

# 检查 Python
echo "检查环境..."
python --version
echo ""

##############################################################################
# 检查图片
##############################################################################
if [ ! -d "test_images" ]; then
    mkdir -p test_images
fi

IMAGES=$(find test_images -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" \) | wc -l | tr -d ' ')

if [ "$IMAGES" -eq 0 ]; then
    echo -e "${YELLOW}⚠ test_images/ 目录中没有图片${NC}"
    echo ""
    echo "请将图片放入 test_images/ 目录，然后重新运行此脚本"
    echo ""
    echo "支持格式: PNG, JPG, JPEG, BMP, WEBP"
    exit 0
fi

echo -e "${GREEN}✓ 找到 $IMAGES 张图片${NC}"
echo ""

##############################################################################
# 创建 Python 脚本
##############################################################################
cat > /tmp/deepseek_ocr_runner.py << 'PYTHON_SCRIPT'
#!/usr/bin/env python3
import os
import sys
from pathlib import Path
import torch
from transformers import AutoModel, AutoTokenizer

# 配置 - 从命令行参数获取工作目录
SCRIPT_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path.cwd()
os.chdir(SCRIPT_DIR)

print("=" * 60)
print("初始化模型...")
print("=" * 60)
print()

# 设备选择（CPU 模式）
device = "cpu"
print(f"✓ 使用设备: {device} (macOS 优化)")
print()

# 查找图片
test_image_dir = Path("test_images")
image_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.webp']
test_images = []
for ext in image_extensions:
    test_images.extend(test_image_dir.glob(f"*{ext}"))
    test_images.extend(test_image_dir.glob(f"*{ext.upper()}"))

if not test_images:
    print("❌ 未找到测试图片")
    sys.exit(1)

print(f"找到 {len(test_images)} 张图片")
print()

# 提示词选择
print("=" * 60)
print("选择 OCR 识别模式")
print("=" * 60)
print()
print("  1. 文档转 Markdown（推荐）")
print("     保留格式和结构，适用于文档、PPT、报告")
print()
print("  2. 普通 OCR")
print("     提取所有文字，适用于一般文字识别")
print()
print("  3. 无布局 OCR")
print("     纯文本提取，适用于快速文字提取")
print()
print("  4. 图表解析")
print("     解析图表内容，适用于图表、流程图")
print()
print("  5. 详细描述")
print("     图片详细描述，适用于理解图片内容")
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
    except (KeyboardInterrupt, EOFError):
        print("\n\n已取消")
        sys.exit(0)

# 提示词映射
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

# 加载模型
print("=" * 60)
print("加载 DeepSeek-OCR 模型...")
print("（首次运行会下载约 10GB 模型，请耐心等待）")
print("=" * 60)
print()

try:
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

    model = model.eval().to(torch.bfloat16).to(device)
    print(f"✓ 模型加载成功")
    print()

except Exception as e:
    print(f"❌ 模型加载失败: {e}")
    sys.exit(1)

# 修复 CUDA 兼容性
print("修复 CUDA 兼容性...")
import subprocess
fix_script = Path(__file__).parent / "fix_cuda.py"
if fix_script.exists():
    subprocess.run([sys.executable, str(fix_script)], check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
print("✓ 兼容性修复完成")
print()

# 创建输出目录
output_dir = Path("ocr_output")
output_dir.mkdir(exist_ok=True)

# 处理每张图片
print("=" * 60)
print("开始 OCR 识别...")
print("=" * 60)
print()

success_count = 0
fail_count = 0

for idx, image_file in enumerate(test_images, 1):
    print(f"[{idx}/{len(test_images)}] {image_file.name}")
    print(f"  模式: {mode_name}")

    img_output_dir = output_dir / image_file.stem
    img_output_dir.mkdir(exist_ok=True)

    try:
        print("  识别中...", end='', flush=True)

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

        # 保存结果
        result_file = img_output_dir / f"{image_file.stem}_result.md"
        with open(result_file, 'w', encoding='utf-8') as f:
            f.write(f"# OCR 识别结果\n\n")
            f.write(f"**原始图片**: {image_file.name}\n\n")
            f.write(f"**识别模式**: {mode_name}\n\n")
            f.write(f"**使用设备**: {device}\n\n")
            f.write(f"---\n\n")
            if isinstance(result, str):
                f.write(result)
            else:
                f.write(str(result))

        print(" ✓ 完成")
        print(f"  输出: {img_output_dir}/")
        success_count += 1

    except Exception as e:
        print(f" ✗ 失败: {str(e)[:50]}...")
        fail_count += 1

    print()

# 转换 .mmd 为 .md
print("=" * 60)
print("转换格式...")
print("=" * 60)
print()

mmd_files = list(output_dir.rglob("*.mmd"))
if mmd_files:
    print(f"找到 {len(mmd_files)} 个 .mmd 文件，正在转换...")

    converter_script = Path(__file__).parent / "convert_mmd.py"
    if converter_script.exists():
        subprocess.run([sys.executable, str(converter_script), str(output_dir)],
                       check=False)
    else:
        print("⚠ 转换脚本未找到，跳过格式转换")
else:
    print("未找到 .mmd 文件")

print()

# 完成
print("=" * 60)
print("识别完成！")
print("=" * 60)
print()
print(f"成功: {success_count}，失败: {fail_count}")
print(f"结果保存在: {output_dir}/")
print()
print("打开结果目录:")
print(f"  open {output_dir}")
print()

PYTHON_SCRIPT

##############################################################################
# 运行 Python 脚本
##############################################################################
python /tmp/deepseek_ocr_runner.py "$SCRIPT_DIR"

# 清理临时文件
rm /tmp/deepseek_ocr_runner.py

echo -e "${GREEN}完成！${NC}"
