# DeepSeek-OCR 测试指南

## 测试步骤

你已经上传了一张关于 Git 协作流程的图片。要进行 OCR 测试，请按以下步骤操作：

### 方式一：手动保存图片（推荐）

1. 从对话中右键保存图片到本地
2. 将图片保存到以下目录：
   ```
   /Users/tieli/Library/Mobile Documents/com~apple~CloudDocs/Project/DeepSeek_OCR_for_MacOS/test_images/
   ```
3. 建议命名为：`git_workflow.png` 或 `git_workflow.jpg`

### 方式二：使用截图

如果图片无法直接保存，可以：
1. 在对话中打开图片
2. 使用 macOS 截图工具 (Cmd+Shift+4)
3. 将截图保存到 test_images 目录

### 运行 OCR 测试

保存图片后，执行以下命令：

```bash
# 1. 激活 Conda 环境
conda activate deepseek-ocr

# 2. 进入项目目录
cd "/Users/tieli/Library/Mobile Documents/com~apple~CloudDocs/Project/DeepSeek_OCR_for_MacOS"

# 3. 运行 OCR 测试脚本
python run_ocr_test.py
```

### 预期结果

脚本会：
1. 自动检测 test_images 目录中的所有图片
2. 使用 DeepSeek-OCR 进行文档识别
3. 将识别结果转换为 Markdown 格式
4. 保存到 ocr_output 目录

### 输出示例

```
ocr_output/
  └── git_workflow/
      ├── git_workflow_result.md  # Markdown 识别结果
      └── [其他输出文件]
```

## 图片内容预览

你上传的图片包含以下内容（从我的视觉分析）：

### 主要内容：
- **标题**: Git 协作流程图
- **步骤 5**: 创建 Pull Request / Merge Request
  - 在 GitHub/GitLab 上创建 PR/MR，请求将功能分支合并到主分支
- **步骤 6**: 代码审查与合并
  - 团队成员审查代码，通过后合并到主分支

### 情景二：日常同步流程（推荐）
流程图展示了完整的 Git 工作流：
1. 早上开始工作 → `git pull`
2. 开发功能 → 修改代码
3. 提交更改 → `git add & commit`
4. 下班前 → 确保已推送
5. 再次拉取 → `git pull`
6. 推送到远程 → `git push`

## 注意事项

- 首次运行会下载 DeepSeek-OCR 模型（约 10GB）
- 建议使用清晰的图片以获得更好的识别效果
- 支持中英文混合文档识别
- 识别时间取决于图片大小和复杂度

## 故障排除

如果遇到问题：
1. 确认已激活 deepseek-ocr 环境
2. 检查图片是否已保存到 test_images 目录
3. 确认图片格式正确（jpg/png/bmp/webp）
4. 查看终端输出的错误信息

