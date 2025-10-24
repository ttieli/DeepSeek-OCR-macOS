#!/bin/bash

##############################################################################
# DeepSeek-OCR macOS 一键安装脚本
#
# 功能：
#   - 自动安装 Conda 环境
#   - 下载 DeepSeek-OCR 模型
#   - 配置 macOS 优化（CPU 模式）
#   - 修复 CUDA 兼容性问题
#
# 使用方法：
#   bash install.sh
#
##############################################################################

set -e  # 遇到错误立即退出

echo "============================================================"
echo "DeepSeek-OCR macOS 一键安装脚本"
echo "============================================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

##############################################################################
# 步骤 1: 检查 Homebrew
##############################################################################
echo "步骤 1/6: 检查 Homebrew..."
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}⚠ Homebrew 未安装，正在安装...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}✓ Homebrew 已安装${NC}"
fi
echo ""

##############################################################################
# 步骤 2: 检查 Miniforge (Conda)
##############################################################################
echo "步骤 2/6: 检查 Conda 环境..."
if [ ! -d "$HOME/miniforge3" ]; then
    echo -e "${YELLOW}⚠ Miniforge 未安装，正在安装...${NC}"

    # 下载 Miniforge
    if [[ $(uname -m) == "arm64" ]]; then
        curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh"
        bash Miniforge3-MacOSX-arm64.sh -b -p $HOME/miniforge3
        rm Miniforge3-MacOSX-arm64.sh
    else
        curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh"
        bash Miniforge3-MacOSX-x86_64.sh -b -p $HOME/miniforge3
        rm Miniforge3-MacOSX-x86_64.sh
    fi
else
    echo -e "${GREEN}✓ Miniforge 已安装${NC}"
fi

# 初始化 Conda
source "$HOME/miniforge3/etc/profile.d/conda.sh"
echo ""

##############################################################################
# 步骤 3: 创建 Conda 环境
##############################################################################
echo "步骤 3/6: 创建 Conda 环境..."
if conda env list | grep -q "deepseek-ocr"; then
    echo -e "${YELLOW}环境 deepseek-ocr 已存在${NC}"
    read -p "是否删除并重新创建？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        conda env remove -n deepseek-ocr -y
        conda create -n deepseek-ocr python=3.12.9 -y
    fi
else
    conda create -n deepseek-ocr python=3.12.9 -y
fi

conda activate deepseek-ocr
echo -e "${GREEN}✓ Conda 环境已创建并激活${NC}"
echo ""

##############################################################################
# 步骤 4: 安装 PyTorch
##############################################################################
echo "步骤 4/6: 安装 PyTorch (CPU 版本)..."
pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --quiet
echo -e "${GREEN}✓ PyTorch 安装完成${NC}"
echo ""

##############################################################################
# 步骤 5: 安装其他依赖
##############################################################################
echo "步骤 5/6: 安装其他依赖..."

# 创建临时 requirements.txt
cat > /tmp/deepseek_requirements.txt << EOF
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

pip install -r /tmp/deepseek_requirements.txt --quiet
rm /tmp/deepseek_requirements.txt

echo -e "${GREEN}✓ 所有依赖安装完成${NC}"
echo ""

##############################################################################
# 步骤 6: 创建测试目录
##############################################################################
echo "步骤 6/6: 创建工作目录..."
mkdir -p test_images
mkdir -p ocr_output
echo -e "${GREEN}✓ 工作目录已创建${NC}"
echo ""

##############################################################################
# 完成
##############################################################################
echo "============================================================"
echo -e "${GREEN}✅ 安装完成！${NC}"
echo "============================================================"
echo ""
echo "使用方法："
echo "  1. 将图片放入 test_images/ 目录"
echo "  2. 运行: bash ocr.sh"
echo ""
echo "提示："
echo "  - 首次运行会自动下载模型（约 10GB）"
echo "  - CPU 模式每张图片约 3-5 分钟"
echo "  - 结果保存在 ocr_output/ 目录"
echo ""
echo "激活环境："
echo "  source ~/miniforge3/etc/profile.d/conda.sh"
echo "  conda activate deepseek-ocr"
echo ""
