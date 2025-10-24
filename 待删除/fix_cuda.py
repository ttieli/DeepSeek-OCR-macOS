#!/usr/bin/env python3
"""自动修复 CUDA 兼容性（嵌入式版本）"""
import os
import re
from pathlib import Path

cache_dir = Path.home() / ".cache/huggingface/modules/transformers_modules/deepseek-ai/DeepSeek-OCR"
version_dirs = [d for d in cache_dir.iterdir() if d.is_dir() and not d.name.startswith('_')] if cache_dir.exists() else []

if version_dirs:
    model_file = sorted(version_dirs)[-1] / "modeling_deepseekocr.py"
    if model_file.exists():
        with open(model_file, 'r', encoding='utf-8') as f:
            content = f.read()

        backup_file = model_file.with_suffix('.py.backup')
        if not backup_file.exists():
            with open(backup_file, 'w', encoding='utf-8') as f:
                f.write(content)

        modified = content.replace('.cuda()', '.to(self.device)')

        if '@property' not in modified or 'def device' not in modified:
            pattern = r'(class DeepseekOCRForCausalLM.*?\n.*?)(    def )'
            replacement = r'\1    @property\n    def device(self):\n        """获取模型设备"""\n        if hasattr(self, "_device"):\n            return self._device\n        return next(self.parameters()).device\n\n\2'
            modified = re.sub(pattern, replacement, modified, count=1, flags=re.DOTALL)

        with open(model_file, 'w', encoding='utf-8') as f:
            f.write(modified)
