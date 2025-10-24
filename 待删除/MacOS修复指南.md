# 🔧 DeepSeek-OCR macOS 修复指南

## ❌ 遇到的问题

运行测试时出现错误：
```
AssertionError: Torch not compiled with CUDA enabled
```

**原因**：DeepSeek-OCR 官方代码硬编码了 CUDA（NVIDIA GPU），但 macOS 不支持 CUDA。
macOS 使用 **MPS (Metal Performance Shaders)** 或 **CPU**。

## ✅ 解决方案

### 方案 A：自动修复（推荐）

运行自动修复脚本：

```bash
cd "/Users/tieli/Library/Mobile Documents/com~apple~CloudDocs/Project/DeepSeek_OCR_for_MacOS"
python3 fix_mps_support.py
```

修复脚本会：
1. 自动找到缓存的模型文件
2. 备份原始文件
3. 替换所有 `.cuda()` 调用为 `.to(self.device)`
4. 添加设备自动检测（MPS > CUDA > CPU）

### 方案 B：手动修复

如果自动修复失败，手动修改文件：

1. **找到模型文件**：
```bash
~/.cache/huggingface/modules/transformers_modules/deepseek-ai/DeepSeek-OCR/[版本号]/modeling_deepseekocr.py
```

2. **需要修改的位置**：

在 `DeepseekOCRForCausalLM` 类中添加 `device` 属性：

```python
@property
def device(self):
    """获取模型设备（CPU/MPS/CUDA 兼容）"""
    return next(self.parameters()).device
```

3. **替换所有 `.cuda()` 调用**：

查找并替换：
- `input_ids.unsqueeze(0).cuda()` → `input_ids.unsqueeze(0).to(self.device)`
- `images_crop.cuda()` → `images_crop.to(self.device)`
- `images_ori.cuda()` → `images_ori.to(self.device)`
- `images_seq_mask.unsqueeze(0).cuda()` → `images_seq_mask.unsqueeze(0).to(self.device)`

## 🧪 修复后测试

运行测试：

```bash
cd "/Users/tieli/Library/Mobile Documents/com~apple~CloudDocs/Project/DeepSeek_OCR_for_MacOS"
bash test.sh
```

## 📊 性能说明

### MPS 模式（Apple Silicon）
- ✅ 推荐用于 M1/M2/M3 芯片
- ⚡ 比 CPU 快 3-5 倍
- 💾 内存占用：约 8-12GB

### CPU 模式
- ✅ 兼容所有 Mac
- ⏱️ 速度较慢（每张图 3-10 分钟）
- 💾 内存占用：约 8-10GB

## ⚠️ 常见问题

### 1. 修复后仍然报 CUDA 错误

**原因**：可能有多处缓存文件

**解决**：
```bash
# 清除所有缓存
rm -rf ~/.cache/huggingface/modules/transformers_modules/deepseek-ai/DeepSeek-OCR
# 重新运行测试（会重新下载模型）
bash test.sh
# 再次运行修复
python3 fix_mps_support.py
```

### 2. MPS 内存不足

**解决**：切换到 CPU 模式
```python
# 在 run_ocr_test.py 中修改 device 为 "cpu"
device = "cpu"  # 强制使用 CPU
```

### 3. 识别速度很慢

**正常现象**：
- 首次运行需要下载模型（~10GB）
- CPU 模式下每张图需要 3-10 分钟
- MPS 模式下每张图需要 1-3 分钟

### 4. 恢复原始文件

如果修复后出现问题，恢复备份：

```bash
cd ~/.cache/huggingface/modules/transformers_modules/deepseek-ai/DeepSeek-OCR/[版本号]/
cp modeling_deepseekocr.py.backup modeling_deepseekocr.py
```

## 📖 技术说明

### 为什么需要修复？

DeepSeek-OCR 是为 NVIDIA GPU (CUDA) 设计的，代码中硬编码了：
```python
tensor.cuda()  # 强制使用 CUDA
```

在 macOS 上应该使用：
```python
tensor.to(device)  # 设备无关，自动适配 MPS/CPU/CUDA
```

### 修复的影响

- ✅ 不影响模型功能
- ✅ 不改变识别准确度
- ✅ 自动兼容所有设备
- ⚠️ 如果模型更新，需要重新修复

## 🎯 快速测试流程

```bash
# 1. 运行修复
python3 fix_mps_support.py

# 2. 测试
bash test.sh

# 3. 查看结果
open ocr_output
```

## 📞 获取帮助

如果仍有问题：
1. 查看终端完整错误信息
2. 检查 Python 和 PyTorch 版本
3. 确认内存是否充足（至少 16GB 推荐）

---

💡 **提示**：这是 DeepSeek-OCR 官方代码的限制，不是部署问题。官方未来可能会更新以支持非 CUDA 设备。
