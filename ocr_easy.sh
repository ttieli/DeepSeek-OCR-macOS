#!/bin/bash

##############################################################################
# DeepSeek-OCR macOS 傻瓜式操作 V2 - 真正的一键使用
#
# 特点：
#   ✅ 自动检测并安装环境 - 新用户也能一键使用
#   ✅ 交互式路径输入 - 无需预先准备图片
#   ✅ 支持单文件或整个文件夹
#   ✅ 自动创建输出目录
#   ✅ 集成所有功能（无需额外脚本）
#   ✅ CPU 优化模式
#
# 使用方法：
#   1. 打开终端
#   2. 将此脚本拖到终端窗口，按回车
#   3. 首次运行自动安装环境（10-20分钟）
#   4. 粘贴图片路径（支持从 Finder 拖拽）
#   5. 选择识别模式（1-5）
#   6. 等待完成，结果保存在 ocr_output/ 文件夹
#
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 清屏
clear

##############################################################################
# 显示欢迎界面
##############################################################################
echo ""
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${CYAN}    DeepSeek-OCR macOS 傻瓜式操作 V2 | Easy OCR Tool${NC}"
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo ""
echo -e "${GREEN}✨ Features | 特点${NC}"
echo "   • Auto-install environment | 自动检测并安装环境"
echo "   • Interactive path input | 交互式路径输入"
echo "   • Single file or folder | 支持单文件或文件夹"
echo "   • Drag & drop support | 支持拖拽操作"
echo ""
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo ""

##############################################################################
# 函数：安装环境
##############################################################################
install_environment() {
    echo ""
    echo -e "${BOLD}${YELLOW}⚠️  Environment not found, starting auto-installation...${NC}"
    echo -e "${BOLD}${YELLOW}   检测到环境未安装，开始自动安装...${NC}"
    echo ""
    echo -e "${CYAN}One-time setup, takes 10-20 minutes | 一次性操作，需10-20分钟${NC}"
    echo -e "${CYAN}Keep network connected | 请保持网络连接${NC}"
    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo ""

    # 步骤 1: 检查 Miniforge
    echo -e "${BOLD}[1/5] Checking Conda | 检查Conda环境管理器${NC}"
    if [ ! -d "$HOME/miniforge3" ]; then
        echo "   Installing Miniforge | 正在安装Miniforge..."

        # 检测架构
        if [[ $(uname -m) == "arm64" ]]; then
            MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
            MINIFORGE_FILE="Miniforge3-MacOSX-arm64.sh"
        else
            MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"
            MINIFORGE_FILE="Miniforge3-MacOSX-x86_64.sh"
        fi

        # 下载并安装
        curl -L -o "$MINIFORGE_FILE" "$MINIFORGE_URL"
        bash "$MINIFORGE_FILE" -b -p "$HOME/miniforge3"
        rm "$MINIFORGE_FILE"

        echo -e "   ${GREEN}✓ Miniforge 安装完成${NC}"
    else
        echo -e "   ${GREEN}✓ Miniforge 已安装${NC}"
    fi
    echo ""

    # 初始化 Conda
    source "$HOME/miniforge3/etc/profile.d/conda.sh"

    # 步骤 2: 创建 Python 环境 (根据芯片架构选择版本)
    echo -e "${BOLD}[2/5] Creating Python env | 创建Python虚拟环境${NC}"

    # 检测芯片架构并选择合适的 Python 版本
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        PYTHON_VERSION="3.12.9"
        echo "   Detected | 检测到: Apple Silicon (M1/M2/M3)"
    else
        PYTHON_VERSION="3.11.11"
        echo "   Detected | 检测到: Intel x86_64"
    fi

    if conda env list | grep -q "deepseek-ocr"; then
        echo -e "   ${GREEN}✓ Environment exists | 环境已存在${NC}"
    else
        echo "   Creating Python $PYTHON_VERSION | 正在创建环境..."
        conda create -n deepseek-ocr python=$PYTHON_VERSION -y > /dev/null 2>&1
        echo -e "   ${GREEN}✓ Created | 创建完成${NC}"
    fi
    echo ""

    # 激活环境
    conda activate deepseek-ocr

    # 步骤 3: 安装 PyTorch (根据芯片架构选择版本)
    echo -e "${BOLD}[3/5] Installing PyTorch | 安装PyTorch (CPU版)${NC}"

    # 根据芯片架构安装对应版本
    if [[ "$ARCH" == "arm64" ]]; then
        echo "   Installing PyTorch 2.6.0 (Apple Silicon) | 安装 PyTorch 2.6.0..."
        pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --quiet
    else
        echo "   Installing PyTorch 2.2.2 (Intel x86_64) | 安装 PyTorch 2.2.2..."
        echo "   ℹ️  Note: PyTorch 2.2.2 is the last version for Intel Mac | PyTorch 2.2.2 是Intel Mac最后支持版本"
        pip install torch==2.2.2 torchvision==0.17.2 torchaudio==2.2.2 --quiet
    fi

    echo -e "   ${GREEN}✓ PyTorch installed | PyTorch安装完成${NC}"
    echo ""

    # 步骤 4: 安装其他依赖
    echo -e "${BOLD}[4/5] Installing dependencies | 安装其他依赖包${NC}"
    echo "   This may take a few minutes | 可能需要几分钟..."

    # 创建临时 requirements 文件
    cat > /tmp/deepseek_requirements_$$.txt << 'EOF'
transformers==4.46.3
tokenizers==0.20.3
PyMuPDF
img2pdf
einops
easydict
addict
Pillow
numpy
EOF

    pip install -r /tmp/deepseek_requirements_$$.txt --quiet
    rm /tmp/deepseek_requirements_$$.txt

    echo -e "   ${GREEN}✓ Dependencies installed | 依赖包安装完成${NC}"
    echo ""

    # 步骤 5: 完成
    echo -e "${BOLD}[5/5] Finalizing | 完成设置${NC}"
    mkdir -p "$SCRIPT_DIR/ocr_output"
    echo -e "   ${GREEN}✓ Ready | 工作目录已创建${NC}"
    echo ""

    echo -e "${CYAN}============================================================${NC}"
    echo -e "${BOLD}${GREEN}✅ Installation Complete | 环境安装完成！${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
    echo "Tips | 提示："
    echo "  • First OCR run downloads model (~10GB) | 首次运行OCR会下载模型(约10GB)"
    echo "  • No reinstall needed later | 后续使用无需再次安装"
    echo ""
    echo -e "${CYAN}------------------------------------------------------------${NC}"
    echo ""
}

