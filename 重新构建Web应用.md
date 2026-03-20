# 重新构建 Flutter Web 应用步骤

## 当前状态
✓ 后端服务器已启动 (localhost:3000)
✓ 已构建的 web 应用正在提供服务
✓ 代码已修改（AuthManager 和其他改进）

## ⚠️ 需要做的

### 方案 1：使用现有的已构建版本 + 浏览器缓存清理（快速）
1. 打开浏览器开发工具 (F12)
2. 进入 Application → LocalStorage
3. 删除 localhost:3000 的所有数据
4. 刷新页面 (Ctrl+F5 或 Cmd+Shift+R)
5. 重新登录测试

**优点**：立即生效
**缺点**：前端代码改动还没有编译进去

---

### 方案 2：重新构建 Web 应用（推荐，但需要 Flutter SDK）
如果您已安装 Flutter SDK，请在项目根目录运行：

```bash
flutter clean
flutter pub get
flutter build web --release
```

然后重新启动后端：
```bash
cd backend
node index.js
```

**优点**：最新代码已编译
**缺点**：需要 Flutter SDK

---

## 检查 Flutter SDK 环境

### Windows 用户
在 PowerShell 中运行：
```powershell
flutter --version
```

如果出现 "flutter not found"，说明需要：
1. 下载 Flutter SDK: https://flutter.dev/docs/get-started/install/windows
2. 添加 Flutter 到系统 PATH
3. 运行 `flutter doctor` 验证环境

### macOS/Linux 用户
```bash
flutter --version
```

---

## 当前已修复的问题
✓ AuthManager.login() 和 logout() 现已正确通知监听器
✓ AppStateProvider 的积分缓存问题已解决
✓ TaskCenterPage 已改为并行加载（不再阻塞）

---

## 快速测试清单
- [ ] 清除浏览器 localStorage
- [ ] 刷新页面
- [ ] 重新登录
- [ ] 打开任务中心
- [ ] 检查积分是否为 0（而不是缓存的 120）
- [ ] 打开 DevTools 的 Network 标签，验证 /api/incentive/core 返回 integral: 0
