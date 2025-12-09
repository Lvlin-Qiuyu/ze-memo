@echo off
echo 启动 Chrome 并禁用 CORS 安全策略（仅用于开发）
echo.

:: 获取当前目录
set APP_DIR=%~dp0

:: 启动 Chrome 并禁用安全策略
start chrome.exe ^
    --disable-web-security ^
    --disable-features=VizDisplayCompositor ^
    --allow-running-insecure-content ^
    --user-data-dir="%TEMP%\chrome_dev_session" ^
    "http://localhost:8080"

echo.
echo Chrome 已经启动，正在访问 http://localhost:8080
echo 请确保 Flutter 应用已经在 8080 端口运行
echo.
echo 注意：此配置仅用于开发环境，不要用于生产环境！
pause