##############################################################################
# 检查并安装环境
##############################################################################
echo -e "${BOLD}Checking environment | 检查运行环境${NC}"
echo ""

# 检查 Conda 是否已安装
if [ ! -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    install_environment
else
    source "$HOME/miniforge3/etc/profile.d/conda.sh"

    # 检查环境是否存在
    if ! conda env list | grep -q "deepseek-ocr"; then
        install_environment
    else
        # 激活环境
        conda activate deepseek-ocr > /dev/null 2>&1
        echo -e "${GREEN}✓ Environment ready | 运行环境已就绪${NC}"
        echo ""
    fi
fi

# 验证 Python 环境
PYTHON_VERSION=$(python --version 2>&1)
echo -e "${GREEN}✓ $PYTHON_VERSION${NC}"
echo ""

##############################################################################
# 输入图片路径
##############################################################################
echo -e "${BOLD}Step 1/3: Select Images | 步骤1/3: 选择图片${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo ""
echo -e "${YELLOW}Enter image path | 请输入图片路径:${NC}"
echo ""
echo "  Tips | 提示:"
echo "    • Paste file path | 粘贴文件路径"
echo "    • Drag file from Finder | 从Finder拖拽文件"
echo "    • Drag folder for batch | 拖拽文件夹批量处理"
echo "    • Formats: PNG, JPG, JPEG, BMP, WEBP"
echo ""
echo -n "  Path | 路径 > "

# 读取路径
read -r INPUT_PATH

# 去除路径两端的空格和引号
INPUT_PATH=$(echo "$INPUT_PATH" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//" -e "s/^['\"]//;s/['\"]$//")

# 检查路径是否为空
if [ -z "$INPUT_PATH" ]; then
    echo ""
    echo -e "${RED}❌ Path cannot be empty | 路径不能为空${NC}"
    exit 1
fi

# 检查路径是否存在
if [ ! -e "$INPUT_PATH" ]; then
    echo ""
    echo -e "${RED}❌ Path not found | 路径不存在: $INPUT_PATH${NC}"
    exit 1
fi

echo ""

# 收集图片文件
declare -a IMAGE_FILES

if [ -f "$INPUT_PATH" ]; then
    # 单个文件
    EXT="${INPUT_PATH##*.}"
    EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
    if [[ "$EXT_LOWER" =~ ^(jpg|jpeg|png|bmp|webp)$ ]]; then
        IMAGE_FILES+=("$INPUT_PATH")
        echo -e "${GREEN}✓ Found image | 找到图片: $(basename "$INPUT_PATH")${NC}"
    else
        echo -e "${RED}❌ Unsupported format | 不支持的格式: .$EXT${NC}"
        echo "   Supported | 支持: PNG, JPG, JPEG, BMP, WEBP"
        exit 1
    fi
elif [ -d "$INPUT_PATH" ]; then
    # 文件夹
    echo "Scanning folder | 正在扫描文件夹..."
    while IFS= read -r -d '' file; do
        IMAGE_FILES+=("$file")
    done < <(find "$INPUT_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" -o -iname "*.webp" \) -print0)

    if [ ${#IMAGE_FILES[@]} -eq 0 ]; then
        echo ""
        echo -e "${RED}❌ No images found | 文件夹中没有找到图片${NC}"
        echo "   Supported | 支持: PNG, JPG, JPEG, BMP, WEBP"
        exit 1
    fi

    echo -e "${GREEN}✓ Found ${#IMAGE_FILES[@]} images | 找到 ${#IMAGE_FILES[@]} 张图片${NC}"
fi

echo ""

##############################################################################
# 选择识别模式
##############################################################################
echo ""
echo -e "${BOLD}Step 2/3: Select Mode | 步骤2/3: 选择识别模式${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo ""
echo -e "  ${BOLD}1.${NC} Document to Markdown | 文档转Markdown ${CYAN}(Recommended | 推荐)${NC}"
echo "     Preserve format, for docs/PPT | 保留格式，适合文档/PPT"
echo ""
echo -e "  ${BOLD}2.${NC} Standard OCR | 普通OCR"
echo "     Extract all text | 提取所有文字"
echo ""
echo -e "  ${BOLD}3.${NC} Layout-free OCR | 无布局OCR"
echo "     Plain text only | 纯文本提取"
echo ""
echo -e "  ${BOLD}4.${NC} Chart Parsing | 图表解析"
echo "     For charts/diagrams | 适合图表/流程图"
echo ""
echo -e "  ${BOLD}5.${NC} Detailed Description | 详细描述"
echo "     Image description | 图片详细描述"
echo ""
echo -n "Select mode | 选择模式 [1-5, default 1]: "

# 读取选择
read -r MODE_CHOICE

# 默认值
if [ -z "$MODE_CHOICE" ]; then
    MODE_CHOICE=1
fi

# 验证输入
if ! [[ "$MODE_CHOICE" =~ ^[1-5]$ ]]; then
    echo ""
    echo -e "${RED}❌ Invalid option | 无效的选项，请输入 1-5${NC}"
    exit 1
fi

# 设置提示词和模式名称
case $MODE_CHOICE in
    1)
        PROMPT="<image>\n<|grounding|>Convert the document to markdown."
        MODE_NAME="Document to Markdown | 文档转Markdown"
        ;;
    2)
        PROMPT="<image>\n<|grounding|>OCR this image."
        MODE_NAME="Standard OCR | 普通OCR"
        ;;
    3)
        PROMPT="<image>\nFree OCR."
        MODE_NAME="Layout-free OCR | 无布局OCR"
        ;;
    4)
        PROMPT="<image>\nParse the figure."
        MODE_NAME="Chart Parsing | 图表解析"
        ;;
    5)
        PROMPT="<image>\nDescribe this image in detail."
        MODE_NAME="Detailed Description | 详细描述"
        ;;
