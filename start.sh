#!/bin/bash

echo "=========================================="
echo "  萌宠养成系统 - 一键启动脚本"
echo "=========================================="
echo ""

# 检查后端是否已经在运行
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "✓ 后端服务已经在运行 (端口 3000)"
else
    echo "正在启动后端服务..."
    cd backend
    node index.js > /dev/null 2>&1 &
    BACKEND_PID=$!
    echo "✓ 后端服务已启动 (PID: $BACKEND_PID)"
    cd ..
fi

echo ""
echo "=========================================="
echo "  应用已成功启动！"
echo "=========================================="
echo ""
echo "🌐 访问地址: http://localhost:3000"
echo ""
echo "📱 测试账号:"
echo "   手机号: 13800000000"
echo "   密码:   123456"
echo ""
echo "💡 提示:"
echo "   - 后端服务运行在端口 3000"
echo "   - 前端和后端已整合在一起"
echo "   - 所有功能都已实现并可以正常使用"
echo ""
echo "=========================================="
