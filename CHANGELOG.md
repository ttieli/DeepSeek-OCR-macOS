# Changelog | 更新日志

All notable changes to this project will be documented in this file.

## [1.0.1] - 2025-01-15

### 🐛 Bug Fixes | 问题修复

- **Fixed missing dependencies** | 修复缺失依赖
  - Added `numpy<2`, `addict`, `matplotlib` to dependencies
  - 添加了 `numpy<2`, `addict`, `matplotlib` 依赖

- **Fixed transformers compatibility** | 修复 transformers 兼容性
  - Pinned `transformers==4.46.3` and `tokenizers==0.20.3` to avoid `LlamaFlashAttention2` import error
  - 固定 `transformers==4.46.3` 和 `tokenizers==0.20.3` 版本，避免 `LlamaFlashAttention2` 导入错误

- **Fixed MPS bfloat16 support** | 修复 MPS bfloat16 支持
  - MPS does not support bfloat16, now auto-converts to float16
  - MPS 不支持 bfloat16，现自动转换为 float16

- **Added LlamaFlashAttention2 compatibility patch** | 添加 LlamaFlashAttention2 兼容性补丁
  - Model remote code tries to import this class which was removed in newer transformers
  - 模型远程代码尝试导入此类，但在新版 transformers 中已被移除

### 📦 Installation | 安装方式

```bash
# Recommended installation (requires Python 3.12)
pipx install --python python3.12 git+https://github.com/ttieli/DeepSeek-OCR-macOS.git

# Basic usage
dsocr /path/to/image.png
```

---

## [1.0.0] - 2025-10-24

### 🎉 Initial Release | 首次发布

**One-Click OCR Tool for macOS** - A professional OCR solution with intelligent chip adaptation.
**一键式 OCR 工具** - 专业的 OCR 解决方案,智能适配 Mac 芯片。

### ✨ Features | 核心特性

- 🔧 **Smart Chip Detection** | 智能芯片检测
  - Auto-detects Apple Silicon (M1/M2/M3) or Intel x86_64
  - 自动识别 Apple Silicon 或 Intel 芯片
  - Installs optimal Python and PyTorch versions
  - 安装最优的 Python 和 PyTorch 版本

- 🚀 **One-Click Installation** | 一键安装
  - Zero manual configuration required
  - 无需任何手动配置
  - Auto-installs all dependencies (10-20 min)
  - 自动安装所有依赖（10-20分钟）

- 🌍 **Bilingual Interface** | 双语界面
  - Full English/Chinese support
  - 完整的中英文支持
  - Clear prompts and outputs
  - 清晰的提示和输出

- 📦 **Batch Processing** | 批量处理
  - Single file or entire folder
  - 单文件或整个文件夹
  - Drag & drop from Finder
  - 支持从访达拖拽

- 🎯 **5 OCR Modes** | 5种识别模式
  1. Document → Markdown (文档转Markdown)
  2. Standard OCR (普通OCR)
  3. Layout-free OCR (无布局OCR)
  4. Chart Parsing (图表解析)
  5. Detailed Description (详细描述)

### 💻 Chip Compatibility | 芯片兼容性

| Chip | Python | PyTorch | Status |
|------|--------|---------|--------|
| Apple Silicon (M1/M2/M3) | 3.12.9 | 2.6.0 | ✅ Latest versions |
| Intel x86_64 | 3.11.11 | 2.2.2 | ✅ Last official support |

### 🛠️ Technical Stack | 技术栈

- **Model**: DeepSeek-OCR (deepseek-ai/DeepSeek-OCR)
- **Framework**: PyTorch 2.2.2/2.6.0 (CPU-optimized)
- **NLP**: Transformers 4.46.3, Tokenizers 0.20.3
- **Image Processing**: Pillow, PyMuPDF, img2pdf
- **Utils**: einops, easydict, addict, numpy

### 📦 Installation | 安装内容

First run automatically installs:
首次运行自动安装:

1. **Miniforge3** (~100MB) - Python environment manager
2. **Python** (~200MB) - Chip-adaptive version
3. **PyTorch** (~500MB) - Deep learning framework
4. **Dependencies** (~300MB) - All required packages
5. **DeepSeek-OCR Model** (~10GB) - Downloads on first OCR

**Total**: ~11GB (one-time installation)
**总计**: 约11GB（一次性安装）

### 🔧 System Requirements | 系统要求

- macOS 10.15 or later
- 15GB free disk space
- Internet connection (first run only)
- Apple Silicon (M1/M2/M3) or Intel chip

### 📄 License | 开源协议

MIT License - Free and open source
MIT 协议 - 自由开源

### 🙏 Credits | 致谢

- [DeepSeek-AI](https://github.com/deepseek-ai) - DeepSeek-OCR model
- [PyTorch](https://pytorch.org/) - Deep learning framework
- [Hugging Face](https://huggingface.co/) - Model hosting platform

---

**Note**: PyTorch discontinued macOS Intel x86_64 support after version 2.2.2 (January 2024).
**说明**: PyTorch 于 2024年1月后停止支持 Intel Mac x86_64。