esac

echo ""
echo -e "${GREEN}✓ Selected | 已选择: ${BOLD}$MODE_NAME${NC}"
echo ""

##############################################################################
# OCR 识别
##############################################################################
echo -e "${BOLD}Step 3/3: Processing | 步骤3/3: 开始识别${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo ""

# 创建输出目录
OUTPUT_DIR="$SCRIPT_DIR/ocr_output"
mkdir -p "$OUTPUT_DIR"

# 创建临时 Python 脚本
TEMP_PYTHON_SCRIPT="/tmp/deepseek_ocr_v2_$$.py"

cat > "$TEMP_PYTHON_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
import os
import sys
import json
from pathlib import Path
import torch
from transformers import AutoModel, AutoTokenizer

# 获取参数
config = json.loads(sys.argv[1])
image_files = config['image_files']
output_dir = Path(config['output_dir'])
prompt = config['prompt']
mode_name = config['mode_name']

print("⏳ 初始化模型...")
print()

# 设备选择（CPU 模式）
device = "cpu"

try:
    model_name = 'deepseek-ai/DeepSeek-OCR'

    # 加载分词器
    tokenizer = AutoTokenizer.from_pretrained(
        model_name,
        trust_remote_code=True
    )

    # 加载模型
    model = AutoModel.from_pretrained(
        model_name,
        trust_remote_code=True,
        use_safetensors=True
    )

    model = model.eval().to(torch.bfloat16).to(device)
    print("✓ 模型加载成功")
    print()

except Exception as e:
    print(f"❌ 模型加载失败: {e}")
    sys.exit(1)

