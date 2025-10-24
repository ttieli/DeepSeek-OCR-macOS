#!/bin/bash
set -e  # 遇到错误立即退出

echo "======================================"
echo "DeepSeek-OCR MacOS ARM 一键部署脚本"
echo "======================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否在 macOS 上运行
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}错误：此脚本仅支持 macOS 系统${NC}"
    exit 1
fi

# 检查是否为 Apple Silicon
if [[ $(uname -m) != "arm64" ]]; then
    echo -e "${YELLOW}警告：此脚本针对 Apple Silicon (M1/M2/M3) 优化${NC}"
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 项目根目录
PROJECT_DIR="/Users/tieli/Library/Mobile Documents/com~apple~CloudDocs/Project/DeepSeek_OCR_for_MacOS"
DEEPSEEK_DIR="$PROJECT_DIR/DeepSeek-OCR"

echo -e "${GREEN}步骤 1/7: 检查系统环境${NC}"
# 检查 Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}未检测到 Homebrew，正在安装...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✓ Homebrew 已安装"
fi

echo ""
echo -e "${GREEN}步骤 2/7: 检查并安装基础依赖${NC}"
# 安装基础依赖
for pkg in python@3.10 cmake wget; do
    if brew list $pkg &> /dev/null; then
        echo "✓ $pkg 已安装"
    else
        echo "正在安装 $pkg..."
        brew install $pkg
    fi
done

echo ""
echo -e "${GREEN}步骤 3/7: 检查 Conda 环境${NC}"
# 检查 Conda 是否已安装
if [ -d "$HOME/miniforge3" ]; then
    echo "✓ Miniforge 已安装在 $HOME/miniforge3"
    # 直接初始化现有的 conda
    eval "$($HOME/miniforge3/bin/conda shell.bash hook)"
elif [ -d "$HOME/anaconda3" ]; then
    echo "✓ Anaconda 已安装"
    eval "$($HOME/anaconda3/bin/conda shell.bash hook)"
elif [ -d "$HOME/miniconda3" ]; then
    echo "✓ Miniconda 已安装"
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
elif ! command -v conda &> /dev/null; then
    echo -e "${YELLOW}未检测到 Conda，正在安装 Miniforge...${NC}"
    cd /tmp
    if [ ! -f "Miniforge3-MacOSX-arm64.sh" ]; then
        wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh
    fi
    bash Miniforge3-MacOSX-arm64.sh -b
    # 直接初始化 conda 到当前 shell
    eval "$($HOME/miniforge3/bin/conda shell.bash hook)"
    echo "✓ Conda 安装完成"
else
    echo "✓ Conda 已安装"
fi

echo ""
echo -e "${GREEN}步骤 4/7: 创建 Conda 环境${NC}"
# 确保 conda 命令可用
if [ -f "$HOME/miniforge3/bin/conda" ]; then
    eval "$($HOME/miniforge3/bin/conda shell.bash hook)"
elif [ -f "$HOME/anaconda3/bin/conda" ]; then
    eval "$($HOME/anaconda3/bin/conda shell.bash hook)"
elif [ -f "$HOME/miniconda3/bin/conda" ]; then
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
else
    eval "$(conda shell.bash hook)"
fi

# 检查环境是否存在
if conda env list | grep -q "deepseek-ocr"; then
    echo "环境 deepseek-ocr 已存在"
    read -p "是否删除并重新创建？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        conda env remove -n deepseek-ocr -y
        conda create -n deepseek-ocr python=3.12.9 -y
    fi
else
    conda create -n deepseek-ocr python=3.12.9 -y
fi

# 激活环境
conda activate deepseek-ocr

echo ""
echo -e "${GREEN}步骤 5/7: 克隆 DeepSeek-OCR 项目${NC}"
cd "$PROJECT_DIR"
if [ -d "$DEEPSEEK_DIR" ]; then
    echo "DeepSeek-OCR 目录已存在"
    read -p "是否删除并重新克隆？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DEEPSEEK_DIR"
        git clone https://github.com/deepseek-ai/DeepSeek-OCR.git
    fi
else
    git clone https://github.com/deepseek-ai/DeepSeek-OCR.git
fi

cd "$DEEPSEEK_DIR"

echo ""
echo -e "${GREEN}步骤 6/7: 安装 Python 依赖${NC}"
echo "安装 PyTorch (CPU版本，适配 MPS)..."
pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0

echo ""
echo "安装项目依赖..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    echo -e "${YELLOW}警告：未找到 requirements.txt，跳过${NC}"
fi

echo ""
echo "安装 Flash Attention..."
pip install flash-attn==2.7.3 --no-build-isolation || echo -e "${YELLOW}Flash Attention 安装失败，继续...${NC}"

echo ""
echo -e "${GREEN}步骤 7/7: 创建示例脚本${NC}"
cat > "$PROJECT_DIR/test_ocr.py" << 'EOF'
from transformers import AutoModel, AutoTokenizer
import torch
import os

# 配置MacOS ARM优化
if torch.backends.mps.is_available():
    print("✓ MPS (Metal Performance Shaders) 可用")
    device = "mps"
else:
    print("⚠ MPS 不可用，使用 CPU")
    device = "cpu"

os.environ["PYTORCH_MPS_HIGH_WATERMARK_RATIO"] = "0.0"

# 加载模型和分词器
model_name = 'deepseek-ai/DeepSeek-OCR'
print(f"正在加载模型: {model_name}")
print("首次运行会从 Hugging Face 下载模型，可能需要较长时间...")

tokenizer = AutoTokenizer.from_pretrained(
    model_name,
    trust_remote_code=True
)

model = AutoModel.from_pretrained(
    model_name,
    _attn_implementation='flash_attention_2',
    trust_remote_code=True,
    use_safetensors=True
)

model = model.eval().to(torch.bfloat16).to(device)

print(f"✓ 模型加载成功，使用设备: {device}")
print("")
print("使用示例:")
print("  prompt = '<image>\\n<|grounding|>Convert the document to markdown.'")
print("  image_file = 'your_image.jpg'")
print("  output_path = 'output/'")
print("")
print("  res = model.infer(")
print("      tokenizer,")
print("      prompt=prompt,")
print("      image_file=image_file,")
print("      output_path=output_path,")
print("      base_size=1024,")
print("      image_size=640,")
print("      crop_mode=True,")
print("      save_results=True,")
print("      test_compress=True")
print("  )")
EOF

echo ""
echo -e "${GREEN}======================================"
echo "部署完成！"
echo "======================================${NC}"
echo ""
echo "使用方法："
echo "1. 激活环境："
echo "   conda activate deepseek-ocr"
echo ""
echo "2. 运行测试脚本："
echo "   cd $PROJECT_DIR"
echo "   python test_ocr.py"
echo ""
echo "3. 项目目录："
echo "   $DEEPSEEK_DIR"
echo ""
echo -e "${YELLOW}注意事项：${NC}"
echo "- 首次运行会自动下载模型（约 10GB），请确保网络畅通"
echo "- 推荐配置：16GB+ 内存，Apple Silicon 芯片"
echo "- 如需使用其他分辨率模式，参考文档调整 base_size 和 image_size"
echo ""
echo -e "${GREEN}常用提示词模板：${NC}"
echo "  文档转换: '<image>\\n<|grounding|>Convert the document to markdown.'"
echo "  普通OCR: '<image>\\n<|grounding|>OCR this image.'"
echo "  无布局OCR: '<image>\\nFree OCR.'"
echo "  图表解析: '<image>\\nParse the figure.'"
echo ""
