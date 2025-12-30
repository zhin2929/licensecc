# lccgen (License Generator) 工具说明

## 📁 项目结构

```
extern/license-generator/
├── src/
│   ├── license_generator/
│   │   ├── open-license-main.cpp        ⭐ Main 函数入口
│   │   ├── command_line-parser.cpp      🔧 命令行解析
│   │   ├── command_line-parser.hpp
│   │   ├── license.cpp                  📄 许可证生成
│   │   ├── project.cpp                  📦 项目管理
│   │   └── CMakeLists.txt               🛠️ 构建配置
│   └── base_lib/
│       └── crypto_helper.cpp            🔐 加密助手
└── CMakeLists.txt
```

## 🎯 Main 函数入口

**文件**: `extern/license-generator/src/license_generator/open-license-main.cpp:4`

```cpp
int main(int argc, const char *argv[]) {
    return license::CommandLineParser::parseCommandLine(argc, argv);
}
```

**非常简洁！** 所有逻辑都委托给 `CommandLineParser`。

---

## 🔧 构建配置

**文件**: `extern/license-generator/src/license_generator/CMakeLists.txt:22-24`

```cmake
# 第 22 行：创建可执行文件
add_executable(lccgen open-license-main.cpp)

# 第 23 行：创建命名空间别名
add_executable(license_generator::lccgen ALIAS lccgen)

# 第 24 行：链接库
target_link_libraries(lccgen PRIVATE license_generator_lib)
```

**构建产物**: `lccgen.exe`（许可证生成工具）

---

## 📋 支持的命令

基于 `command_line-parser.cpp:207-275` 的代码分析：

### 1. 项目管理命令

#### `project init` - 初始化新项目
```bash
lccgen project init [选项]
```
**功能**:
- 创建新的许可证项目
- 生成 RSA 密钥对（公钥/私钥）
- 创建项目配置文件

**相关代码**: `initializeProject()` 函数

---

#### `project list` - 列出所有项目
```bash
lccgen project list [选项]
```
**功能**: 列出所有已配置的许可证项目

---

### 2. 许可证管理命令

#### `license issue` - 颁发许可证
```bash
lccgen license issue [选项]
```
**功能**:
- 为指定项目颁发许可证
- 使用私钥签名
- 生成许可证文件

**相关代码**: `issueLicense()` 函数

---

### 3. 测试命令

#### `test sign` - 测试签名
```bash
lccgen test sign [选项]
```
**功能**: 测试加密签名功能

**相关代码**: `test_sign()` 函数

---

## 🔑 在 licensecc 项目中的使用

### CMake 自动调用

主项目通过 CMake 在构建时自动调用 lccgen：

**文件**: `CMakeLists.txt:114-118`

```cmake
add_custom_target(project_initialize
  COMMAND license_generator::lccgen project initialize
          -t "${PROJECT_SOURCE_DIR}/src/templates"
          -n "${LCC_PROJECT_NAME}"
          -p "${LCC_PROJECTS_BASE_DIR}"
  COMMENT "generating ${LCC_PROJECT_PUBLIC_KEY} and ${LCC_PROJECT_PRIVATE_KEY} if they don't already exist"
  USES_TERMINAL
)
```

**执行时机**: 在主项目构建前自动运行

**生成的文件**:
```
projects/MTEA/
├── include/licensecc/MTEA/
│   └── public_key.h          # 公钥头文件（嵌入到库中）
└── private_key.rsa           # 私钥文件（用于颁发许可证）
```

---

## 🛠️ 构建流程

### 1. 子模块编译
```
CMake 配置 → 编译 license_generator_lib → 编译 lccgen.exe
```

### 2. 密钥生成
```
lccgen 运行 → 生成 RSA 密钥对 → 写入 public_key.h 和 private_key.rsa
```

### 3. 主项目编译
```
包含 public_key.h → 编译 licensecc 库 → 生成最终库文件
```

---

## 🔍 调试 lccgen

### 在 Visual Studio 中查看输出

构建时查看 CMake 输出窗口：
```
[CMake] -- generating projects/MTEA/include/licensecc/MTEA/public_key.h
[CMake] -- generating projects/MTEA/private_key.rsa
```

### 手动运行 lccgen

构建完成后，可以手动运行：
```powershell
# 进入构建目录
cd E:\trading\Include\Git\licensecc\build\x64-debug\extern\license-generator

# 查看帮助
.\lccgen.exe

# 初始化项目
.\lccgen.exe project init -n TestProject -p E:\trading\Include\Git\licensecc\projects
```

---

## 📊 依赖关系

```
lccgen.exe
├── license_generator_lib (静态库)
│   ├── command_line-parser.cpp
│   ├── license.cpp
│   ├── project.cpp
│   └── lcc_base (对象库)
├── Boost.ProgramOptions     # 命令行解析
├── Boost.Filesystem         # 文件系统操作
└── OpenSSL::Crypto          # RSA 加密（可选）
```

---

## 🎯 关键点总结

| 项目 | 说明 |
|------|------|
| **入口文件** | `open-license-main.cpp:4` |
| **可执行文件** | `lccgen.exe` |
| **主要功能** | 生成 RSA 密钥对、管理项目、颁发许可证 |
| **构建方式** | 作为子模块自动编译 |
| **当前项目名** | `MTEA`（在 CMakePresets.json 中配置） |
| **输出位置** | `build/x64-debug/extern/license-generator/` |

---

## 🔗 相关文件

- 主入口：`extern/license-generator/src/license_generator/open-license-main.cpp`
- 命令解析：`extern/license-generator/src/license_generator/command_line-parser.cpp`
- 项目管理：`extern/license-generator/src/license_generator/project.cpp`
- 许可证生成：`extern/license-generator/src/license_generator/license.cpp`
- 构建配置：`extern/license-generator/src/license_generator/CMakeLists.txt`

---

**创建日期**: 2024-12-30