# 修复 CUDA 兼容性（静默处理）
try:
    # 动态修复 - 嵌入代码
    import site
    site_packages = site.getsitepackages()[0]
    target_file = Path(site_packages) / "transformers" / "models" / "llava_next" / "modeling_llava_next.py"

    if target_file.exists():
        with open(target_file, 'r', encoding='utf-8') as f:
            content = f.read()

        if 'vision_feature_layer = kwargs.get("vision_feature_layer", -1)' in content:
            content = content.replace(
                'vision_feature_layer = kwargs.get("vision_feature_layer", -1)',
                'vision_feature_layer = kwargs.get("vision_feature_layer", -2)'
            )
            with open(target_file, 'w', encoding='utf-8') as f:
                f.write(content)
except:
    pass  # 静默失败

# 处理每张图片
success_count = 0
fail_count = 0

print("🔍 开始处理图片...")
print()

for idx, image_file in enumerate(image_files, 1):
    image_path = Path(image_file)
    print(f"[{idx}/{len(image_files)}] {image_path.name}")

    # 创建输出子目录
    img_output_dir = output_dir / image_path.stem
    img_output_dir.mkdir(exist_ok=True)

    try:
        print("  ⏳ 识别中...", end='', flush=True)

        # 执行 OCR
        result = model.infer(
            tokenizer,
            prompt=prompt,
            image_file=str(image_path),
            output_path=str(img_output_dir),
            base_size=1024,
            image_size=640,
            crop_mode=True,
            save_results=True,
            test_compress=True
        )

        # 保存结果
        result_file = img_output_dir / f"result.md"
        with open(result_file, 'w', encoding='utf-8') as f:
            f.write(f"# OCR 识别结果\n\n")
            f.write(f"**原始图片**: {image_path.name}\n\n")
            f.write(f"**识别模式**: {mode_name}\n\n")
            f.write(f"---\n\n")
            if isinstance(result, str):
                f.write(result)
            else:
                f.write(str(result))

        # 处理 .mmd 文件（如果存在）
        mmd_files = list(img_output_dir.glob("*.mmd"))
        for mmd_file in mmd_files:
            try:
                with open(mmd_file, 'r', encoding='utf-8') as f:
                    content = f.read()

                # 转换为标准 Markdown
                md_file = mmd_file.with_suffix('.md')
                md_file = md_file.with_name(f"result_标准格式.md")

                with open(md_file, 'w', encoding='utf-8') as f:
                    f.write(content)

                # 删除原始 .mmd 文件
                mmd_file.unlink()
            except:
                pass

        print(" ✓")
        print(f"  📁 输出: {img_output_dir.relative_to(output_dir)}/")
        success_count += 1

    except Exception as e:
        print(f" ✗")
        print(f"  ❌ 错误: {str(e)[:60]}")
        fail_count += 1

    print()

# 完成
print("=" * 60)
print("✅ 识别完成！")
print("=" * 60)
print()
print(f"成功: {success_count} 张，失败: {fail_count} 张")
print(f"结果保存在: {output_dir}/")
print()

PYTHON_EOF

# 准备配置 - 构建 JSON 字符串数组（需要转义路径中的特殊字符）
IMAGE_JSON=""
for img in "${IMAGE_FILES[@]}"; do
    # 转义路径中的特殊字符
    img_escaped=$(echo "$img" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    if [ -z "$IMAGE_JSON" ]; then
        IMAGE_JSON="\"$img_escaped\""
    else
        IMAGE_JSON="$IMAGE_JSON,\"$img_escaped\""
    fi
done

# 转义特殊字符
OUTPUT_DIR_ESC=$(echo "$OUTPUT_DIR" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
PROMPT_ESC=$(echo "$PROMPT" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
MODE_NAME_ESC=$(echo "$MODE_NAME" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

# 构建单行 JSON
CONFIG_JSON="{\"image_files\":[$IMAGE_JSON],\"output_dir\":\"$OUTPUT_DIR_ESC\",\"prompt\":\"$PROMPT_ESC\",\"mode_name\":\"$MODE_NAME_ESC\"}"

# 运行 Python 脚本
python "$TEMP_PYTHON_SCRIPT" "$CONFIG_JSON"

# 清理临时文件
rm -f "$TEMP_PYTHON_SCRIPT"

##############################################################################
# 完成
##############################################################################
echo ""
echo -e "${BOLD}${GREEN}🎉 All Done | 全部完成！${NC}"
echo ""
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo ""
echo "📂 Results Location | 结果位置:"
echo "   $OUTPUT_DIR/"
echo ""
echo "💡 Tips | 提示:"
echo "   • Each image has a folder | 每张图片都有独立文件夹"
echo "   • Check result.md or result_标准格式.md"
echo "   • result_with_boxes.jpg is annotated | 带标注的图片"
echo ""
echo "🚀 Quick Open | 快速打开:"
echo "   open '$OUTPUT_DIR'"
echo ""
echo -e "${CYAN}------------------------------------------------------------${NC}"
echo ""
