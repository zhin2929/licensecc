# licensecc 依赖安装脚本
# 使用 vcpkg 安装所需的依赖库

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "安装 licensecc 依赖库" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 检测 vcpkg
$VCPKG_EXE = $null

if ($env:VCPKG_ROOT) {
  $VCPKG_EXE = Join-Path $env:VCPKG_ROOT "vcpkg.exe"
  if (Test-Path $VCPKG_EXE) {
    Write-Host "找到 vcpkg: $VCPKG_EXE" -ForegroundColor Green
  } else {
    $VCPKG_EXE = $null
  }
}

if (-not $VCPKG_EXE) {
  $commonPaths = @("E:\vcpkg\vcpkg.exe", "C:\vcpkg\vcpkg.exe", "C:\src\vcpkg\vcpkg.exe", "D:\vcpkg\vcpkg.exe")
  foreach ($path in $commonPaths) {
    if (Test-Path $path) {
      $VCPKG_EXE = $path
      Write-Host "找到 vcpkg: $VCPKG_EXE" -ForegroundColor Green
      break
    }
  }
}

if (-not $VCPKG_EXE) {
  Write-Host "错误: 未找到 vcpkg.exe" -ForegroundColor Red
  Write-Host "请设置环境变量 VCPKG_ROOT 或安装 vcpkg" -ForegroundColor Yellow
  Read-Host "按任意键退出"
  exit 1
}

Write-Host ""

# 定义需要安装的包
$packages = @(
  # OpenSSL（主项目和子项目都需要）
  "openssl:x64-windows",
  "openssl:x86-windows",

  # Boost（license-generator 子项目需要）
  "boost-date-time:x64-windows",
  "boost-date-time:x86-windows",
  "boost-filesystem:x64-windows",
  "boost-filesystem:x86-windows",
  "boost-program-options:x64-windows",
  "boost-program-options:x86-windows",
  "boost-system:x64-windows",
  "boost-system:x86-windows",
  "boost-test:x64-windows",
  "boost-test:x86-windows"
)

Write-Host "将要安装以下包:" -ForegroundColor Yellow
foreach ($pkg in $packages) {
  Write-Host "  - $pkg" -ForegroundColor White
}
Write-Host ""

$confirm = Read-Host "是否继续安装？(Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
  Write-Host "已取消安装" -ForegroundColor Yellow
  exit 0
}

Write-Host ""
Write-Host "开始安装..." -ForegroundColor Green
Write-Host ""

$totalCount = $packages.Count
$currentCount = 0

foreach ($pkg in $packages) {
  $currentCount++
  Write-Host "[$currentCount/$totalCount] 正在安装 $pkg..." -ForegroundColor Yellow

  & $VCPKG_EXE install $pkg

  if ($LASTEXITCODE -ne 0) {
    Write-Host "警告: $pkg 安装失败（可能已安装）" -ForegroundColor Yellow
  } else {
    Write-Host "[$currentCount/$totalCount] $pkg 安装完成" -ForegroundColor Green
  }
  Write-Host ""
}

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "依赖安装完成!" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "现在可以运行 build-all-configs.ps1 进行编译" -ForegroundColor Green
Write-Host ""
Read-Host "按任意键退出"
