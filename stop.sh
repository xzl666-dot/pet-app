#!/bin/bash

echo "=========================================="
echo "  停止萌宠养成系统"
echo "=========================================="
echo ""

# 查找并停止后端服务
BACKEND_PID=$(lsof -ti :3000)

if [ -n "$BACKEND_PID" ]; then
    echo "正在停止后端服务 (PID: $BACKEND_PID)..."
    kill $BACKEND_PID
    echo "✓ 后端服务已停止"
else
    echo "✓ 后端服务未运行"
fi

echo ""
echo "=========================================="
echo "  应用已停止"
echo "=========================================="
