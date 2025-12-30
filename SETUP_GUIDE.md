# licensecc 快速设置指南

## 🚀 首次使用（新克隆的仓库）

### 1. 克隆仓库
```powershell
git clone https://github.com/zhin2929/licensecc.git
cd licensecc
git submodule update --init --recursive
```

### 2. 应用子模块兼容性修复
```powershell
.\apply-submodule-fixes.ps1
```

### 3. 安装依赖（如果使用 vcpkg）
```powershell
.\install-dependencies.ps1
```

### 4. 构建项目
```powershell
# 使用 PowerShell 脚本
.\build-all-configs.ps1

# 或在 Visual Studio 中打开
# 文件 → 打开 → 文件夹 → 选择此目录
```

---

## ⚠️ 重要说明

### 为什么需要 apply-submodule-fixes.ps1？

**license-generator 子模块** 指向上游仓库，未 fork。为了编译通过，需要应用以下兼容性修复：

1. **Boost 1.76+ 兼容性**
   - `normalize()` → `lexically_normal()`

2. **C++17 兼容性**
   - 移除 `std::binary_function`

3. **动态库支持**
   - `Boost_USE_STATIC_LIBS OFF`

这些修改**仅在本地应用**，不会提交到仓库。

---

## 📋 修复的文件

子模块中修复的文件：
- `extern/license-generator/src/license_generator/project.cpp`
- `extern/license-generator/src/ini/SimpleIni.h`
- `extern/license-generator/CMakeLists.txt`

主项目中修复的文件：
- `src/library/ini/SimpleIni.h`
- `CMakeLists.txt`

---

## 🔧 如果构建失败

### 重新应用修复
```powershell
# 重置子模块
git submodule update --init --force

# 重新应用修复
.\apply-submodule-fixes.ps1

# 清理并重新构建
.\clean-cache.ps1
.\build-all-configs.ps1
```

---

## 📚 更多文档

- `BUILD_GUIDE.md` - 详细构建指南
- `QUICK_START.md` - 快速开始
- `BOOST_COMPATIBILITY.md` - Boost 兼容性说明
- `LCCGEN_GUIDE.md` - lccgen 工具说明

---

**最后更新**: 2024-12-30
