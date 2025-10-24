# DeepSeek-OCR V2 | 傻瓜式操作

> 🚀 One-click OCR Tool | 一键使用的OCR图片识别工具
> 🌍 Bilingual Interface | 中英双语界面
> 🔧 Smart Chip Detection | 智能芯片适配 (Apple Silicon & Intel)

---

## Quick Start | 快速开始

**中文 Chinese:**
1. 打开终端 (Command + 空格 → 输入 terminal)
2. 拖 `ocr_easy.sh` 到终端，回车
3. **首次运行**: 自动安装环境（10-20分钟），请保持网络连接
4. 拖图片/文件夹到终端
5. 输入 `1` 选模式
6. 结果在 `ocr_output/` 文件夹

**English:**
1. Open Terminal (Command + Space → type terminal)
2. Drag `ocr_easy.sh` to Terminal, Enter
3. **First run**: Auto-install (10-20 min), keep network connected
4. Drag image/folder to Terminal
5. Type `1` to select mode
6. Results in `ocr_output/` folder

---

## Features | 特性

- ✅ **Smart chip detection** | 智能芯片检测 (M1/M2/M3 & Intel)
- ✅ **Auto-install** | 自动安装环境
- ✅ **Bilingual UI** | 中英双语界面
- ✅ **Batch processing** | 支持批量处理
- ✅ **5 OCR modes** | 5种识别模式
- ✅ **macOS optimized** | macOS优化

---

## Modes | 识别模式

1. **Document → Markdown** | 文档转Markdown
   Preserve format | 保留格式

2. **Standard OCR** | 普通OCR
   Extract text | 提取文字

3. **Layout-free** | 无布局OCR
   Plain text | 纯文本

4. **Chart parsing** | 图表解析
   For diagrams | 适合图表

5. **Description** | 详细描述
   Image caption | 图片说明

---

## Requirements | 系统要求

- macOS 10.15+
- 15GB space | 可用空间 (首次运行)
- Internet | 网络连接 (首次运行)
- Chip | 芯片: Apple Silicon (M1/M2/M3) or Intel

---

## Installation Details | 环境安装详解

### First Run Installation | 首次运行自动安装

**时长 Duration**: 10-20 分钟 (仅首次)

脚本会自动完成以下 5 个步骤:

#### [1/5] Checking Conda | 检查Conda环境管理器

**安装内容**: Miniforge3 (轻量级 Python 环境管理器)

```bash
# 自动检测芯片架构并下载对应版本
# Apple Silicon (M1/M2/M3):
curl -L -o Miniforge3-MacOSX-arm64.sh \
  https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh
bash Miniforge3-MacOSX-arm64.sh -b -p "$HOME/miniforge3"

# Intel x86_64:
curl -L -o Miniforge3-MacOSX-x86_64.sh \
  https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh
bash Miniforge3-MacOSX-x86_64.sh -b -p "$HOME/miniforge3"
```

- **大小**: ~100MB
- **位置**: `~/miniforge3/`
- **说明**: 用于隔离的 Python 环境,不影响系统 Python

---

#### [2/5] Creating Python env | 创建Python虚拟环境

**安装内容**: Python 环境 (根据芯片自动选择版本)

```bash
# 初始化 Conda
source "$HOME/miniforge3/etc/profile.d/conda.sh"

# Apple Silicon: Python 3.12.9
conda create -n deepseek-ocr python=3.12.9 -y

# Intel Mac: Python 3.11.11
conda create -n deepseek-ocr python=3.11.11 -y

# 激活环境
conda activate deepseek-ocr
```

- **大小**: ~200MB
- **环境名**: `deepseek-ocr`
- **说明**: 智能检测芯片架构,自动选择最佳 Python 版本
  - **Apple Silicon**: Python 3.12.9
  - **Intel Mac**: Python 3.11.11

---

#### [3/5] Installing PyTorch | 安装PyTorch深度学习框架

**安装内容**: PyTorch + TorchVision + TorchAudio (根据芯片自动选择版本)

```bash
# Apple Silicon: PyTorch 2.6.0 (最新版)
pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0

# Intel Mac: PyTorch 2.2.2 (Intel 最后官方支持版)
pip install torch==2.2.2 torchvision==0.17.2 torchaudio==2.2.2
```

- **大小**: ~500MB
- **说明**: CPU 优化版本,无需 GPU
- **版本说明**:
  - **Apple Silicon**: PyTorch 2.6.0 (最新版,完整功能支持)
  - **Intel Mac**: PyTorch 2.2.2 (Intel 最后官方支持版)
  - ℹ️ PyTorch 官方于 2024年1月后停止支持 Intel Mac x86_64

---

#### [4/5] Installing dependencies | 安装其他依赖包

**安装内容**: 所有必需的 Python 依赖包

