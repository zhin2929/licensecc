# 应用 license-generator 兼容性补丁
# 修复 Boost 1.76+ 和 C++17 兼容性问题

Write-Host "====================================" -ForegroundColor Cyan
Write-Host "应用 license-generator 补丁" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = $PSScriptRoot
$generatorDir = Join-Path $scriptDir "extern\license-generator"

if (-not (Test-Path $generatorDir)) {
  Write-Host "错误: license-generator 子模块不存在" -ForegroundColor Red
  Write-Host "请先运行: git submodule update --init --recursive" -ForegroundColor Yellow
  exit 1
}

Write-Host "应用兼容性补丁..." -ForegroundColor Yellow
Write-Host ""

# 修复 1: project.cpp - normalize() -> lexically_normal()
$file1 = Join-Path $generatorDir "src\license_generator\project.cpp"
if (Test-Path $file1) {
  $content1 = Get-Content $file1 -Raw
  if ($content1 -match "\.normalize\(\)") {
    $content1 = $content1 -replace "\.normalize\(\)", ".lexically_normal()"
    Set-Content $file1 -Value $content1 -NoNewline
    Write-Host "✅ 修复 project.cpp: normalize() -> lexically_normal()" -ForegroundColor Green
  } else {
    Write-Host "⏭️  project.cpp 已修复或不需要修复" -ForegroundColor Gray
  }
}

# 修复 2: SimpleIni.h - 移除 std::binary_function
$file2 = Join-Path $generatorDir "src\ini\SimpleIni.h"
if (Test-Path $file2) {
  $content2 = Get-Content $file2 -Raw
  if ($content2 -match "std::binary_function") {
    # 修复 KeyOrder
    $content2 = $content2 -replace "struct KeyOrder : std::binary_function<Entry, Entry, bool> \{", "struct KeyOrder {"
    # 修复 LoadOrder
    $content2 = $content2 -replace "struct LoadOrder : std::binary_function<Entry, Entry, bool> \{", "struct LoadOrder {"
    Set-Content $file2 -Value $content2 -NoNewline
    Write-Host "✅ 修复 SimpleIni.h: 移除 std::binary_function" -ForegroundColor Green
  } else {
    Write-Host "⏭️  SimpleIni.h 已修复或不需要修复" -ForegroundColor Gray
  }
}

# 修复 3: CMakeLists.txt - 使用动态 Boost
$file3 = Join-Path $generatorDir "CMakeLists.txt"
if (Test-Path $file3) {
  $content3 = Get-Content $file3 -Raw
  if ($content3 -match "SET\( Boost_USE_STATIC_LIBS ON \)") {
    $content3 = $content3 -replace "SET\( Boost_USE_STATIC_LIBS ON \)", "SET( Boost_USE_STATIC_LIBS OFF )"

    # 添加 BOOST_TEST_DYN_LINK 宏
    $pattern = "(SET\( Boost_USE_STATIC_LIBS OFF \)`nfind_package\(Boost REQUIRED COMPONENTS date_time filesystem program_options system unit_test_framework\))"
    $replacement = @"
SET( Boost_USE_STATIC_LIBS OFF )
find_package(Boost REQUIRED COMPONENTS date_time filesystem program_options system unit_test_framework)

# 使用动态链接 Boost 时需要定义此宏
if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS `$<`$<CONFIG:Debug>:BOOST_TEST_DYN_LINK>)
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS `$<`$<CONFIG:Release>:BOOST_TEST_DYN_LINK>)
"@

    if ($content3 -match "BOOST_TEST_DYN_LINK") {
      # 已经添加过了
      $content3 = $content3 -replace "SET\( Boost_USE_STATIC_LIBS ON \)", "SET( Boost_USE_STATIC_LIBS OFF )"
    } else {
      $content3 = $content3 -replace $pattern, $replacement
    }

    Set-Content $file3 -Value $content3 -NoNewline
    Write-Host "✅ 修复 CMakeLists.txt: 使用动态 Boost 库" -ForegroundColor Green
  } else {
    Write-Host "⏭️  CMakeLists.txt 已修复或不需要修复" -ForegroundColor Gray
  }
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "补丁应用完成!" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "修复的问题:" -ForegroundColor Green
Write-Host "  ✅ Boost 1.76+ 兼容性 (normalize -> lexically_normal)" -ForegroundColor White
Write-Host "  ✅ C++17 兼容性 (移除 std::binary_function)" -ForegroundColor White
Write-Host "  ✅ 动态 Boost 库支持" -ForegroundColor White
Write-Host ""
Write-Host "现在可以正常构建项目了!" -ForegroundColor Green
Write-Host ""
