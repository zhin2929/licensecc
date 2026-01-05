cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

SET(LICENSECC_SHORT_LICENSE "BSD Software License")

# 设置 CMake 策略，使用新的 Boost 查找方式
if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()

# CMP0144: find_package 使用大写 <PACKAGENAME>_ROOT 变量
if(POLICY CMP0144)
  cmake_policy(SET CMP0144 NEW)
endif()

SET(CMAKE_DISABLE_SOURCE_CHANGES OFF) #keys are generated in the source tree by default
SET(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

# vcpkg 工具链支持
# 使用 CMakePresets.json 或通过命令行参数指定：
# cmake -DCMAKE_TOOLCHAIN_FILE=[vcpkg根目录]/scripts/buildsystems/vcpkg.cmake
IF(CMAKE_TOOLCHAIN_FILE)
  MESSAGE(STATUS "使用 vcpkg 工具链: ${CMAKE_TOOLCHAIN_FILE}")
ENDIF()

IF(NOT LCC_PROJECT_NAME)
	message(STATUS "You should define a variable LCC_PROJECT_NAME containing the name of the software you want to add a license to."
		"A mock project named DEFAULT has been added for you.")
	set(LCC_PROJECT_NAME "DEFAULT" CACHE STRING "Project name (name of the software for which you want to issue a license)") 
ENDIF(NOT LCC_PROJECT_NAME)

#base folder where projects are stored (/projects)
IF(NOT LCC_PROJECTS_BASE_DIR)
	set(LCC_PROJECTS_BASE_DIR "${CMAKE_SOURCE_DIR}/projects")
ENDIF(NOT LCC_PROJECTS_BASE_DIR)

# ===============================================================
# 静态链接配置 - 必须在 project() 之前设置
# ===============================================================
if(NOT DEFINED STATIC_RUNTIME)
  set(STATIC_RUNTIME ON CACHE BOOL "Use static runtime libraries (/MT) and static linking" FORCE)
  message(STATUS "STATIC_RUNTIME not defined, defaulting to ON (static linking)")
else()
  message(STATUS "STATIC_RUNTIME explicitly set to: ${STATIC_RUNTIME}")
endif()

# MSVC运行时库配置 - 必须在 project() 之前设置（CMake 3.15+）
# 注意：在 project() 之前，直接设置变量（MSVC 编译器会自动使用）
if(STATIC_RUNTIME)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>" CACHE STRING "MSVC runtime library" FORCE)
  message(STATUS "Configuring for static CRT: /MT (Release) and /MTd (Debug)")
else()
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL$<$<CONFIG:Debug>:Debug>" CACHE STRING "MSVC runtime library" FORCE)
  message(STATUS "Configuring for dynamic CRT: /MD (Release) and /MDd (Debug)")
endif()

cmake_policy(SET CMP0048 NEW)
cmake_policy(SET CMP0091 NEW)
project (licensecc 
			VERSION 2.1.0
			LANGUAGES CXX)
set(PROJECT_DESCRIPTION "Copy protection and licensing library")

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")

# 检查密钥是否存在（提前检查以决定是否需要 lccgen）
# 先设置路径，即使 LCC_PROJECT_NAME 未定义也能工作
if(NOT LCC_PROJECT_NAME)
  set(LCC_PROJECT_NAME "DEFAULT")
endif()
if(NOT LCC_PROJECTS_BASE_DIR)
  set(LCC_PROJECTS_BASE_DIR "${CMAKE_SOURCE_DIR}/projects")
endif()

set(LCC_TEMP_INCLUDE_DIR "${LCC_PROJECTS_BASE_DIR}/${LCC_PROJECT_NAME}/include/${PROJECT_NAME}/${LCC_PROJECT_NAME}")
set(LCC_TEMP_PUBLIC_KEY "${LCC_TEMP_INCLUDE_DIR}/public_key.h")

# 根据密钥存在性决定是否需要 lccgen
if(EXISTS "${LCC_TEMP_PUBLIC_KEY}")
  message(STATUS "检测到现有密钥，跳过 lccgen 查找")
  set(NEED_LCCGEN FALSE)
  # 创建虚拟 lccgen target
  if(NOT TARGET lccgen)
    add_executable(lccgen IMPORTED)
  endif()
else()
  message(STATUS "未检测到密钥，需要 lccgen")
  set(NEED_LCCGEN TRUE)

  # 判断是否为顶层项目（单独编译）
  if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    # 单独编译：始终查找 lccgen
    message(STATUS "单独编译模式：查找 lccgen")
    find_package(lccgen REQUIRED)
  else()
    # 作为子项目：只在非 Windows 或测试模式下查找
    if(BUILD_TESTING OR NOT WIN32)
      find_package(lccgen REQUIRED)
    else()
      message(STATUS "Windows 验证模式（子项目）：延迟 lccgen 检查")
      if(NOT TARGET lccgen)
        add_executable(lccgen IMPORTED)
      endif()
    endif()
  endif()
endif() 

#In case the build system doesn't support binfmt misc
IF( ( CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux" ) AND CMAKE_CROSSCOMPILING AND NOT DEFINED CMAKE_CROSSCOMPILING_EMULATOR )
	SET(CMAKE_CROSSCOMPILING_EMULATOR "wine")
ENDIF()

SET (OPENSSL_USE_STATIC_LIBS TRUE)
IF(${STATIC_RUNTIME})
	SET(OPENSSL_MSVC_STATIC_RT TRUE)
ENDIF(${STATIC_RUNTIME})

# Windows 使用原生 BCRYPT API，不查找 OpenSSL
if(WIN32)
	MESSAGE(STATUS "Windows 平台检测到，使用原生 BCRYPT API，跳过 OpenSSL 查找")
	set(OPENSSL_FOUND FALSE)
else()
	find_package(OpenSSL COMPONENTS Crypto QUIET)
	IF(OPENSSL_FOUND)
		MESSAGE(STATUS "Found openssl version ${OPENSSL_VERSION} -licensecc")
	ENDIF(OPENSSL_FOUND)
endif()

if(UNIX) #this is true for all the linux systems but not for cross compiling "linux->windows"
	IF(${STATIC_RUNTIME})
		set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++ -static")
	ENDIF(${STATIC_RUNTIME})
	IF(NOT OPENSSL_FOUND)
		MESSAGE(SEND_ERROR "Openssl required in Linux, please install it or specify -DOPENSSL_ROOT")
	ENDIF(NOT OPENSSL_FOUND)
	
    find_package(Threads)
	if(THREADS_HAVE_PTHREAD_ARG)
  		list(APPEND EXTERNAL_LIBS "-pthread")
	else(THREADS_HAVE_PTHREAD_ARG)
		if(CMAKE_THREAD_LIBS_INIT)
  			 list(APPEND EXTERNAL_LIBS "${CMAKE_THREAD_LIBS_INIT}")
		endif()
	endif(THREADS_HAVE_PTHREAD_ARG)

	#Zlib required with old openssl version < 1.0.1f in centos 7
	IF(OPENSSL_VERSION VERSION_LESS_EQUAL 1.0.2)
		SET ( ZLIB_USE_STATIC_LIBS ON ) 
		find_package(ZLIB REQUIRED)
		list(APPEND EXTERNAL_LIBS "${ZLIB_LIBRARIES}")
		MESSAGE(STATUS "Found zlib version ${ZLIB_VERSION_STRING} - licensecc")
	ELSE(OPENSSL_VERSION VERSION_LESS_EQUAL 1.0.2)
	    MESSAGE(STATUS "openssl ${OPENSSL_VERSION} zlib not required - licensecc")
	ENDIF(OPENSSL_VERSION VERSION_LESS_EQUAL 1.0.2)
	
	find_program( MEMORYCHECK_COMMAND valgrind )
	set( MEMORYCHECK_COMMAND_OPTIONS "--trace-children=yes --leak-check=full" )
	set(main_lib_dest "lib/${PROJECT_NAME}")
	#https://cmake.org/cmake/help/latest/command/find_package.html
	set(pkg_config_dest "lib/cmake/${PROJECT_NAME}")
else(UNIX)
	IF(NOT OPENSSL_FOUND)
		MESSAGE(STATUS "Openssl not found, configuring the library without it (running in wine not supported).")
	ENDIF(NOT OPENSSL_FOUND)
	if(MSVC)
		include(target_arch)
		target_architecture( TARGET_ARCHITECTURE )
		message(STATUS "architecture detected: ${TARGET_ARCHITECTURE}")

		# CRT已在顶层通过CMAKE_MSVC_RUNTIME_LIBRARY统一配置，这里只需设置Boost匹配
		if(STATIC_RUNTIME)
		  SET(Boost_USE_STATIC_RUNTIME ON)
		else()
		  SET(Boost_USE_STATIC_RUNTIME OFF)
		endif()

		add_definitions("/D _CRT_SECURE_NO_WARNINGS")
	    list(APPEND EXTERNAL_LIBS "bcrypt" "crypt32" "ws2_32" "iphlpapi")
	else(MSVC)
	    if(MINGW)        
            list(APPEND EXTERNAL_LIBS "-lbcrypt" "-lcrypt32" "-lws2_32" "-liphlpapi")
	        SET(CMAKE_EXE_LINKER_FLAGS "-static -static-libstdc++")
	    endif(MINGW)
	endif(MSVC)
	set(main_lib_dest "${PROJECT_NAME}")  
	#https://cmake.org/cmake/help/latest/command/find_package.html
	set(pkg_config_dest "cmake/${PROJECT_NAME}")
endif(UNIX)

#initialize project
#load the current project from files or find it from environment variables or create a default one

# 强制检查并修正 LCC_PROJECT_NAME（防止缓存问题）
# 如果父项目明确设置了 CACHE 变量，以父项目为准
get_property(LCC_NAME_FROM_CACHE CACHE LCC_PROJECT_NAME PROPERTY VALUE)
if(LCC_NAME_FROM_CACHE)
  set(LCC_PROJECT_NAME "${LCC_NAME_FROM_CACHE}")
  message(STATUS "使用父项目指定的 LCC_PROJECT_NAME: ${LCC_PROJECT_NAME}")
endif()

get_property(LCC_DIR_FROM_CACHE CACHE LCC_PROJECTS_BASE_DIR PROPERTY VALUE)
if(LCC_DIR_FROM_CACHE)
  set(LCC_PROJECTS_BASE_DIR "${LCC_DIR_FROM_CACHE}")
  message(STATUS "使用父项目指定的 LCC_PROJECTS_BASE_DIR: ${LCC_PROJECTS_BASE_DIR}")
endif()

# 调试输出：显示当前使用的项目配置
message(STATUS "========================================")
message(STATUS "licensecc 项目配置:")
message(STATUS "  LCC_PROJECT_NAME: ${LCC_PROJECT_NAME}")
message(STATUS "  LCC_PROJECTS_BASE_DIR: ${LCC_PROJECTS_BASE_DIR}")
message(STATUS "========================================")

set(LCC_INCLUDE_DIR "${LCC_PROJECTS_BASE_DIR}/${LCC_PROJECT_NAME}/include/${PROJECT_NAME}/${LCC_PROJECT_NAME}" )
set(LCC_PROJECT_PUBLIC_KEY "${LCC_INCLUDE_DIR}/public_key.h" )
set(LCC_PROJECT_PRIVATE_KEY "${LCC_PROJECTS_BASE_DIR}/${LCC_PROJECT_NAME}/private_key.rsa" )

# 检查密钥是否已存在
if(EXISTS "${LCC_PROJECT_PUBLIC_KEY}")
  # 密钥已存在：跳过 lccgen，不需要项目初始化
  message(STATUS "密钥已存在: ${LCC_PROJECT_PUBLIC_KEY}")
  message(STATUS "跳过 lccgen 和项目初始化")

  # 创建虚拟 target（避免依赖错误）
  add_custom_target(project_initialize
    COMMENT "密钥已存在，跳过项目初始化"
  )

  # 不需要查找 lccgen
  set(NEED_LCCGEN FALSE)

else()
  # 密钥不存在：需要 lccgen 生成
  message(STATUS "密钥不存在: ${LCC_PROJECT_PUBLIC_KEY}")

  # 判断是否为顶层项目（单独编译）还是子项目
  if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    # 单独编译 licensecc：始终尝试生成密钥
    message(STATUS "单独编译 licensecc，将生成密钥（需要 lccgen 和 Boost）")
    set(NEED_LCCGEN TRUE)

    # 创建项目初始化 target
    add_custom_target(project_initialize
      COMMAND license_generator::lccgen project initialize -t "${PROJECT_SOURCE_DIR}/src/templates" -n "${LCC_PROJECT_NAME}" -p "${LCC_PROJECTS_BASE_DIR}"
      COMMENT "generating ${LCC_PROJECT_PUBLIC_KEY} and ${LCC_PROJECT_PRIVATE_KEY}"
      USES_TERMINAL
    )
  else()
    # 作为子项目：根据平台和测试模式决定
    if(WIN32 AND NOT BUILD_TESTING)
      # Windows 验证模式但密钥不存在：提示错误
      message(FATAL_ERROR
        "Windows 验证模式需要现有密钥！\n"
        "  密钥路径: ${LCC_PROJECT_PUBLIC_KEY}\n"
        "  请先生成密钥：\n"
        "    方法1: 在 Linux/Mac 上编译 licensecc\n"
        "    方法2: 设置 -DBUILD_TESTING=ON 并安装 Boost\n"
        "    方法3: 手动运行 lccgen 生成密钥")
    else()
      # 需要 lccgen 生成密钥
      message(STATUS "需要 lccgen 生成密钥")
      set(NEED_LCCGEN TRUE)

      # 创建项目初始化 target
      add_custom_target(project_initialize
        COMMAND license_generator::lccgen project initialize -t "${PROJECT_SOURCE_DIR}/src/templates" -n "${LCC_PROJECT_NAME}" -p "${LCC_PROJECTS_BASE_DIR}"
        COMMENT "generating ${LCC_PROJECT_PUBLIC_KEY} and ${LCC_PROJECT_PRIVATE_KEY}"
        USES_TERMINAL
      )
    endif()
  endif()
endif()

include_directories( ${LCC_INCLUDE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/include" )

message( STATUS "CXX compiler        : " ${CMAKE_CXX_COMPILER})
message( STATUS "CXX compiler flags  : " ${CMAKE_CXX_FLAGS})
message( STATUS "CXX compiler flags debug : " ${CMAKE_CXX_FLAGS_DEBUG})
message( STATUS "CXX compiler flags release: " ${CMAKE_CXX_FLAGS_RELEASE})
if(CMAKE_BUILD_TYPE)
  message( STATUS "Build type          : " ${CMAKE_BUILD_TYPE})
endif(CMAKE_BUILD_TYPE)
message( STATUS "Install prefix      : " ${CMAKE_INSTALL_PREFIX})
message( STATUS "Project name        : " ${LCC_PROJECT_NAME} )
message( STATUS "Project base dir    : " ${LCC_PROJECTS_BASE_DIR}/${LCC_PROJECT_NAME} )

add_subdirectory(src)

#boost is required only for tests
#bug in cmake win32 - can't find boost compiled with mingw 
if(WIN32 AND "x${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}" STREQUAL "x")
    message(WARNING "WIN32 compiler does not specify CMAKE_CXX_COMPILER_ARCHITECTURE_ID -- filling in manually")
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(CMAKE_CXX_COMPILER_ARCHITECTURE_ID "x64")
    else()
        set(CMAKE_CXX_COMPILER_ARCHITECTURE_ID "x86")
    endif()
	    message(STATUS "Compiler architecture: ${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}")
endif()

# ===============================================================
# Boost 静态链接配置 - 根据 STATIC_RUNTIME 选项决定
# ===============================================================
if(STATIC_RUNTIME)
  SET( Boost_USE_STATIC_LIBS ON )
  message(STATUS "Using static Boost libraries (Boost_USE_STATIC_LIBS=ON)")

  if(MSVC)
    SET(Boost_USE_STATIC_RUNTIME ON)
    message(STATUS "Boost configured to match static CRT (/MT)")
  endif()
else()
  SET( Boost_USE_STATIC_LIBS OFF )
  message(STATUS "Using dynamic Boost libraries (Boost_USE_STATIC_LIBS=OFF)")

  if(MSVC)
    SET(Boost_USE_STATIC_RUNTIME OFF)
    message(STATUS "Boost configured to match dynamic CRT (/MD)")
  endif()
endif()

# ===============================================================
# vcpkg 路径推导 - 强制使用静态 triplet 的依赖库
# ===============================================================
# 只在需要 Boost 时配置（测试、非 Windows 或需要 lccgen）
if((BUILD_TESTING OR NOT WIN32 OR NEED_LCCGEN) AND MSVC AND STATIC_RUNTIME)
  message(STATUS "配置 vcpkg Boost 路径")
  if(CMAKE_TOOLCHAIN_FILE AND CMAKE_TOOLCHAIN_FILE MATCHES "vcpkg.cmake")
    get_filename_component(VCPKG_ROOT_TEMP "${CMAKE_TOOLCHAIN_FILE}" DIRECTORY)
    get_filename_component(VCPKG_ROOT_TEMP "${VCPKG_ROOT_TEMP}" DIRECTORY)
    get_filename_component(VCPKG_ROOT_TEMP "${VCPKG_ROOT_TEMP}" DIRECTORY)

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(VCPKG_TRIPLET_DIR "${VCPKG_ROOT_TEMP}/installed/x64-windows-static")
    else()
      set(VCPKG_TRIPLET_DIR "${VCPKG_ROOT_TEMP}/installed/x86-windows-static")
    endif()

    set(Boost_ROOT "${VCPKG_TRIPLET_DIR}")
    set(Boost_NO_SYSTEM_PATHS ON)
    set(OPENSSL_ROOT_DIR "${VCPKG_TRIPLET_DIR}")

    message(STATUS "Using static libraries from: ${VCPKG_TRIPLET_DIR}")
  elseif(DEFINED ENV{VCPKG_ROOT})
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(VCPKG_TRIPLET_DIR "$ENV{VCPKG_ROOT}/installed/x64-windows-static")
    else()
      set(VCPKG_TRIPLET_DIR "$ENV{VCPKG_ROOT}/installed/x86-windows-static")
    endif()

    set(Boost_ROOT "${VCPKG_TRIPLET_DIR}")
    set(Boost_NO_SYSTEM_PATHS ON)
    set(OPENSSL_ROOT_DIR "${VCPKG_TRIPLET_DIR}")

    message(STATUS "Using static libraries from VCPKG_ROOT env: ${VCPKG_TRIPLET_DIR}")
  endif()
else()
  if(WIN32 AND NOT BUILD_TESTING)
    message(STATUS "Windows 验证模式：跳过 vcpkg Boost 配置")
  endif()
endif()

# 根据是否需要 lccgen 决定是否查找 Boost
if(NEED_LCCGEN)
  # 密钥不存在，需要 lccgen 生成，必须查找 Boost
  message(STATUS "需要 lccgen 生成密钥，查找 Boost（lccgen 依赖）...")
  find_package(Boost COMPONENTS unit_test_framework system filesystem REQUIRED)

  # if boost is found enable tests
  IF(Boost_FOUND)
    INCLUDE(CTest)
    IF(BUILD_TESTING)
      SET(BUILDNAME "${BUILDNAME}" CACHE STRING "Name of build on the dashboard")
      MARK_AS_ADVANCED(BUILDNAME)
      add_subdirectory(test)
    ENDIF(BUILD_TESTING)
    add_subdirectory("src/inspector")
  ELSE(Boost_FOUND)
    message(FATAL_ERROR "Boost 未找到，但 lccgen 需要 Boost 才能生成密钥！\n"
                        "  请安装 Boost 或使用已有密钥。")
  ENDIF(Boost_FOUND)

elseif(WIN32 AND NOT BUILD_TESTING)
  # 密钥已存在，Windows 验证模式，跳过 Boost
  message(STATUS "Windows 验证库模式：跳过 Boost 查找（密钥已存在，仅验证功能）")
  set(Boost_FOUND FALSE)

else()
  # 其他情况（Linux、测试模式等）
  find_package(Boost COMPONENTS unit_test_framework system filesystem)
  # if boost is found enable tests
  IF(Boost_FOUND)
    INCLUDE(CTest)
    IF(BUILD_TESTING)
      SET(BUILDNAME "${BUILDNAME}" CACHE STRING "Name of build on the dashboard")
      MARK_AS_ADVANCED(BUILDNAME)
      add_subdirectory(test)
    ENDIF(BUILD_TESTING)
    add_subdirectory("src/inspector")
  ELSE(Boost_FOUND)
    message(WARNING "Boost not found, disabling tests")
  ENDIF(Boost_FOUND)
endif()

#################################
# Documentation
#################################
find_package(Doxygen COMPONENTS dot)
find_package(Sphinx)
 
IF(Doxygen_FOUND AND Sphinx_FOUND)
    message(STATUS "Doxygen found, generating docs.")
    SET(DOXYGEN_EXCLUDE_PATTERNS "*/library/ini/*;*/doc/resources/*")
    SET(DOXYGEN_DISABLE_INDEX YES)
    #SET(DOXYGEN_GENERATE_TREEVIEW YES)
    SET(DOXYGEN_GENERATE_XML YES)
    SET(DOXYGEN_LAYOUT_FILE "${CMAKE_CURRENT_SOURCE_DIR}/doc/DoxygenLayout.xml")
	doxygen_add_docs(docs doc src include/licensecc ${LCC_INCLUDE_DIR} COMMENT "doxygen docs")
	#file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/doc/resources/" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/html")
	
	#file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/doc/sphinx/" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
	set(SPHINX_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/doc)
	set(SPHINX_BUILD ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx)
 
	add_custom_target(documentation
                  COMMAND
                  ${SPHINX_EXECUTABLE} -b html
                  ${SPHINX_SOURCE} ${SPHINX_BUILD}
                  -Dbreathe_projects.licensecc=${CMAKE_CURRENT_BINARY_DIR}/xml
                  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                  COMMENT "Generating documentation with Sphinx")
    add_dependencies(documentation docs)
    
ELSE(Doxygen_FOUND AND Sphinx_FOUND)
	message(STATUS "Doxygen or Sphynx not found, not generating docs.")
ENDIF(Doxygen_FOUND AND Sphinx_FOUND)
install(DIRECTORY ${LCC_INCLUDE_DIR} DESTINATION include/${PROJECT_NAME})
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include/ DESTINATION include)
install(FILES src/cmake/licensecc-config.cmake DESTINATION ${pkg_config_dest})

include(CMakePackageConfigHelpers)
write_basic_package_version_file(${CMAKE_BINARY_DIR}/licensecc-config-version.cmake COMPATIBILITY SameMajorVersion)
install(FILES ${CMAKE_BINARY_DIR}/licensecc-config-version.cmake DESTINATION ${pkg_config_dest})


