# licensecc 依赖安装脚本（修复版）
# 使用 vcpkg 安装所需的依赖库
# 修复：正确处理 VCPKG_ROOT 环境变量优先级

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "安装 licensecc 依赖库" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# ========================================
# 检测 vcpkg（优先级修复版本）
# ========================================
$VCPKG_EXE = $null

Write-Host "正在查找 vcpkg..." -ForegroundColor Yellow

# 优先级 1: 检查系统级环境变量（您设置的全局变量）
$systemVcpkgRoot = [System.Environment]::GetEnvironmentVariable("VCPKG_ROOT", "Machine")
if ($systemVcpkgRoot) {
  $vcpkgPath = Join-Path $systemVcpkgRoot "vcpkg.exe"
  if (Test-Path $vcpkgPath) {
    $VCPKG_EXE = $vcpkgPath
    Write-Host "✓ 找到 vcpkg (系统环境变量): $VCPKG_EXE" -ForegroundColor Green
  } else {
    Write-Host "✗ 系统环境变量 VCPKG_ROOT 设置为: $systemVcpkgRoot" -ForegroundColor Yellow
    Write-Host "  但 vcpkg.exe 不存在于该路径" -ForegroundColor Yellow
  }
}

# 优先级 2: 检查用户级环境变量
if (-not $VCPKG_EXE) {
  $userVcpkgRoot = [System.Environment]::GetEnvironmentVariable("VCPKG_ROOT", "User")
  if ($userVcpkgRoot) {
    $vcpkgPath = Join-Path $userVcpkgRoot "vcpkg.exe"
    if (Test-Path $vcpkgPath) {
      $VCPKG_EXE = $vcpkgPath
      Write-Host "✓ 找到 vcpkg (用户环境变量): $VCPKG_EXE" -ForegroundColor Green
    } else {
      Write-Host "✗ 用户环境变量 VCPKG_ROOT 设置为: $userVcpkgRoot" -ForegroundColor Yellow
      Write-Host "  但 vcpkg.exe 不存在于该路径" -ForegroundColor Yellow
    }
  }
}

# 优先级 3: 检查进程级环境变量（可能被 VS 覆盖）
if (-not $VCPKG_EXE) {
  if ($env:VCPKG_ROOT) {
    $vcpkgPath = Join-Path $env:VCPKG_ROOT "vcpkg.exe"
    if (Test-Path $vcpkgPath) {
      # 警告：这可能是 VS 自带的 vcpkg
      if ($env:VSINSTALLDIR) {
        Write-Host "⚠ 找到 vcpkg (VS 开发者环境): $VCPKG_EXE" -ForegroundColor Yellow
        Write-Host "  注意: 这是 Visual Studio 自带的 vcpkg，可能不是您想要的版本" -ForegroundColor Yellow
      } else {
        Write-Host "✓ 找到 vcpkg (进程环境变量): $VCPKG_EXE" -ForegroundColor Green
      }
      $VCPKG_EXE = $vcpkgPath
    }
  }
}

# 优先级 4: 搜索常见路径
if (-not $VCPKG_EXE) {
  Write-Host "在常见路径中搜索..." -ForegroundColor Yellow
  $commonPaths = @(
    "E:\vcpkg\vcpkg.exe",
    "D:\vcpkg\vcpkg.exe",
    "C:\vcpkg\vcpkg.exe",
    "C:\src\vcpkg\vcpkg.exe",
    "D:\tools\vcpkg\vcpkg.exe"
  )
  foreach ($path in $commonPaths) {
    if (Test-Path $path) {
      $VCPKG_EXE = $path
      Write-Host "✓ 找到 vcpkg (常见路径): $VCPKG_EXE" -ForegroundColor Green
      break
    }
  }
}

# 如果仍未找到，报错退出
if (-not $VCPKG_EXE) {
  Write-Host ""
  Write-Host "====================================" -ForegroundColor Red
  Write-Host "错误: 未找到 vcpkg.exe" -ForegroundColor Red
  Write-Host "====================================" -ForegroundColor Red
  Write-Host ""
  Write-Host "请执行以下步骤之一：" -ForegroundColor Yellow
  Write-Host "1. 设置系统环境变量 VCPKG_ROOT 为您的 vcpkg 安装目录" -ForegroundColor White
  Write-Host "   示例: setx VCPKG_ROOT ""D:\vcpkg"" /M" -ForegroundColor Gray
  Write-Host ""
  Write-Host "2. 或者从 https://github.com/microsoft/vcpkg 安装 vcpkg" -ForegroundColor White
  Write-Host ""
  Write-Host "3. 设置后重新启动 PowerShell" -ForegroundColor White
  Write-Host ""
  Read-Host "按任意键退出"
  exit 1
}

Write-Host ""

# 显示 vcpkg 版本信息
Write-Host "vcpkg 信息:" -ForegroundColor Cyan
$vcpkgVersion = & $VCPKG_EXE version 2>&1 | Select-Object -First 1
Write-Host "  路径: $VCPKG_EXE" -ForegroundColor White
Write-Host "  版本: $vcpkgVersion" -ForegroundColor White
Write-Host ""

# 定义需要安装的包
$packages = @(
  # OpenSSL（主项目和子项目都需要）
  "openssl:x64-windows",
  "openssl:x86-windows",
  "openssl:x64-windows-static",
  "openssl:x86-windows-static",

  # Boost（license-generator 子项目需要）
  # 动态版本（用于单独构建 licensecc）
  "boost-date-time:x64-windows",
  "boost-date-time:x86-windows",
  "boost-filesystem:x64-windows",
  "boost-filesystem:x86-windows",
  "boost-program-options:x64-windows",
  "boost-program-options:x86-windows",
  "boost-system:x64-windows",
  "boost-system:x86-windows",
  "boost-test:x64-windows",
  "boost-test:x86-windows",

  # 静态版本（用于作为子项目集成，避免 DLL 依赖问题）
  "boost-date-time:x64-windows-static",
  "boost-date-time:x86-windows-static",
  "boost-filesystem:x64-windows-static",
  "boost-filesystem:x86-windows-static",
  "boost-program-options:x64-windows-static",
  "boost-program-options:x86-windows-static",
  "boost-system:x64-windows-static",
  "boost-system:x86-windows-static",
  "boost-test:x64-windows-static",
  "boost-test:x86-windows-static"
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
