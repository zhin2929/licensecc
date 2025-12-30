# licensecc 清理缓存脚本
# 清理所有 Visual Studio 和 CMake 缓存

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "清理 licensecc 缓存" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 设置当前目录
Set-Location $PSScriptRoot

Write-Host "正在清理以下目录和文件..." -ForegroundColor Yellow
Write-Host "  - .vs/ (Visual Studio 缓存)" -ForegroundColor White
Write-Host "  - build/ (CMake 构建目录)" -ForegroundColor White
Write-Host "  - install/ (安装目录)" -ForegroundColor White
Write-Host "  - out/ (输出目录)" -ForegroundColor White
Write-Host "  - CMakeCache.txt" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "确认清理？(Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
  Write-Host "已取消清理" -ForegroundColor Yellow
  exit 0
}

Write-Host ""

# 清理 Visual Studio 缓存
if (Test-Path ".vs") {
  Write-Host "删除 .vs/ ..." -ForegroundColor Yellow
  Remove-Item -Recurse -Force .vs -ErrorAction SilentlyContinue
  Write-Host "  完成" -ForegroundColor Green
}

# 清理构建目录
if (Test-Path "build") {
  Write-Host "删除 build/ ..." -ForegroundColor Yellow
  Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
  Write-Host "  完成" -ForegroundColor Green
}

# 清理安装目录
if (Test-Path "install") {
  Write-Host "删除 install/ ..." -ForegroundColor Yellow
  Remove-Item -Recurse -Force install -ErrorAction SilentlyContinue
  Write-Host "  完成" -ForegroundColor Green
}

# 清理输出目录（如果存在）
if (Test-Path "out") {
  Write-Host "删除 out/ ..." -ForegroundColor Yellow
  Remove-Item -Recurse -Force out -ErrorAction SilentlyContinue
  Write-Host "  完成" -ForegroundColor Green
}

# 清理 CMakeCache
if (Test-Path "CMakeCache.txt") {
  Write-Host "删除 CMakeCache.txt ..." -ForegroundColor Yellow
  Remove-Item -Force CMakeCache.txt -ErrorAction SilentlyContinue
  Write-Host "  完成" -ForegroundColor Green
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "清理完成!" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "请按以下步骤操作:" -ForegroundColor Green
Write-Host "  1. 关闭所有 Visual Studio 窗口" -ForegroundColor White
Write-Host "  2. 重新打开 Visual Studio" -ForegroundColor White
Write-Host "  3. 打开此文件夹: E:\trading\Include\Git\licensecc" -ForegroundColor White
Write-Host "  4. 等待 CMake 自动配置完成" -ForegroundColor White
Write-Host ""
Read-Host "按任意键退出"
