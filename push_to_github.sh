#!/bin/bash

##############################################################################
# DeepSeek-OCR macOS - GitHub 仓库初始化和推送脚本
#
# 功能:
#   - 初始化 Git 仓库
#   - 创建 .gitignore 文件
#   - 添加所有文件并提交
#   - 在 GitHub 创建远程仓库
#   - 推送代码到 GitHub
#
# 使用方法:
#   bash push_to_github.sh
#
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 获取脚本所在目录(项目根目录)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo -e "${BOLD}${CYAN}    DeepSeek-OCR macOS - GitHub Repository Setup${NC}"
echo -e "${BOLD}${CYAN}============================================================${NC}"
echo ""

##############################################################################
# 检查 Git 和 GitHub CLI
##############################################################################
echo -e "${BOLD}[1/6] Checking tools | 检查工具${NC}"
echo ""

# 检查 Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git not found | Git 未安装${NC}"
    echo "   Please install: xcode-select --install"
    exit 1
fi
echo -e "${GREEN}✓ Git installed${NC}"

# 检查 GitHub CLI
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) not found | GitHub CLI 未安装${NC}"
    echo ""
    echo "Install GitHub CLI | 安装 GitHub CLI:"
    echo "  brew install gh"
    echo ""
    echo "Or create repo manually at: https://github.com/new"
    echo ""
    read -p "Continue without gh? (y/n) | 不使用 gh 继续? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    USE_GH=false
else
    echo -e "${GREEN}✓ GitHub CLI installed${NC}"

    # 检查 GitHub CLI 登录状态
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️  Not logged in to GitHub | 未登录 GitHub${NC}"
        echo ""
        echo "Login to GitHub | 登录 GitHub:"
        echo "  gh auth login"
        echo ""
        read -p "Login now? (y/n) | 现在登录? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh auth login
        else
            USE_GH=false
        fi
    else
        echo -e "${GREEN}✓ GitHub CLI logged in${NC}"
        USE_GH=true
    fi
fi

echo ""

##############################################################################
# 获取仓库信息
##############################################################################
echo -e "${BOLD}[2/6] Repository info | 仓库信息${NC}"
echo ""

# 获取仓库名称
DEFAULT_REPO_NAME="DeepSeek-OCR-macOS"
echo -e "${CYAN}Enter repository name | 输入仓库名称${NC}"
echo -n "Repository name [${DEFAULT_REPO_NAME}]: "
read -r REPO_NAME

if [ -z "$REPO_NAME" ]; then
    REPO_NAME="$DEFAULT_REPO_NAME"
fi

echo -e "${GREEN}✓ Repository: ${REPO_NAME}${NC}"
echo ""

# 获取仓库描述
DEFAULT_DESCRIPTION="🚀 One-click OCR tool for macOS with DeepSeek-OCR. Supports Apple Silicon & Intel. 傻瓜式 OCR 图片识别工具,支持 M1/M2/M3 和 Intel 芯片"
echo -e "${CYAN}Enter description | 输入仓库描述${NC}"
echo "Description [default]: "
echo "$DEFAULT_DESCRIPTION"
echo -n "Press Enter to use default or type custom: "
read -r REPO_DESCRIPTION

if [ -z "$REPO_DESCRIPTION" ]; then
    REPO_DESCRIPTION="$DEFAULT_DESCRIPTION"
fi

echo ""

# 公开或私有
echo -e "${CYAN}Repository visibility | 仓库可见性${NC}"
echo "  1. Public (公开)"
echo "  2. Private (私有)"
echo -n "Choose [1]: "
read -r VISIBILITY_CHOICE

if [ -z "$VISIBILITY_CHOICE" ]; then
    VISIBILITY_CHOICE=1
fi

if [ "$VISIBILITY_CHOICE" = "2" ]; then
    REPO_VISIBILITY="private"
else
    REPO_VISIBILITY="public"
fi

echo -e "${GREEN}✓ Visibility: ${REPO_VISIBILITY}${NC}"
echo ""

##############################################################################
# 创建 .gitignore
##############################################################################
echo -e "${BOLD}[3/6] Creating .gitignore | 创建 .gitignore${NC}"
echo ""