```bash
# 安装 Hugging Face 相关库
pip install transformers==4.46.3   # Hugging Face 模型加载库
pip install tokenizers==0.20.3     # 文本分词器

# 安装文档处理库
pip install PyMuPDF                # PDF 处理
pip install img2pdf                # 图片转 PDF

# 安装工具库
pip install einops                 # 张量操作工具
pip install easydict               # 字典访问工具
pip install addict                 # 字典扩展工具

# 安装图像处理库
pip install Pillow                 # 图像处理
pip install numpy                  # 数值计算
```

或使用 requirements 文件一次性安装:

```bash
# 创建 requirements.txt
cat > requirements.txt << 'EOF'
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

# 批量安装
pip install -r requirements.txt
```

- **大小**: ~300MB
- **包说明**:
  - `transformers==4.46.3` - Hugging Face 模型加载库
  - `tokenizers==0.20.3` - 文本分词器
  - `PyMuPDF` - PDF 文件处理
  - `img2pdf` - 图片转 PDF 工具
  - `einops` - 张量操作简化库
  - `easydict`, `addict` - 字典访问工具
  - `Pillow` - Python 图像处理库
  - `numpy` - 数值计算基础库

---

#### [5/5] Finalizing | 完成设置

**创建工作目录**:

```bash
mkdir -p ocr_output
```

- **创建目录**: `ocr_output/` (结果保存位置)
- **总大小**: ~1.1GB (环境 + 依赖)

### Model Download | 模型下载

⚠️ **重要**: 模型在**首次执行 OCR 识别时**下载,不在环境安装阶段

- **下载时机**: 第一次处理图片时
- **模型名称**: DeepSeek-OCR (`deepseek-ai/DeepSeek-OCR`)
- **模型大小**: ~10GB
- **下载位置**: `~/.cache/huggingface/hub/`
- **下载时长**: 5-15分钟 (取决于网速)
- **说明**: 只下载一次,后续使用直接加载本地模型

### Total Space Required | 总空间需求

| 项目 | 大小 | 说明 |
|-----|------|------|
| Miniforge3 | ~100MB | Conda 环境管理器 |
| Python 环境 | ~200MB | 虚拟环境 |
| PyTorch | ~500MB | 深度学习框架 |
| 依赖包 | ~300MB | 其他库 |
| **环境小计** | **~1.1GB** | **首次安装** |
| DeepSeek-OCR 模型 | ~10GB | 首次 OCR 时下载 |
| **总计** | **~11GB** | **完整使用** |

---

## Chip Compatibility | 芯片兼容性

### Apple Silicon (M1/M2/M3)
- Python: 3.12.9
- PyTorch: 2.6.0 (最新版)
- 完整功能支持,性能最佳

### Intel x86_64
- Python: 3.11.11
- PyTorch: 2.2.2 (Intel 最后官方支持版)
- 完整功能支持
- ℹ️ PyTorch 官方于 2024年1月后停止支持 Intel Mac

---

## What's New in V2 | V2版本特性

- 🆕 **Smart chip detection** | 智能芯片检测与适配
- 🆕 **Bilingual interface** | 中英双语界面
- 🆕 **Fixed path bug** | 修复路径空格问题
- 🆕 **Detailed install info** | 详细安装步骤说明
- ✅ **One-click install** | 一键自动安装
- ✅ **Simplified files** | 极简文件结构
- ✅ **Smart batch** | 智能批量处理

---

## Troubleshooting | 常见问题

### Q: 首次运行需要多长时间?
**A**: 环境安装 10-20分钟 + 首次 OCR 时模型下载 5-15分钟

### Q: 需要多少磁盘空间?
**A**: 环境 ~1.1GB + 模型 ~10GB = 总计 ~11GB

### Q: Intel Mac 可以使用吗?
**A**: 可以! 脚本会自动检测并安装 Intel 兼容版本 (Python 3.11 + PyTorch 2.2.2)

### Q: 模型什么时候下载?
**A**: 首次执行 OCR 识别时自动下载,不在环境安装阶段

### Q: 后续使用还需要网络吗?
**A**: 不需要,环境和模型下载后可离线使用

---

## File Structure | 文件结构

```
傻瓜式操作V2/
├── ocr_easy.sh          # 主程序脚本
├── README.md            # 本说明文档
└── ocr_output/          # 输出目录 (自动创建)
    └── [图片名]/
        ├── result.md             # 识别结果
        ├── result_标准格式.md     # Markdown 格式结果
        └── result_with_boxes.jpg # 带标注的图片
```

---

**🎉 Easy to use | 简单易用**
**🚀 First run installs environment (10-20 min) | 首次运行自动安装环境（10-20分钟）**
**📦 Model downloads on first OCR (~10GB) | 首次识别时下载模型（约10GB）**
