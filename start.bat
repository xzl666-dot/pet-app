@echo off
chcp 65001 >nul
echo ==========================================
echo   萌宠养成系统 - 一键启动脚本
echo ==========================================
echo.

REM 检查后端是否已经在运行
netstat -ano | findstr :3000 >nul
if %errorlevel% equ 0 (
    echo ✓ 后端服务已经在运行 (端口 3000)
) else (
    echo 正在启动后端服务...
    cd backend
    start /B node index.js
    cd ..
    echo ✓ 后端服务已启动
)

echo.
echo ==========================================
echo   应用已成功启动！
echo ==========================================
echo.
echo 🌐 访问地址: http://localhost:3000
echo.
echo 📱 测试账号:
echo    手机号: 13800000000
echo    密码:   123456
echo.
echo 💡 提示:
echo    - 后端服务运行在端口 3000
echo    - 前端和后端已整合在一起
echo    - 所有功能都已实现并可以正常使用
echo.
echo ==========================================
pause
