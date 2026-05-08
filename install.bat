@echo off
chcp 65001 >nul
echo ========================================
echo   datamap-sql Skill 安装脚本
echo ========================================
echo.

set "TARGET_DIR=%USERPROFILE%\.claude\commands"
set "SOURCE_FILE=%~dp0datamap-sql.md"
set "TARGET_FILE=%TARGET_DIR%\datamap-sql.md"

REM 检查目标目录
if not exist "%TARGET_DIR%" (
    echo [INFO] 创建目录: %TARGET_DIR%
    mkdir "%TARGET_DIR%"
)

REM 检查是否已存在旧版本
if exist "%TARGET_FILE%" (
    echo [WARN] 检测到旧版本，正在备份...
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
    set "BACKUP_NAME=datamap-sql.md.bak.%datetime:~0,14%"
    copy "%TARGET_FILE%" "%TARGET_DIR%\%BACKUP_NAME%" >nul
    echo [OK] 旧版本已备份为: %BACKUP_NAME%
)

REM 复制新版本
copy "%SOURCE_FILE%" "%TARGET_FILE%" >nul
if %errorlevel% equ 0 (
    echo [OK] 安装成功！
    echo.
    echo 文件位置: %TARGET_FILE%
    echo.
    echo 使用方式: 在 Claude Code 中输入 /datamap-sql "你的查数需求"
) else (
    echo [ERROR] 安装失败，请检查权限
)

echo.
pause
