# Local DeepSeek OCR CLI Plan | 本地 DeepSeek OCR CLI 方案

This document outlines the plan to create a standalone, installable CLI tool for local document parsing (OCR) using the DeepSeek-OCR model, inspired by `mineru-cloud` but executing entirely locally on macOS.
本文档概述了创建独立的、可安装的 CLI 工具的计划，该工具使用 DeepSeek-OCR 模型进行本地文档解析（OCR），灵感来自 `mineru-cloud`，但完全在 macOS 本地运行。

## 1. Objectives | 目标

- **Core Function:** Parse local Images, PDFs, and DOCX files into Markdown using a single command.
  **核心功能:** 使用单个命令将本地图片、PDF 和 DOCX 文件解析为 Markdown。
- **Engine:** DeepSeek-OCR (running locally via PyTorch/Transformers).
  **引擎:** DeepSeek-OCR（通过 PyTorch/Transformers 本地运行）。
- **Installation:** Support fast installation via `pipx` (Python) and `npm` (Node.js wrapper).
  **安装:** 支持通过 `pipx` (Python) 和 `npm` (Node.js 封装器) 快速安装。
- **Platform:** macOS (Apple Silicon & Intel optimized).
  **平台:** macOS（针对 Apple Silicon 和 Intel 进行优化）。

## 2. Proposed Architecture | 建议架构

We will restructure the current shell-script-based project into a proper Python package.
我们将把当前基于 Shell 脚本的项目重构为一个标准的 Python 包。

### Directory Structure | 目录结构
```
.
├── internal/               # Internal documentation (this file) | 内部文档（本文件）
├── src/
│   └── deepseek_ocr_cli/   # Main Python package | 主 Python 包
│       ├── __init__.py
│       ├── cli.py          # Entry point (Click/Typer) | 入口点
│       ├── core.py         # Model loading and inference logic | 模型加载与推理逻辑
│       ├── converters.py   # PDF/DOCX to Image conversion handling | PDF/DOCX 转图片处理
│       └── utils.py
├── pyproject.toml          # Python build configuration | Python 构建配置
├── package.json            # NPM wrapper configuration | NPM 封装配置
├── README.md
└── .gitignore
```

## 3. Implementation Details | 实现细节

### A. Python Package (`src/deepseek_ocr_cli`)

- **CLI Framework:** Use `click` or `typer` for a robust command-line interface.
  **CLI 框架:** 使用 `click` 或 `typer` 构建健壮的命令行界面。
- **Command:** `dsocr <input_path> [OPTIONS]`
  **命令:** `dsocr <input_path> [选项]`
- **Options | 选项:**
    - `--mode`: Select OCR mode (Document, Standard, Chart, etc.). | 选择 OCR 模式（文档、标准、图表等）。
    - `--output`: Specify output directory. | 指定输出目录。
    - `--device`: Force CPU or MPS (Auto-detect by default). | 强制使用 CPU 或 MPS（默认自动检测）。

### B. File Processing Strategy | 文件处理策略

1.  **Network URLs (HTTP/HTTPS):**
    - specific support for downloading files from URLs before processing.
    - 特别支持在处理前从 URL 下载文件。
2.  **Images (PNG, JPG, WEBP):**
    - Direct input to DeepSeek-OCR model.
    - 直接输入到 DeepSeek-OCR 模型。
3.  **PDFs:**
    - Use `pymupdf` (fitz) to render each page as an image.
    - 使用 `pymupdf` (fitz) 将每一页渲染为图片。
    - Process each page-image through the OCR model.
    - 通过 OCR 模型处理每一页图片。
    - Concatenate results into a single Markdown file.
    - 将结果合并为单个 Markdown 文件。
4.  **DOCX:**
    - *Option 1 (Visual):* Convert DOCX to PDF (using macOS built-in tools or `pypandoc`), then process as PDF. This preserves layout analysis.
    - *方案 1 (视觉):* 将 DOCX 转换为 PDF（使用 macOS 内置工具或 `pypandoc`），然后作为 PDF 处理。这保留了布局分析。
    - *Option 2 (Content):* Use `python-docx` to extract text and `DeepSeek-OCR` for embedded images.
    - *方案 2 (内容):* 使用 `python-docx` 提取文本，并使用 `DeepSeek-OCR` 处理嵌入的图片。
    - *Recommendation:* Start with **Option 1** (Visual) to leverage the "Document to Markdown" capability of the model, ensuring complex layouts are preserved.
    - *推荐:* 从 **方案 1** (视觉) 开始，利用模型的“文档转 Markdown”能力，确保保留复杂的布局。

### C. Model Management | 模型管理

- The model (`deepseek-ai/DeepSeek-OCR`) is large (~10GB).
  模型 (`deepseek-ai/DeepSeek-OCR`) 很大（约 10GB）。
- **First Run:** The CLI will check for the model in `~/.cache/huggingface` or a custom directory.
  **首次运行:** CLI 将在 `~/.cache/huggingface` 或自定义目录中检查模型。
