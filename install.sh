#!/bin/bash
# datamap-sql Skill 安装脚本 (Git Bash / macOS / Linux)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$HOME/.claude/commands"
SOURCE_FILE="$SCRIPT_DIR/datamap-sql.md"
TARGET_FILE="$TARGET_DIR/datamap-sql.md"

echo "========================================"
echo "  datamap-sql Skill 安装脚本"
echo "========================================"
echo ""

# 创建目标目录
if [ ! -d "$TARGET_DIR" ]; then
    echo "[INFO] 创建目录: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

# 检查旧版本并备份
if [ -f "$TARGET_FILE" ]; then
    BACKUP_NAME="datamap-sql.md.bak.$(date +%Y%m%d%H%M%S)"
    echo "[WARN] 检测到旧版本，正在备份..."
    cp "$TARGET_FILE" "$TARGET_DIR/$BACKUP_NAME"
    echo "[OK] 旧版本已备份为: $BACKUP_NAME"
fi

# 复制新版本
cp "$SOURCE_FILE" "$TARGET_FILE"
echo "[OK] 安装成功！"
echo ""
echo "文件位置: $TARGET_FILE"
echo ""
echo "使用方式: 在 Claude Code 中输入 /datamap-sql \"你的查数需求\""
