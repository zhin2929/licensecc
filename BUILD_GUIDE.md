# licensecc 项目构建指南

## 前提条件

1. **确保环境变量已设置**（在 PowerShell 中验证）：
```powershell
$env:VCPKG_ROOT
# 应该输出：E:\vcpkg
```

如果没有输出，请设置：
```powershell
# 临时设置（当前 PowerShell 会话）
$env:VCPKG_ROOT = "E:\vcpkg"

# 或永久设置（推荐）
[System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", "E:\vcpkg", "User")
# 设置后需要重启 PowerShell 和 Visual Studio
```

2. **确认 Boost 已安装**：
```powershell
dir E:\vcpkg\installed\x64-windows\include\boost
```

## 方法 1：使用 Visual Studio（推荐）

### 步骤：
1. **关闭所有 Visual Studio 窗口**

2. **重启 Visual Studio**（确保读取新的环境变量）

3. **打开项目**：
   - 文件 → 打开 → 文件夹
   - 选择：`E:\trading\Include\Git\licensecc`

4. **等待 CMake 配置完成**：
   - VS 会自动检测 `CMakePresets.json`
   - 在输出窗口查看 "CMake" 标签页
   - 应该看到 "CMake generation finished." 消息

5. **选择配置**：
   - 在工具栏的配置下拉框选择：`x64-debug`、`x64-release`、`x86-debug` 或 `x86-release`

6. **构建项目**：
   - 点击"生成" → "生成全部" (Ctrl+Shift+B)

7. **查看生成结果**：
   - 构建目录：`build\x64-debug\`
   - 安装目录：`install\x64-debug\`

## 方法 2：使用命令行（PowerShell）

### 清理并重新配置：
```powershell
cd E:\trading\Include\Git\licensecc

# 清理旧的构建
Remove-Item -Recurse -Force build, install -ErrorAction SilentlyContinue

# 配置 x64-Debug
cmake --preset x64-debug

# 编译
cmake --build build/x64-debug

# 安装
cmake --install build/x64-debug
```

### 或使用自动化脚本构建所有配置：
```powershell
cd E:\trading\Include\Git\licensecc
.\build-all-configs.ps1
```

## 方法 3：单独配置每个版本

```powershell
# x64-Debug
cmake --preset x64-debug
cmake --build build/x64-debug
cmake --install build/x64-debug

# x64-Release
cmake --preset x64-release
cmake --build build/x64-release
cmake --install build/x64-release

# x86-Debug
cmake --preset x86-debug
cmake --build build/x86-debug
cmake --install build/x86-debug

# x86-Release
cmake --preset x86-release
cmake --build build/x86-release
cmake --install build/x86-release
```

## 常见问题排查

### 问题 1：找不到 Boost
**症状**：CMake Error: Could NOT find Boost

**解决方案**：
1. 确认 VCPKG_ROOT 环境变量已设置并重启了 VS
2. 确认 Boost 已安装：
   ```powershell
   E:\vcpkg\vcpkg list boost
   ```
3. 清理 CMake 缓存：
   ```powershell
   Remove-Item -Recurse -Force build
   ```

### 问题 2：Visual Studio 不识别 CMakePresets.json
**解决方案**：
1. 确保 VS 版本 >= 2019 16.10
2. 关闭并重新打开文件夹
3. 删除 `.vs` 隐藏文件夹：
   ```powershell
   Remove-Item -Recurse -Force .vs
   ```

### 问题 3：环境变量不生效
**解决方案**：
1. 以管理员身份打开 PowerShell
2. 设置用户级环境变量：
   ```powershell
   [System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", "E:\vcpkg", "User")
   ```
3. **重启所有 PowerShell 窗口和 Visual Studio**

## 验证配置成功

### 检查 CMake 是否找到 Boost：
```powershell
# 查看 CMakeCache
Select-String -Path "build\x64-debug\CMakeCache.txt" -Pattern "Boost_FOUND|Boost_INCLUDE_DIR"
```

应该看到：
```
Boost_FOUND:BOOL=TRUE
Boost_INCLUDE_DIR:PATH=E:/vcpkg/installed/x64-windows/include
```

## 项目结构

配置成功后，目录结构如下：
```
licensecc/
├── build/
│   ├── x64-debug/      # x64 Debug 构建输出
│   ├── x64-release/    # x64 Release 构建输出
│   ├── x86-debug/      # x86 Debug 构建输出
│   └── x86-release/    # x86 Release 构建输出
├── install/
│   ├── x64-debug/      # x64 Debug 库文件和头文件
│   ├── x64-release/    # x64 Release 库文件和头文件
│   ├── x86-debug/      # x86 Debug 库文件和头文件
│   └── x86-release/    # x86 Release 库文件和头文件
├── CMakeLists.txt
├── CMakePresets.json   # CMake 配置预设
└── build-all-configs.ps1  # 自动化构建脚本
```

## 项目配置参数

当前 CMakePresets.json 配置的参数：
- `CMAKE_TOOLCHAIN_FILE`: 自动使用 $env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake
- `LCC_PROJECT_NAME`: "MTEA"
- `BUILD_TESTING`: OFF（不构建测试）
- `STATIC_RUNTIME`: OFF（使用动态运行时 /MD）

如需修改，请编辑 `CMakePresets.json` 文件。
