#!/usr/bin/env python3
"""
修复 DeepSeek-OCR 以支持 macOS MPS/CPU
自动替换硬编码的 .cuda() 调用为设备无关的代码
"""

import os
import sys
from pathlib import Path

# 找到缓存的模型文件
cache_dir = Path.home() / ".cache/huggingface/modules/transformers_modules/deepseek-ai/DeepSeek-OCR"

# 查找最新的版本目录
version_dirs = [d for d in cache_dir.iterdir() if d.is_dir() and not d.name.startswith('_')]
if not version_dirs:
    print("❌ 未找到 DeepSeek-OCR 缓存文件")
    print("请先运行一次测试以下载模型文件")
    sys.exit(1)

# 使用最新的版本
version_dir = sorted(version_dirs)[-1]
model_file = version_dir / "modeling_deepseekocr.py"

if not model_file.exists():
    print(f"❌ 未找到模型文件: {model_file}")
    sys.exit(1)

print("=" * 60)
print("DeepSeek-OCR MPS/CPU 支持修复工具")
print("=" * 60)
print()
print(f"📁 模型文件: {model_file}")
print()

# 读取原始文件
with open(model_file, 'r', encoding='utf-8') as f:
    content = f.read()

# 备份原始文件
backup_file = model_file.with_suffix('.py.backup')
if not backup_file.exists():
    with open(backup_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✓ 已备份原始文件: {backup_file.name}")

# 修复策略：
# 1. 替换 .cuda() 为 .to(self.device)
# 2. 添加 device 属性

modifications = [
    # 在 __init__ 方法中添加 device 属性（如果没有）
    {
        'search': 'def __init__(self, config: DeepseekOCRConfig):',
        'replace': '''def __init__(self, config: DeepseekOCRConfig):
        # 添加设备支持（修复 macOS MPS 兼容性）
        import torch
        if torch.backends.mps.is_available():
            self._device = torch.device("mps")
        elif torch.cuda.is_available():
            self._device = torch.device("cuda")
        else:
            self._device = torch.device("cpu")
        ''',
        'count': 0
    },
    # 替换 .cuda() 调用
    {
        'search': '.cuda()',
        'replace': '.to(self.device)',
        'count': 0
    },
    # 修复 input_ids.unsqueeze(0).cuda()
    {
        'search': 'input_ids.unsqueeze(0).cuda()',
        'replace': 'input_ids.unsqueeze(0).to(self.device)',
        'count': 0
    },
    # 修复 images_crop.cuda()
    {
        'search': 'images_crop.cuda()',
        'replace': 'images_crop.to(self.device)',
        'count': 0
    },
    # 修复 images_ori.cuda()
    {
        'search': 'images_ori.cuda()',
        'replace': 'images_ori.to(self.device)',
        'count': 0
    },
    # 修复 images_seq_mask
    {
        'search': 'images_seq_mask.unsqueeze(0).cuda()',
        'replace': 'images_seq_mask.unsqueeze(0).to(self.device)',
        'count': 0
    },
]

# 执行替换
modified_content = content
print("🔧 开始修复...")
print()

# 简单的替换策略
modified_content = modified_content.replace('.cuda()', '.to(self.device)')

# 统计替换次数
cuda_count = content.count('.cuda()')
print(f"✓ 替换了 {cuda_count} 处 .cuda() 调用")
print()

# 添加 device 属性
# 在类中查找合适的位置添加
if '@property' not in modified_content or 'def device' not in modified_content:
    # 在类定义后添加 device 属性
    class_pattern = 'class DeepseekOCRForCausalLM'
    if class_pattern in modified_content:
        # 找到第一个方法定义
        import re
        pattern = r'(class DeepseekOCRForCausalLM.*?\n.*?)(    def )'
        replacement = r'\1    @property\n    def device(self):\n        """获取模型设备（CPU/MPS/CUDA 兼容）"""\n        if hasattr(self, "_device"):\n            return self._device\n        return next(self.parameters()).device\n\n\2'
        modified_content = re.sub(pattern, replacement, modified_content, count=1, flags=re.DOTALL)
        print("✓ 添加了 device 属性")
    else:
        print("⚠ 未找到类定义，跳过 device 属性添加")
else:
    print("✓ device 属性已存在")

print()

# 写入修改后的文件
with open(model_file, 'w', encoding='utf-8') as f:
    f.write(modified_content)

print("=" * 60)
print("✅ 修复完成！")
print("=" * 60)
print()
print("修改内容:")
print(f"  - 替换了 {cuda_count} 处硬编码的 .cuda() 调用")
print("  - 添加了设备无关的 .to(self.device) 方法")
print("  - 添加了自动设备检测 (MPS > CUDA > CPU)")
print()
print("现在可以重新运行测试:")
print("  bash test.sh")
print()
print("如需恢复原始文件:")
print(f"  cp {backup_file} {model_file}")
print()