- **Download:** If missing, it uses `huggingface_hub` to download it with a progress bar.
  **下载:** 如果缺失，则使用 `huggingface_hub` 下载并显示进度条。

## 4. Installation Support | 安装支持

### Method 1: Python (Pipx) - Recommended | 方法 1: Python (Pipx) - 推荐
Users can install directly from GitHub using `pipx`. This creates an isolated environment, handling the complex dependencies (PyTorch) automatically.
用户可以使用 `pipx` 直接从 GitHub 安装。这将创建一个隔离的环境，自动处理复杂的依赖关系（PyTorch）。

```bash
pipx install git+https://github.com/ttieli/DeepSeek-OCR-macOS.git
# Usage
dsocr /path/to/image.png
dsocr https://example.com/document.pdf
```

### Method 2: NPM (Node.js Wrapper) | 方法 2: NPM (Node.js 封装器)
An NPM package will be created that wraps the `pipx` command or the Python script.
将创建一个 NPM 包来封装 `pipx` 命令或 Python 脚本。

- **`package.json`**:
    - `bin`: `{"dsocr": "./bin/dsocr.js"}`
    - `scripts`: `postinstall`: Check for Python/Pipx. | 检查 Python/Pipx。
- **Wrapper Logic:** The JS script will execute the Python module.
  **封装逻辑:** JS 脚本将执行 Python 模块。

## 5. Development Steps | 开发步骤

1.  **Initialize Python Project:** Create `pyproject.toml` with dependencies (`torch`, `transformers`, `pymupdf`, `click`, `rich`, `requests`).
    **初始化 Python 项目:** 创建包含依赖项 (`torch`, `transformers`, `pymupdf`, `click`, `rich`, `requests`) 的 `pyproject.toml`。
2.  **Migrate Logic:** Refactor the Python script embedded in `ocr_easy.sh` into `src/deepseek_ocr_cli/core.py`.
    **迁移逻辑:** 将嵌入在 `ocr_easy.sh` 中的 Python 脚本重构到 `src/deepseek_ocr_cli/core.py` 中。
3.  **Implement CLI:** Create the `dsocr` entry point.
    **实现 CLI:** 创建 `dsocr` 入口点。
4.  **Add PDF/DOCX/URL Support:** Implement the conversion and download logic.
    **添加 PDF/DOCX/URL 支持:** 实现转换和下载逻辑。
5.  **Create NPM Wrapper:** Add `package.json` and `bin/dsocr.js`.
    **创建 NPM 封装器:** 添加 `package.json` 和 `bin/dsocr.js`。
6.  **Test:** Verify installation on a fresh environment.
    **测试:** 在全新环境中验证安装。

## 6. Draft Configuration | 配置草稿

### `pyproject.toml` (Snippet | 片段)
```toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "deepseek-ocr-cli"
version = "1.0.0"
dependencies = [
    "torch",
    "transformers",
    "pymupdf",
    "click",
    "pillow",
    "einops",
    "easydict",
    "requests"
]
scripts = { "dsocr" = "deepseek_ocr_cli.cli:main" }
```

### `package.json` (Snippet | 片段)
```json
{
  "name": "deepseek-ocr-cli",
  "bin": {
    "dsocr": "./bin/dsocr.js"
  }
}
```

## 7. Technical Refinements & Specifications | 技术细化与规范

### A. Dependency Management Strategy | 依赖管理策略
- **Apple Silicon (M1/M2/M3):** Default `pip install torch` works (installs latest stable with MPS support).
  **Apple Silicon:** 默认安装即可（包含 MPS 支持）。
- **Intel Macs:** PyTorch 2.3+ stopped x86_64 macOS support. The package installation should detect arch or documentation must guide users to pin `torch==2.2.2`.
  **Intel Mac:** 需注意 PyTorch 版本兼容性（建议锁定 2.2.2）。
- **Solution:** Use a dynamic `setup.py` or post-install check to warn if incompatible torch version is detected on Intel.

### B. PDF Processing Optimization | PDF 处理优化
- **Rasterization DPI:** Render pages at **150-200 DPI**. Higher DPI improves OCR accuracy but slows down inference significantly. Default to 200.
  **光栅化 DPI:** 默认 150-200 DPI，平衡速度与精度。
- **Memory Management:** For large PDFs (>10 pages), process pages in batches (e.g., 5 pages at a time) to prevent RAM spikes, as the visual model is memory intensive.
  **内存管理:** 大文件采用分批处理（如每批 5 页），防止内存溢出。

### C. DOCX Conversion Logic | DOCX 转换逻辑
- **Primary Method:** `docx2pdf` (Requires Microsoft Word installed).
  **首选方法:** `docx2pdf` (依赖 MS Word)。
- **Fallback Method:** `libreoffice --headless --convert-to pdf` (Requires LibreOffice).
  **备选方法:** `libreoffice` 命令行转换。
- **Last Resort:** Warn user if neither is available and suggest installing them, or attempt `pypandoc` (text-only lossy fallback).
  **最终手段:** 提示用户安装必要软件。

