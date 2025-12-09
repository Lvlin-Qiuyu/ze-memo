#!/bin/bash

echo "启动 Chrome 并禁用 CORS 安全策略（仅用于开发）"
echo ""

# 检测操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CHROME_CMD="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    CHROME_CMD="google-chrome"
else
    echo "不支持的操作系统: $OSTYPE"
    exit 1
fi

# 检查 Chrome 是否存在
if ! command -v "$CHROME_CMD" &> /dev/null && [[ ! -f "$CHROME_CMD" ]]; then
    echo "错误: 找不到 Chrome 浏览器"
    echo "请确保 Chrome 已安装"
    exit 1
fi

# 启动 Chrome 并禁用安全策略
"$CHROME_CMD" \
    --disable-web-security \
    --disable-features=VizDisplayCompositor \
    --allow-running-insecure-content \
    --user-data-dir="$TMPDIR/chrome_dev_session" \
    "http://localhost:8080" &

echo ""
echo "Chrome 已经启动，正在访问 http://localhost:8080"
echo "请确保 Flutter 应用已经在 8080 端口运行"
echo ""
echo "注意：此配置仅用于开发环境，不要用于生产环境！"