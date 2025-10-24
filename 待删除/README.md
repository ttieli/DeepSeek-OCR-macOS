# 🎯 DeepSeek-OCR for macOS

macOS 平台上的 DeepSeek-OCR 文档识别工具，支持交互式提示词选择。

## ✨ 特性

- ✅ **交互式模式选择**：5 种识别模式，无需修改代码
- ✅ **CPU 优化**：针对 macOS 优化，稳定高效（3GB 内存）
- ✅ **批量处理**：支持同时处理多张图片
- ✅ **多种输出**：Markdown、纯文本、图表解析
- ✅ **自动修复**：自动处理 CUDA 兼容性问题

## 🚀 快速开始

### 1. 安装依赖

```bash
# 运行部署脚本（首次运行）
bash deploy_deepseek_ocr.sh
```

### 2. 准备图片

```bash
# 将图片放入测试目录
cp your_image.png test_images/
```

### 3. 运行识别

```bash
bash test.sh
```

### 4. 选择模式

```
请选择 OCR 识别模式：

  1. 文档转 Markdown（推荐）⭐
  2. 普通 OCR
  3. 无布局 OCR
  4. 图表解析
  5. 详细描述

请输入选项（1-5）[默认: 1]:
```

### 5. 查看结果

```bash
open ocr_output/
```

## 📝 识别模式

| 模式 | 说明 | 适用场景 |
|-----|------|---------|
| 1️⃣ 文档转 Markdown | 保留格式和结构 | 文档、PPT、报告 ⭐ |
| 2️⃣ 普通 OCR | 提取所有文字 | 一般文字识别 |
| 3️⃣ 无布局 OCR | 纯文本提取 | 快速文字提取 |
| 4️⃣ 图表解析 | 解析图表内容 | 图表、流程图 |
| 5️⃣ 详细描述 | 图片详细描述 | 理解图片内容 |

## 📚 文档

- **[交互式使用指南](交互式使用指南.md)** - 详细的模式选择说明
- **[使用指南](使用指南.md)** - 完整的使用教程
- **[快速参考](快速参考.md)** - 速查表
- **[CPU 模式说明](CPU模式说明.md)** - 为什么使用 CPU

## 💡 使用示例

### 示例 1：识别文档

```bash
cp document.png test_images/
bash test.sh
# 选择: 1 (文档转 Markdown)
```

### 示例 2：识别图表

```bash
cp chart.png test_images/
bash test.sh
# 选择: 4 (图表解析)
```

### 示例 3：批量处理

```bash
cp *.png test_images/
bash test.sh
# 选择模式后，自动处理所有图片
```

## 🎛️ 高级配置

### 调整分辨率

编辑 `run_ocr_test.py` 第 186-187 行：

```python
# 快速模式
base_size=512, image_size=384

# 标准模式（推荐）
base_size=1024, image_size=640

# 高精度模式
base_size=1280, image_size=800
```

## 📊 性能

- **设备**：CPU 模式（macOS 优化）
- **内存**：约 3-4GB
- **速度**：每张图片 3-5 分钟
- **输出**：准确的 Markdown 格式

## ⚠️ 注意事项

- ✅ macOS 上使用 **CPU 模式**最稳定
- ✅ 首次运行需要下载模型（约 10GB）
- ✅ 建议使用清晰的高分辨率图片
- ✅ 支持 PNG、JPG、JPEG、BMP、WEBP

## 🔧 故障排除

### 问题：提示 CUDA 错误

**解决**：运行修复脚本
```bash
python3 fix_mps_support.py
bash test.sh
```

### 问题：识别结果不准确

**解决**：
1. 提高分辨率：使用 `base_size=1280`
2. 更换识别模式
3. 使用更清晰的图片

### 问题：速度太慢

**解决**：
- CPU 模式下 3-5 分钟/张是正常的
- 可以降低分辨率加快速度

## 📁 项目结构

```
DeepSeek_OCR_for_MacOS/
├── test_images/              # 输入图片目录
├── ocr_output/               # 输出结果目录
├── test.sh                   # 测试脚本 ⭐
├── run_ocr_test.py          # 主程序
├── fix_mps_support.py       # 修复工具
├── deploy_deepseek_ocr.sh   # 部署脚本
└── 文档/
    ├── 交互式使用指南.md      # 模式选择指南 ⭐
    ├── 使用指南.md           # 完整教程
    ├── 快速参考.md           # 速查表
    └── CPU模式说明.md        # 技术说明
```

## 🎉 开始使用

```bash
# 1. 准备图片
cp your_image.png test_images/

# 2. 运行测试
bash test.sh

# 3. 选择模式
# 输入: 1 ⏎

# 4. 查看结果
open ocr_output/
```

---

**享受 DeepSeek-OCR 带来的便利！** 🚀
