# licensecc 完整编译脚本 - 使用 CMakePresets.json
# 生成 x64/x86 的 Debug/Release 版本

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "licensecc 多配置编译脚本" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 设置当前目录
Set-Location $PSScriptRoot

Write-Host "使用 CMakePresets.json 配置..." -ForegroundColor Green
Write-Host ""

# ====================================
# 配置列表
# ====================================
$presets = @("x64-debug", "x64-release", "x86-debug", "x86-release")
$totalCount = $presets.Count

# ====================================
# 编译函数
# ====================================
function Build-Preset {
  param(
    [string]$PresetName,
    [string]$Step
  )

  Write-Host "$Step 正在配置 $PresetName..." -ForegroundColor Yellow
  cmake --preset $PresetName
  if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: $PresetName 配置失败" -ForegroundColor Red
    Read-Host "按任意键退出"
    exit 1
  }

  Write-Host "$Step 正在编译 $PresetName..." -ForegroundColor Yellow
  cmake --build --preset $PresetName
  if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: $PresetName 编译失败" -ForegroundColor Red
    Read-Host "按任意键退出"
    exit 1
  }

  Write-Host "$Step 正在安装 $PresetName..." -ForegroundColor Yellow
  cmake --install "build/$PresetName"
  if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: $PresetName 安装失败" -ForegroundColor Red
    Read-Host "按任意键退出"
    exit 1
  }

  Write-Host "$Step 运行测试 $PresetName..." -ForegroundColor Yellow
  ctest --preset $PresetName
  # 测试失败不中止脚本

  Write-Host "$Step $PresetName 完成!" -ForegroundColor Green
  Write-Host ""
}

# ====================================
# 编译所有配置
# ====================================
$currentCount = 0
foreach ($preset in $presets) {
  $currentCount++
  $step = "[$currentCount/$totalCount]"
  Build-Preset -PresetName $preset -Step $step
}

# ====================================
# 完成
# ====================================
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "所有配置编译完成!" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "生成的文件:" -ForegroundColor Green
Write-Host "  - build\x64-debug\    (x64 Debug 构建)" -ForegroundColor White
Write-Host "  - build\x64-release\  (x64 Release 构建)" -ForegroundColor White
Write-Host "  - build\x86-debug\    (x86 Debug 构建)" -ForegroundColor White
Write-Host "  - build\x86-release\  (x86 Release 构建)" -ForegroundColor White
Write-Host ""
Write-Host "库文件位置:" -ForegroundColor Green
Write-Host "  - install\x64-debug\    (x64 Debug)" -ForegroundColor White
Write-Host "  - install\x64-release\  (x64 Release)" -ForegroundColor White
Write-Host "  - install\x86-debug\    (x86 Debug)" -ForegroundColor White
Write-Host "  - install\x86-release\  (x86 Release)" -ForegroundColor White
Write-Host ""
Read-Host "按任意键退出"