### D. Environment Variables | 环境变量
- `DSOCR_HOME`: Custom config/cache directory (default: `~/.dsocr`).
- `DSOCR_MODEL_DIR`: Override model storage path.
- `DSOCR_OFFLINE`: `1` to disable auto-downloading models (fail if missing).

### E. Output Format Specs | 输出格式规范
- **Markdown Structure:**
  ```markdown
  # Filename.pdf

  ## Page 1
  [OCR Content]

  ## Page 2
  [OCR Content]
  ```
- **Assets:** If the OCR extracts separate images (charts), save them to `./<filename>_assets/`.

## 可行性检查（基于当前需求补充）

- 本地模型复用：已存在 `~/.cache/huggingface/hub/models--deepseek-ai--DeepSeek-OCR`（约 6.2G），方案需默认优先使用本地缓存（可通过 HF_HOME / DSOCR_MODEL_DIR / CLI 参数指定），仅在缺失时下载，避免重复拉取。建议启动时做完整性检查并在缺失时提示需 Hugging Face 认证。  
- 依赖补齐：当前依赖草稿未含 `pypandoc`，文档也未明确安装 `pandoc`（DOCX 视觉路径依赖）。需要在安装指引中写明前置 `pandoc`，并在 Python 依赖中加入 `pypandoc`（不移除现有依赖）。  
- 版本/补丁风险：现有 shell 流程对 transformers llava_next 有热补丁，方案未说明如何在打包后固化（例如锁定 transformers 版本或内置补丁）；否则可能运行时报 vision_feature_layer 相关错误。  
- 输出策略明确化：按照需求仅需按页顺序合并为单一 Markdown，无需页眉页脚去重或表格/公式修正。需要在实现时固定输出文件命名（如 `<input_stem>.md`）并按页顺序追加，避免分散多文件。  
- 安装可用性：pipx+torch 在干净 macOS 环境可能因缺失 Xcode CLT/代理导致 wheel 拉取失败；方案应在安装说明中给出前置条件提示或失败提示（保持功能不删减，仅增加提示）。

## 现状检查反馈（基于已完成进度）

- 目录/骨架：`src/deepseek_ocr_cli` 与 `bin/dsocr.js` 已创建，`pyproject.toml`/`package.json` 已落地。现有 Python 文件均为占位，尚未实现实际逻辑。  
- package.json 存在 `"postinstall": "node scripts/postinstall.js"`，但当前缺少 `scripts/postinstall.js` 文件，安装时会报错。需补齐脚本或移除引用（建议补齐并检查 pipx/Python/HF_HOME）。  
- CLI 入口：`cli.py` 未调用 `process_file`（调用被注释），URL 下载为 TODO；设备选择/输出目录/模式映射未完成。  
- 核心逻辑：`core.py` 仅占位，未加载模型、未分发到 image/pdf/docx 处理；未接入本地模型复用检测。  
- 转换工具：`converters.py` 未实现 DOCX->PDF（需 pandoc/pypandoc）与 PDF->image（pymupdf）；`utils.py` 的下载与模型检测未实现。  
- 依赖：`pyproject.toml` 已包含 `pypandoc`，但未在文档中声明 `pandoc` 系统依赖；torch 版本未按架构区分（Intel 需锁定 2.2.2）；缺少 transformers 补丁固化策略。  
- Node 封装：`bin/dsocr.js` 只检测 `dsocr` 是否存在，未透传 HF_HOME/模型路径，也未输出更详细错误上下文。  
- 文档对“默认复用本地模型、缺失才下载”的要求尚未在代码里落实（需要在核心逻辑中检测 `~/.cache/huggingface`/`HF_HOME`/自定义路径）。

## Implementation Log | 实施日志

### [Date: 2026-01-15] Phase 1: Structure & Skeletons | 第一阶段：结构与骨架
1.  **Backup**: Created git backup `Backup: Before implementing dsocr CLI`.
    **备份:** 创建了 git 备份 `Backup: Before implementing dsocr CLI`。
2.  **File Structure**: Created directory tree.
    **文件结构:** 创建了目录树。
    - `src/deepseek_ocr_cli/`
    - `bin/`
3.  **Python Configuration**: Created `pyproject.toml`.
    **Python 配置:** 创建了 `pyproject.toml`。
    - Added dependencies: `torch`, `transformers`, `pymupdf`, `click`, `rich`, `pillow`, `requests`, `pypandoc`, `einops`, `easydict`.
    - Defined entry point script: `dsocr = "deepseek_ocr_cli.cli:main"`.
4.  **NPM Wrapper**: Created `package.json` and `bin/dsocr.js`.
    **NPM 封装器:** 创建了 `package.json` 和 `bin/dsocr.js`。
    - `dsocr.js`: Checks for Python command presence and wraps execution.
5.  **Source Code Skeletons**:
    **源代码骨架:**
    - `cli.py`: Basic `click` command structure with arguments (`--url`, `--mode`, `--output`).
    - `core.py`: Placeholder for main processing logic (file type detection).
    - `converters.py`: Placeholder for PDF/DOCX conversion.
    - `utils.py`: Placeholder for downloads and model checks.
