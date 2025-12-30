cd E:\trading\Include\Git\licensecc

# 处理子模块
cd extern\license-generator
git checkout -b boost-cpp17-fixes 2>$null
git add src/license_generator/project.cpp src/ini/SimpleIni.h CMakeLists.txt
git commit -m "修复 Boost 1.76+ 和 C++17 兼容性

- 修复 normalize() -> lexically_normal() (Boost 1.76+)
- 移除 std::binary_function 继承 (C++17)  
- 改为使用动态 Boost 库

🤖 Generated with Claude Code"
git push -u origin boost-cpp17-fixes

# 返回主项目
cd ..\..

# 创建分支
git checkout -b vcpkg-boost-fix

# 添加所有文件
git add -A

# 提交
git commit -m "添加 vcpkg 支持和完整兼容性修复

主要改动：
✅ 添加 CMakePresets.json 和 vcpkg 工具链集成
✅ 修复主项目的 Boost 1.76+ 和 C++17 兼容性
✅ 添加自动化构建脚本和完整文档
✅ 更新子模块指向 fork 版本

配置: MTEA, 动态运行时, Boost 1.90, MSVC 19.50
平台: x64/x86 × Debug/Release

🤖 Generated with Claude Code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# 推送
git push -u origin vcpkg-boost-fix

Write-Host ""
Write-Host "✅ 所有修改已成功推送！" -ForegroundColor Green
Write-Host ""
Write-Host "您的仓库:" -ForegroundColor Cyan
Write-Host "  主项目: https://github.com/zhin2929/licensecc/tree/vcpkg-boost-fix" -ForegroundColor White
Write-Host "  子模块: https://github.com/zhin2929/lcc-license-generator/tree/boost-cpp17-fixes" -ForegroundColor White