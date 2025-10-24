# DeepSeek-OCR macOS

<div align="center">

**One-click OCR tool for macOS with intelligent chip adaptation**
**一键使用的 OCR 图片识别工具，智能适配 Mac 芯片**

[![Platform](https://img.shields.io/badge/platform-macOS%2010.15%2B-lightgrey)](https://www.apple.com/macos)
[![Python](https://img.shields.io/badge/python-3.11%20%7C%203.12-blue)](https://www.python.org/)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.2.2%20%7C%202.6.0-ee4c2c)](https://pytorch.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Chip](https://img.shields.io/badge/chip-Apple%20Silicon%20%7C%20Intel-orange)](https://www.apple.com)

[English](#english) | [中文](#中文)

</div>

---

## English

### ⚡ Quick Start

```bash
# Clone repository
git clone https://github.com/ttieli/DeepSeek-OCR-macOS.git
cd DeepSeek-OCR-macOS

# Run script
bash ocr_easy.sh
```

**That's it!** First run auto-installs everything (10-20 min).

### ✨ Features

- 🔧 **Smart Chip Detection** - Auto-detects Apple Silicon/Intel, installs optimal versions
- 🚀 **One-Click Install** - Zero manual configuration required
- 🌍 **Bilingual UI** - Full English/Chinese interface
- 📦 **Batch Processing** - Single file or entire folder support
- 🎯 **5 OCR Modes** - Document, Standard, Layout-free, Chart, Description
- 📝 **Markdown Output** - Clean, formatted results

### 🎯 OCR Modes

| Mode | Description | Best For |
|------|-------------|----------|
| **1. Document → Markdown** | Preserves formatting | Documents, PPTs, Reports |
| **2. Standard OCR** | Extracts all text | General text recognition |
| **3. Layout-free OCR** | Plain text only | Quick text extraction |
| **4. Chart Parsing** | Analyzes charts | Diagrams, Flowcharts |
| **5. Detailed Description** | Image description | Understanding content |

### 💻 Chip Compatibility

| Chip | Python | PyTorch | Status |
|------|--------|---------|--------|
| **Apple Silicon** (M1/M2/M3) | 3.12.9 | 2.6.0 | ✅ Latest versions |
| **Intel x86_64** | 3.11.11 | 2.2.2 | ✅ Last official support |

*Note: PyTorch discontinued Intel Mac support after v2.2.2 (Jan 2024)*

### 📦 Installation Details

**First run installs:**

1. **Miniforge3** (~100MB) - Python environment manager
2. **Python** (~200MB) - Version auto-selected by chip
3. **PyTorch** (~500MB) - Deep learning framework
4. **Dependencies** (~300MB) - transformers, tokenizers, PyMuPDF, etc.
5. **DeepSeek-OCR Model** (~10GB) - Downloads on first OCR run

**Total:** ~11GB (one-time)

### 🔧 System Requirements

- macOS 10.15+
- 15GB free space
- Internet connection (first run only)
- Apple Silicon (M1/M2/M3) or Intel chip

### 📖 Usage

```bash
# 1. Run script
bash ocr_easy.sh

# 2. Enter image path (drag from Finder or paste path)
Path > /path/to/image.png

# 3. Select mode (1-5)
Select mode [1-5, default 1]: 1

# 4. Wait for results in ocr_output/
```

### 📁 Output Structure

```
ocr_output/
└── [image_name]/
    ├── result.md                # OCR result
    ├── result_标准格式.md        # Markdown format
    └── result_with_boxes.jpg    # Annotated image
```

### 🛠️ Technical Stack

- **Core**: DeepSeek-OCR Model
- **Framework**: PyTorch (CPU-optimized)
- **NLP**: Transformers 4.46.3, Tokenizers 0.20.3
- **Image**: Pillow, PyMuPDF, img2pdf
- **Tools**: einops, easydict, numpy

### ❓ FAQ

**Q: How long does first run take?**
A: Environment install (10-20 min) + Model download on first OCR (5-15 min)

**Q: How much space needed?**
A: ~11GB total (environment ~1.1GB + model ~10GB)

**Q: Does it work on Intel Mac?**
A: Yes! Auto-installs compatible versions (Python 3.11 + PyTorch 2.2.2)

**Q: Can I use offline after setup?**
A: Yes, after environment and model download

### 📄 License

MIT License - see [LICENSE](LICENSE)

### 🙏 Credits

- [DeepSeek-AI](https://github.com/deepseek-ai) - DeepSeek-OCR model
- [PyTorch](https://pytorch.org/) - Deep learning framework
- [Hugging Face](https://huggingface.co/) - Model hosting

---

## 中文

### ⚡ 快速开始

```bash
# 克隆仓库
git clone https://github.com/ttieli/DeepSeek-OCR-macOS.git
cd DeepSeek-OCR-macOS

# 运行脚本
bash ocr_easy.sh
```

**就这么简单!** 首次运行自动安装所有环境（10-20分钟）。

### ✨ 核心特性

- 🔧 **智能芯片检测** - 自动识别 Apple Silicon/Intel，安装最优版本
- 🚀 **一键安装** - 零手动配置，开箱即用
- 🌍 **中英双语** - 完整的中英文界面
- 📦 **批量处理** - 支持单文件或整个文件夹
- 🎯 **5种识别模式** - 文档、标准、无布局、图表、描述
- 📝 **Markdown输出** - 格式化的清晰结果

### 🎯 识别模式

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| **1. 文档转Markdown** | 保留格式 | 文档、PPT、报告 |
| **2. 普通OCR** | 提取所有文字 | 一般文字识别 |
| **3. 无布局OCR** | 纯文本提取 | 快速文字提取 |
| **4. 图表解析** | 解析图表内容 | 图表、流程图 |
| **5. 详细描述** | 图片详细描述 | 理解图片内容 |

### 💻 芯片兼容性

| 芯片类型 | Python | PyTorch | 状态 |
|---------|--------|---------|------|
| **Apple Silicon** (M1/M2/M3) | 3.12.9 | 2.6.0 | ✅ 最新版本 |
| **Intel x86_64** | 3.11.11 | 2.2.2 | ✅ 最后官方支持版 |

*说明: PyTorch 于 2024年1月后停止支持 Intel Mac*

### 📦 安装详情

**首次运行安装：**

1. **Miniforge3** (~100MB) - Python 环境管理器
2. **Python** (~200MB) - 根据芯片自动选择版本
3. **PyTorch** (~500MB) - 深度学习框架
4. **依赖包** (~300MB) - transformers、tokenizers、PyMuPDF 等
5. **DeepSeek-OCR 模型** (~10GB) - 首次执行OCR时下载

**总计:** ~11GB（一次性）

### 🔧 系统要求

- macOS 10.15+
- 15GB 可用空间
- 网络连接（仅首次运行）
- Apple Silicon (M1/M2/M3) 或 Intel 芯片

### 📖 使用方法

```bash
# 1. 运行脚本
bash ocr_easy.sh

# 2. 输入图片路径（从访达拖拽或粘贴路径）
Path > /path/to/image.png

# 3. 选择识别模式（1-5）
Select mode [1-5, default 1]: 1

# 4. 等待完成，结果保存在 ocr_output/
```

### 📁 输出结构

```
ocr_output/
└── [图片名]/
    ├── result.md                # 识别结果
    ├── result_标准格式.md        # Markdown 格式
    └── result_with_boxes.jpg    # 带标注的图片
```

### 🛠️ 技术栈

- **核心**: DeepSeek-OCR 模型
- **框架**: PyTorch (CPU优化)
- **NLP**: Transformers 4.46.3, Tokenizers 0.20.3
- **图像**: Pillow, PyMuPDF, img2pdf
- **工具**: einops, easydict, numpy

### ❓ 常见问题

**Q: 首次运行需要多长时间？**
A: 环境安装 10-20分钟 + 首次OCR时模型下载 5-15分钟

**Q: 需要多少磁盘空间？**
A: 总计约 11GB（环境 ~1.1GB + 模型 ~10GB）

**Q: Intel Mac 可以使用吗？**
A: 可以！会自动安装兼容版本（Python 3.11 + PyTorch 2.2.2）

**Q: 安装后可以离线使用吗？**
A: 可以，环境和模型下载后即可离线使用

### 📄 开源协议

MIT License - 详见 [LICENSE](LICENSE)

### 🙏 致谢

- [DeepSeek-AI](https://github.com/deepseek-ai) - DeepSeek-OCR 模型
- [PyTorch](https://pytorch.org/) - 深度学习框架
- [Hugging Face](https://huggingface.co/) - 模型托管平台

---

<div align="center">

**Made with ❤️ for macOS users**
**专为 macOS 用户打造**

⭐ Star this repo if you find it helpful!
⭐ 如果觉得有用，请给个星标！

</div>