cat > .gitignore << 'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride
._*

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual Environments
venv/
ENV/
env/
.venv

# PyTorch
*.pth
*.pt
checkpoints/

# Hugging Face
.cache/
wandb/

# OCR Output
ocr_output/
test_images/
*.mmd

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Logs
*.log

# Temporary files
tmp/
temp/
*.tmp

# Claude
.claude/

# iCloud
*.icloud
EOF

echo -e "${GREEN}✓ .gitignore created${NC}"
echo ""

##############################################################################
# 初始化 Git 仓库
##############################################################################
echo -e "${BOLD}[4/6] Initializing Git | 初始化 Git 仓库${NC}"
echo ""

# 检查是否已经是 Git 仓库
if [ -d ".git" ]; then
    echo -e "${YELLOW}⚠️  Git repository already exists | Git 仓库已存在${NC}"
    echo ""
    read -p "Reinitialize? This will keep history. (y/n) | 重新初始化? 会保留历史. (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping git init..."
    fi
else
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}"
fi

echo ""

##############################################################################
# 添加文件并提交
##############################################################################
echo -e "${BOLD}[5/6] Committing files | 提交文件${NC}"
echo ""

# 添加所有文件
git add .

# 显示将要提交的文件
echo "Files to be committed | 将要提交的文件:"
git status --short

echo ""
echo -e "${CYAN}Creating initial commit...${NC}"

# 创建提交
git commit -m "$(cat <<'COMMIT_MSG'
🎉 Initial commit: DeepSeek-OCR macOS

Features | 特性:
- 🔧 Smart chip detection (Apple Silicon & Intel)
- 🚀 One-click installation
- 🌍 Bilingual interface (中英双语)
- 📦 5 OCR modes
- ✅ Batch processing support
- 📝 Markdown output

Technical Stack | 技术栈:
- Python 3.11/3.12 (chip-adaptive)
- PyTorch 2.2.2/2.6.0 (chip-adaptive)
- DeepSeek-OCR model
- Transformers 4.46.3

🤖 Generated with Claude Code
COMMIT_MSG
)"

echo -e "${GREEN}✓ Initial commit created${NC}"
echo ""

##############################################################################
# 创建 GitHub 仓库并推送
##############################################################################
echo -e "${BOLD}[6/6] Pushing to GitHub | 推送到 GitHub${NC}"
echo ""

if [ "$USE_GH" = true ]; then
    echo -e "${CYAN}Creating GitHub repository...${NC}"

    # 使用 GitHub CLI 创建仓库
    if [ "$REPO_VISIBILITY" = "private" ]; then
        gh repo create "$REPO_NAME" --description "$REPO_DESCRIPTION" --private --source=. --remote=origin --push
    else
        gh repo create "$REPO_NAME" --description "$REPO_DESCRIPTION" --public --source=. --remote=origin --push
    fi

    echo ""
    echo -e "${GREEN}✓ Repository created and pushed!${NC}"
    echo ""

    # 获取仓库 URL
    REPO_URL=$(gh repo view --json url -q .url)
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo -e "${BOLD}${GREEN}✅ Success! | 成功!${NC}"
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo ""
    echo -e "${BOLD}Repository URL | 仓库地址:${NC}"
    echo "  $REPO_URL"
    echo ""
    echo -e "${CYAN}Next steps | 后续步骤:${NC}"
    echo "  • View online: gh repo view --web"
    echo "  • Add topics: gh repo edit --add-topic ocr,deepseek,macos"
    echo "  • Edit README: Update with your custom info"
    echo ""

else
    echo -e "${YELLOW}Manual setup required | 需要手动设置${NC}"
    echo ""
    echo "1. Create repository on GitHub:"
    echo "   https://github.com/new"
    echo ""
    echo "2. Repository name: ${REPO_NAME}"
    echo "3. Description: ${REPO_DESCRIPTION}"
    echo "4. Visibility: ${REPO_VISIBILITY}"
    echo ""
    echo "5. Then run these commands:"
    echo ""
    echo "   git branch -M main"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/${REPO_NAME}.git"
    echo "   git push -u origin main"
    echo ""
fi

echo -e "${CYAN}============================================================${NC}"
echo ""
