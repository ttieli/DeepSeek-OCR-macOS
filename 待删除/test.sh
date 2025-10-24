#!/bin/bash

# 简化的测试脚本 - 使用 conda 环境
echo "========================================"
echo "DeepSeek-OCR 测试"
echo "========================================"
echo ""

# 进入脚本所在目录
cd "$(dirname "$0")"

# 激活 conda 环境
echo "激活 conda 环境..."
source ~/miniforge3/etc/profile.d/conda.sh
conda activate deepseek-ocr

# 检查环境
echo "检查 Python 环境..."
which python
python --version
echo ""

# 检查 PyTorch
echo "检查 PyTorch..."
python -c "import torch; print('PyTorch 版本:', torch.__version__)"
echo ""

# 注意：根据 Hugging Face 社区反馈，CPU 模式在 macOS 上更稳定
# MPS fallback 会导致数值精度问题，因此直接使用 CPU 模式

# 运行测试
echo "========================================"
echo "开始 OCR 测试..."
echo "========================================"
python run_ocr_test.py
