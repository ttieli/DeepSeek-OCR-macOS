#!/bin/bash

echo "=========================================="
echo "DeepSeek-OCR 一键运行脚本"
echo "=========================================="
echo ""

# 进入脚本所在目录
cd "$(dirname "$0")"

# 步骤 1: 运行修复
echo "步骤 1/2: 修复 CUDA 兼容性问题..."
python3 fix_mps_support.py
echo ""

# 步骤 2: 运行测试
echo "步骤 2/2: 开始 OCR 测试..."
echo ""
bash test.sh
