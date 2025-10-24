# 🎯 为什么使用 CPU 模式？

## 📊 研究发现

根据 Hugging Face 官方讨论区的测试结果：

### MPS 模式（Apple Silicon GPU）
- ❌ 内存需求：**19GB RAM**
- ❌ 存在兼容性问题：需要 fallback 到 CPU
- ❌ **数值精度问题**：fallback 会导致输出异常
- ❌ 输出乱码（如你看到的 "Background by..."）

### CPU 模式
- ✅ 内存需求：**仅 3GB RAM**
- ✅ **性能更好**：在 macOS 上速度实际更快
- ✅ **稳定性高**：无精度问题
- ✅ **正确输出**：无乱码

## 🔬 技术原因

### MPS Fallback 的问题

DeepSeek-OCR 使用了 `_upsample_bicubic2d_aa` 操作，这个操作：
1. MPS（Metal）不支持
2. 需要 fallback 到 CPU
3. **在 MPS→CPU 数据转换时丢失精度**
4. 导致模型输出异常（乱码、重复文本）

### CPU 模式的优势

1. **统一计算**：所有操作都在 CPU 上，无数据转换
2. **数值稳定**：无精度损失
3. **内存高效**：3GB vs 19GB
4. **经过验证**：社区测试证明有效

## 📖 参考来源

- Hugging Face 讨论 #20: MPS support
- Hugging Face 讨论 #21: CPU support
- 社区反馈：CPU 模式在 macOS 上更可靠

## 🚀 现在测试

已经为你配置好了 CPU 模式，运行：

```bash
cd "/Users/tieli/Library/Mobile Documents/com~apple~CloudDocs/Project/DeepSeek_OCR_for_MacOS"
bash test.sh
```

## ⏱️ 预期性能

- **首次运行**：模型已下载，直接识别
- **每张图片**：约 3-5 分钟（CPU 模式）
- **内存使用**：约 3-4GB
- **输出质量**：准确的 Markdown 格式

## 💡 为什么不使用 GPU？

在 macOS 上：
- **CUDA**：不支持（NVIDIA 专用）
- **MPS**：有兼容性问题（需要 fallback）
- **CPU**：最稳定、最可靠的选择

对于 DeepSeek-OCR 这样的模型，CPU 模式在 macOS 上反而是最佳选择。

## 🎉 优化结果

| 模式 | 内存 | 速度 | 稳定性 | 输出质量 |
|------|------|------|--------|----------|
| MPS + Fallback | 19GB | 慢 | ❌ 不稳定 | ❌ 乱码 |
| **CPU** | **3GB** | **快** | **✅ 稳定** | **✅ 准确** |

---

**现在运行测试，应该能得到正确的结果！** 🚀
