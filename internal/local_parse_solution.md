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

### [Date: 2026-01-15] Phase 2: Implementation of Logic | 第二阶段：逻辑实现
1.  **Fixing Gaps**: Addressed issues from "Status Check Feedback".
    **修复缺口:** 解决了“现状检查反馈”中的问题。
    - **NPM**: Created `scripts/postinstall.js` to warn if Python/`dsocr` is missing. Updated `bin/dsocr.js` to inherit environment variables (`HF_HOME` etc.).
    - **Dependencies**: Added `huggingface_hub` and `docx2pdf` (Darwin) to `pyproject.toml`.
2.  **Utils Module**: Implemented `src/deepseek_ocr_cli/utils.py`.
    **Utils 模块:** 实现了 `src/deepseek_ocr_cli/utils.py`。
    - `check_model_exists`: Looks in `HF_HOME` or default HF cache for existing model to avoid re-download.
    - `download_model`: Uses `snapshot_download` with resume support.
    - `patch_transformers`: Implements the runtime monkey-patch for `llava_next` (vision_feature_layer = -2) required by DeepSeek-OCR.
    - `download_file`: Handles URL downloads with progress bar.
3.  **Converters Module**: Implemented `src/deepseek_ocr_cli/converters.py`.
    **Converters 模块:** 实现了 `src/deepseek_ocr_cli/converters.py`。
    - `docx_to_pdf`: Tries `docx2pdf` (Word), then `pypandoc`, then `libreoffice`.
    - `pdf_to_images`: Uses `pymupdf` (fitz) to render pages at 200 DPI.
4.  **Core Logic**: Implemented `src/deepseek_ocr_cli/core.py`.
    **核心逻辑:** 实现了 `src/deepseek_ocr_cli/core.py`。
    - Loads model (auto-detects device MPS/CPU).
    - Processes pipeline: URL Download -> Convert to Images -> Batch Inference -> Markdown Assembly.
    - Output format: Single Markdown file with "## Page X" headers.
5.  **CLI Wiring**: Updated `src/deepseek_ocr_cli/cli.py`.
    **CLI 连接:** 更新了 `src/deepseek_ocr_cli/cli.py`。
    - Connected CLI arguments to `process_file`.
    - Added simple validation for input path vs URL.

## 最新可行性检查（阶段 2 代码）

- DOCX 转 PDF 回退链路未完整：`docx_to_pdf` 在 docx2pdf 失败后仅检查 pandoc 是否存在，却未调用 `pypandoc` 做实际转换，并直接尝试 LibreOffice；若无 Word/LibreOffice 而已安装 pandoc，仍会失败。需补上真实 pypandoc 转换或明确提示。  
- URL 下载失败时缺少兜底：`download_file` 失败返回 None，但 `process_file` 继续执行会导致后续错误，需在下载失败时中止并提示。  
- 自定义模型路径/离线模式未暴露：`check_model_exists` 仅读取 HF_HOME/默认缓存，CLI 未提供 `--model-cache`，也未支持 DSOCR_MODEL_DIR/DSOCR_OFFLINE 等环境变量，离线场景下仍会尝试联网下载。  
- 资源控制提示缺失：PDF 渲染与推理未提供页批次/DPI/并发参数，长 PDF 可能内存飙升（虽当前不强求性能优化，但应在文档中提示风险）。  
- 依赖说明需同步：代码新增 `huggingface_hub`、`docx2pdf`、`pypandoc`，但文档尚未强调系统前置（pandoc/Word/LibreOffice）及 HF token 需求，安装失败时用户可能不知原因。  
- Node 封装提示有限：postinstall 仅警告未安装 dsocr/Python，未提示 HF_HOME/模型缓存透传与 Python 版本检测结果；若未装 pipx 仅提示不会自动处理（符合“不删功能”，但需文档注明前置条件）。
