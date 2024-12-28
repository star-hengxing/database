---
title: "MySQL 编译（打包）"
date: 2024-08-29
lastmod: 2023-01-21
draft: false
tags:
    - C/C++
    - Xmake
---

## 前言

本文基于 mysql-8.0.39 (git tag) 版本。

## 部署

随手写下包描述。

```lua
package("mysql")
    set_homepage("http://www.mysql.com")
    set_description("A real-time, open source transactional database.")
    set_license("GPL-2.0")

    -- add_urls("https://github.com/mysql/mysql-server/archive/refs/tags/mysql-$(version).tar.gz")

    -- add_versions("8.0.39", "3a72e6af758236374764b7a1d682f7ab94c70ed0d00bf0cb0f7dd728352b6d96")
    set_sourcedir([[A:\tmp\repo\mysql]])

    add_deps("cmake")

    on_install(function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        import("package.tools.cmake").install(package, configs)
    end)
```

为什么还自己下源码？主要是方便修改 cmake，毕竟大型库一行不改大概率是不可能的。

但在国内的网络环境下，直接 `git clone https://github.com/mysql/mysql-server.git` 必定 clone 失败，没得玩。

那只能手动挡了，自己下载 `https://github.com/mysql/mysql-server/archive/refs/tags/mysql-8.0.39.tar.gz`，找个地方解压，但用 7z 解压慢得要死，因为要先解压 tar 然后再解 gz。

幸好我发现了个工具 busybox ，可以直接用 tar 命令。直接 `scoop install main/busybox` 安装然后 `tar -xf mysql-8.0.39.tar.gz`，完美。

> xmake 也许以后也会支持这个工具：https://github.com/xmake-io/xmake/issues/5538

不过为了导出 patch，我们还需要给这个源码目录配个 .git 。

```sh
$ git init
$ git add .
$ git commit -m "init"
```

A Few Moments Later.

好慢啊，毕竟大型项目的目录和文件是数不清的。

最终询问群友，学到了 git 新的操作：partial clone。

```sh
$ git clone --filter=tree:0 --no-checkout https://github.com/mysql/mysql-server.git mysql
$ cd mysql
$ git checkout mysql-8.0.39
```

这是 `depth 1` 的加强版，我们可以只 clone tag/branch 等信息，文件和目录一个都不下载，然后只有 checkout 的时候才真正向服务器请求，爽。

> xmake 2.9.5 版本支持 [treeless](https://github.com/xmake-io/xmake/issues/5507)，git clone 第三方库用到的时候，可以达到 "按需" 下载。

## 级联依赖

先直接执行 xmake 的包本地测试看看最有啥信息。

```sh
$ xmake l scripts\test.lua --shallow -vD mysql
```

迎面而来的是一个大报错。

```console
-- Looked for boost/version.hpp in  and
-- BOOST_INCLUDE_DIR BOOST_INCLUDE_DIR-NOTFOUND
-- LOCAL_BOOST_DIR
-- LOCAL_BOOST_ZIP
-- Could not find (the correct version of) boost.
-- MySQL currently requires boost_1_77_0

CMake Error at cmake/boost.cmake:109 (MESSAGE):
  You can download it with -DDOWNLOAD_BOOST=1 -DWITH_BOOST=<directory>

  This CMake script will look for boost in <directory>.  If it is not there,
  it will download and unpack it (in that directory) for you.

  You can also download boost manually, from
  https://archives.boost.io/release/1.77.0/source/boost_1_77_0.tar.bz2

  If you are inside a firewall, you may need to use an https proxy:

  export https_proxy=http://example.com:80

Call Stack (most recent call first):
  cmake/boost.cmake:278 (COULD_NOT_FIND_BOOST)
  CMakeLists.txt:1564 (INCLUDE)
```

好吧先用 `add_deps("boost")` 配置一下。

```console
-- BOOST_INCLUDE_DIR C:/Users/star/AppData/Local/.xmake/packages/b/boost/1.86.0/f1b18bc4ca114f2c9ac8606d97867946/include
-- LOCAL_BOOST_DIR
-- LOCAL_BOOST_ZIP
-- Could not find (the correct version of) boost.
-- MySQL currently requires boost_1_77_0
```

怒了，强制要求 `boost 1.77` ，但 xrepo 默认使用最新的 boost，突然来一个指定某个版本，维护压力++。

但大库很少会修改 api，估计是里面硬编码判断版本，我们把它去掉，如果因为版本影响编译，那就报错再说。

```cmake
# cmake/boost.cmake:305

IF(NOT BOOST_MINOR_VERSION EQUAL 77)
  MESSAGE(WARNING "Boost minor version found is ${BOOST_MINOR_VERSION} "
    "we need 77"
    )
  COULD_NOT_FIND_BOOST()
ENDIF()
```

直接 `IF(NOT BOOST_MINOR_VERSION EQUAL 77)` -> `IF(FALSE)`

看起来效果不错，boost 成功找到没有报错。但接下来的 log 开始信息量大了起来。

```
-- ZLIB_VERSION (bundled) is 1.2.13
-- ZLIB_INCLUDE_DIR A:/tmp/repo/mysql/extra/zlib/zlib-1.2.13
-- Check size of off64_t
-- Check size of off64_t - failed
-- Looking for fseeko
-- Looking for fseeko - not found
-- Looking for unistd.h
-- Looking for unistd.h - not found
-- ZSTD_VERSION (bundled) is 1.5.5
-- ZSTD_INCLUDE_DIR A:/tmp/repo/mysql/extra/zstd/zstd-1.5.5/lib
-- ZSTD_LEGACY_SUPPORT not defined!
-- OPENSSL_WIN32 OPENSSL_WIN32-NOTFOUND
-- OPENSSL_WIN64 OPENSSL_WIN64-NOTFOUND
-- Could NOT find OpenSSL, try to set the path to OpenSSL root folder in the system variable OPENSSL_ROOT_DIR (missing: OPENSSL_CRYPTO_LIBRARY OPENSSL_INCLUDE_DIR)
--
Could not find system OpenSSL
Make sure you have specified a supported SSL version.
Valid options are :
openssl[0-9]+ (use alternative system library)
yes (synonym for system)
</path/to/custom/openssl/installation>

CMake Error at cmake/ssl.cmake:88 (MESSAGE):
  Please see https://wiki.openssl.org/index.php/Binaries

Call Stack (most recent call first):
  cmake/ssl.cmake:332 (FATAL_SSL_NOT_FOUND_ERROR)
  CMakeLists.txt:1797 (MYSQL_CHECK_SSL)
```

老规矩，先 `add_deps("zlib", "zstd", "openssl")` 试试看。

```
-- ZLIB_VERSION (bundled) is 1.2.13
-- ZLIB_INCLUDE_DIR A:/tmp/repo/mysql/extra/zlib/zlib-1.2.13
-- ZSTD_VERSION (bundled) is 1.5.5
-- ZSTD_INCLUDE_DIR A:/tmp/repo/mysql/extra/zstd/zstd-1.5.5/lib
-- ZSTD_LEGACY_SUPPORT not defined!
```

huh？看来内有玄机，直接翻源码。

看到行注释。

```cmake
# Usage:
#  cmake -DWITH_ZLIB="bundled"|"system"
#
# Default is "bundled".
# The default should be "system" on non-windows platforms,
# but we need at least version 1.2.13, and that's not available on
# all the platforms we need to support.
```

好，我们试试给 cmake 添加新参数。

```lua
local configs = {
    "-DWITH_ZLIB=system",
    "-DWITH_ZSTD=system",
    "-DWITH_SSL=system",
}
```

还行，zlib/zstd 都成功找到，但 openssl 这个啥意思。

```
-- Found ZLIB: C:/Users/star/AppData/Local/.xmake/packages/z/zlib/v1.3.1/95786712bac941e795afa187a68143a4/lib/zlib.lib (found version "1.3.1")
-- ZLIB_VERSION (system) is 1.3.1
-- ZLIB_INCLUDE_DIR C:/Users/star/AppData/Local/.xmake/packages/z/zlib/v1.3.1/95786712bac941e795afa187a68143a4/include
-- ZSTD_VERSION (system) is 1.5.6
-- ZSTD_INCLUDE_DIR C:/Users/star/AppData/Local/.xmake/packages/z/zstd/v1.5.6/557e528272704581b94182e01c1dcd2b/include
-- OPENSSL_WIN32 C:/Users/star/AppData/Local/.xmake/packages/o/openssl/1.1.1-w/290075b839ee412e80953472c36e007b
-- OPENSSL_WIN64 C:/Users/star/AppData/Local/.xmake/packages/o/openssl/1.1.1-w/290075b839ee412e80953472c36e007b
-- Found both 32bit and 64bit
-- OPENSSL_ROOT_DIR C:/Users/star/AppData/Local/.xmake/packages/o/openssl/1.1.1-w/290075b839ee412e80953472c36e007b
-- OPENSSL_APPLINK_C OPENSSL_APPLINK_C-NOTFOUND
--
Cannot find applink.c for WITH_SSL=system.
Make sure you have specified a supported SSL version.
```

不知道去掉这个有没有问题，但我们可以看一下 "参考答案"。

```cmake
IF(NOT OPENSSL_APPLINK_C)
RESET_SSL_VARIABLES()
FATAL_SSL_NOT_FOUND_ERROR(
    "Cannot find applink.c for WITH_SSL=${WITH_SSL}.")
ENDIF()
```

https://github.com/conan-io/conan-center-index/blob/7fdbb2410f2b8e682bfc26aee7b6a0a53ad93bed/recipes/libmysqlclient/all/conanfile.py#L163-L166

```python
replace_in_file(self, ssl_cmake,
                "IF(NOT OPENSSL_APPLINK_C)\n",
                "IF(FALSE AND NOT OPENSSL_APPLINK_C)\n",
                strict=False)
```

看起来 conan 直接去掉了这个判断，既然它们 reviewer 觉得没问题，那我们也如法炮制。

最后发现还有三个依赖（lz4/rapidjson/libevent），也同上做法。

```
-- KERBEROS path is none, disabling kerberos support.
-- HAVE_KRB5_KRB5_H
-- KERBEROS_LIBRARIES
CMake Warning at cmake/sasl.cmake:273 (MESSAGE):
  Could not find SASL
Call Stack (most recent call first):
  CMakeLists.txt:1817 (MYSQL_CHECK_SASL)
```

```
-- Could NOT find BISON (missing: BISON_EXECUTABLE)
CMake Warning at cmake/bison.cmake:119 (MESSAGE):
  No bison found!!
Call Stack (most recent call first):
  CMakeLists.txt:1938 (INCLUDE)


CMake Warning at cmake/bison.cmake:120 (MESSAGE):
  If you have bison in a non-standard location, you can do 'cmake
  -DBISON_EXECUTABLE=</path/to/bison-executable>
Call Stack (most recent call first):
  CMakeLists.txt:1938 (INCLUDE)


-- WITH_CURL=none, not using any curl library.
```

一路上去飘来了各种 warning ，看起来有一些依赖，但不是强制要求，而是可选，那就好，不是 error 那就直接无视！

但最终还是报错了，而且和依赖貌似没啥关系。

```
CMake Error at sql/CMakeLists.txt:1323 (MESSAGE):
  Cannot find A:/tmp/repo/mysql/sql/sql_yacc.h
```

## 构建选项

我陷入深思，因为直接定位到报错位置，但一点都看不懂哎。那就先逃避战术吧。

sql 是子目录，看一下主 cmakelists 是怎么使用这个目录吧。

开始搜索 `add_sub` ，很快就定位到这里。

```cmake
IF(NOT WITHOUT_SERVER)
  ADD_SUBDIRECTORY(testclients)
  ADD_SUBDIRECTORY(sql)
ENDIF()
```

这个信息很关键，再想一下，conan 包名叫 libmysqlclient。那么，这个选项明显是用来构建 mysql 服务器的，既然搞不定，那就强制关闭这个选项不构建！mysql server, さようなら。

```
CMake Error at unittest/gunit/xplugin/CMakeLists.txt:34 (GET_DIRECTORY_PROPERTY):
  GET_DIRECTORY_PROPERTY DIRECTORY argument provided but requested directory
  not found.  This could be because the directory argument was invalid or, it
  is valid but has not been processed yet.


CMake Error at unittest/gunit/xplugin/CMakeLists.txt:39 (GET_DIRECTORY_PROPERTY):
  GET_DIRECTORY_PROPERTY DIRECTORY argument provided but requested directory
  not found.  This could be because the directory argument was invalid or, it
  is valid but has not been processed yet.


CMake Error at unittest/gunit/xplugin/xpl/CMakeLists.txt:25 (GET_DIRECTORY_PROPERTY):
  GET_DIRECTORY_PROPERTY DIRECTORY argument provided but requested directory
  not found.  This could be because the directory argument was invalid or, it
  is valid but has not been processed yet.


CMake Error at unittest/gunit/xplugin/xcl/CMakeLists.txt:25 (GET_DIRECTORY_PROPERTY):
  GET_DIRECTORY_PROPERTY DIRECTORY argument provided but requested directory
  not found.  This could be because the directory argument was invalid or, it
  is valid but has not been processed yet.


CMake Error at unittest/gunit/xplugin/xcl/CMakeLists.txt:30 (GET_DIRECTORY_PROPERTY):
  GET_DIRECTORY_PROPERTY DIRECTORY argument provided but requested directory
  not found.  This could be because the directory argument was invalid or, it
  is valid but has not been processed yet.
```

好吧，我忘记了打包的第一件事，先搜一下哪里有选项控制关闭**测试**/**例子**/**文档**的构建。

```
ninja install -C build -v -j 18
[1/494] C:\PROGRA~1\MICROS~2\2022\COMMUN~1\VC\Tools\MSVC\1441~1.341\bin\Hostx64\x64\cl.exe
```

ninja ，启动！好吧终于到这一步，看看能不能完整编译到最后吧。

```
{
  sysincludedirs = {
    "prefix\include"
  },
  libfiles = {
    "prefix\lib\libmysql.lib",
    "prefix\lib\mysqlclient.lib",
    "prefix\lib\libmysql.dll"
  },
  license = "GPL-2.0",
  shared = true,
  links = {
    "libmysql",
    "mysqlclient"
  },
  static = true,
  version = "latest",
  linkdirs = {
    "prefix\lib"
  }
}
```

很好，成功编译了，但为啥 build type 是静态，却有个 dll。

没关系，继续去 conan 抄作业。

https://github.com/conan-io/conan-center-index/blob/7fdbb2410f2b8e682bfc26aee7b6a0a53ad93bed/recipes/libmysqlclient/all/conanfile.py#L273

```python
self.cpp_info.libs = ["libmysql" if self.settings.os == "Windows" and self.options.shared else "mysqlclient"]
```

改成 xmake 写法。

```lua
if package:is_plat("windows") then
    if package:config("shared") then
        os.tryrm(package:installdir("lib/mysqlclient.lib"))
        os.trymv(package:installdir("lib/libmysql.dll"), package:installdir("bin"))
    else
        os.tryrm(package:installdir("lib/libmysql.lib"))
        os.tryrm(package:installdir("lib/libmysql.dll"))
    end
else
    if package:config("shared") then
        os.tryrm(package:installdir("lib/*.a"))
    else
        os.tryrm(package:installdir("lib/*.so*"))
    end
end
```

## Linux

目前只是 Windows 构建成功，其他平台，ci 见分晓。虽然大概率是失败的。

```
CMake Error at cmake/readline.cmake:93 (MESSAGE):
  Curses library not found.  Please install appropriate package,

      remove CMakeCache.txt and rerun cmake.On Debian/Ubuntu, package name is libncurses5-dev, on Redhat and derivates it is ncurses-devel.
Call Stack (most recent call first):
  cmake/readline.cmake:127 (FIND_CURSES)
  cmake/readline.cmake:221 (MYSQL_USE_BUNDLED_EDITLINE)
  CMakeLists.txt:1904 (MYSQL_CHECK_EDITLINE)
```

果不其然。。而且只有一些 linux ci 报错，部分是成功的，猜测找到了 ci 上的系统库。

根据报错信息，翻一下 cmake。

看来 linux 下 libedit 库和它的级联依赖 ncurses ，但目录树内置了 editline 源码却没有 ncurses，搞心态这不是。

好吧继续 `add_deps("libedit", {configs = {terminal_db = "ncurses"}})`

但恶心的是，报错依旧。

```
-- Could NOT find Curses (missing: CURSES_LIBRARY CURSES_INCLUDE_PATH) 
```

我又陷入了沉思。这波思考了很久，明明有 find_package 命令为啥找不到呢。最我去翻了 cmake FindCurses 文档和源码，看完后，我理解了一切！

首先观察 pacman 的 [ncurse](https://archlinux.org/packages/core/x86_64/ncurses) 包信息，可以看到。

```
libc.so.6
libformw.so.6
libgcc_s.so.1
libmenuw.so.6
libncursesw.so.6
libpanelw.so.6
libstdc++.so.6
```

ncurses 相关的库有 w 结尾。

然后看 xrepo 里 ncurses 的包描述。

```lua
add_configs("widec", {description = "Compile with wide-char/UTF-8 code.", default = true, type = "boolean"})

on_load(function (package)
    if package:config("widec") then
        package:add("links", "ncursesw", "formw", "panelw", "menuw")
        package:add("includedirs", "include/ncursesw", "include")
    else
        package:add("links", "ncurses", "form", "panel", "menu")
        package:add("includedirs", "include/ncurses", "include")
    end
end)
```

这个库默认开启 unicode，所以库名结尾会不一样。

而 cmake 文档有行小字。

https://cmake.org/cmake/help/latest/module/FindCurses.html
> New in version 3.10: Set CURSES_NEED_WIDE to TRUE before the find_package(Curses) call if unicode functionality is required.

https://github.com/Kitware/CMake/blob/master/Modules/FindCurses.cmake

```cmake
# we don't know anything about cursesw, so only ncurses
# may be ncursesw
if(NOT CURSES_NEED_WIDE)
  set(NCURSES_LIBRARY_NAME "ncurses")
  set(CURSES_FORM_LIBRARY_NAME "form")
else()
  set(NCURSES_LIBRARY_NAME "ncursesw")
  set(CURSES_FORM_LIBRARY_NAME "formw")
  # Also, if we are searching for wide curses - we are actually searching
  # for ncurses, we don't know about any other unicode version.
  set(CURSES_NEED_NCURSES TRUE)
endif()
```

最后加上修改，根据 ncurses 包配置来适配 cmake。

```lua
if package:is_plat("linux") then
    local widec = package:dep("ncurses"):config("widec")
    -- From FindCurses.cmake
    table.insert(configs, "-DCURSES_NEED_WIDE=" .. (widec and "ON" or "OFF"))
    table.insert(configs, "-DWITH_EDITLINE=system")
end
```

然而事情还没结束。。

```
-- EDITLINE_INCLUDE_DIR /github/home/.xmake/packages/l/libedit/3.1/0fa7ba91e7cf4451977c4509d788cad2/include/editline
-- EDITLINE_LIBRARY /github/home/.xmake/packages/l/libedit/3.1/0fa7ba91e7cf4451977c4509d788cad2/lib/libedit.a
-- Performing Test EDITLINE_HAVE_HIST_ENTRY
-- Performing Test EDITLINE_HAVE_HIST_ENTRY - Success
-- Performing Test EDITLINE_HAVE_COMPLETION_INT
-- Performing Test EDITLINE_HAVE_COMPLETION_INT - Failed
-- Performing Test EDITLINE_HAVE_COMPLETION_CHAR
-- Performing Test EDITLINE_HAVE_COMPLETION_CHAR - Failed
-- Configuring incomplete, errors occurred!
```

最头大的一集。不过老规矩，先用 `EDITLINE_HAVE_COMPLETION_INT` 定位吧。

可以看到 mysql 这里用了 `CHECK_CXX_SOURCE_COMPILES` 检查我们的 editline 库有没有效。但我忘记了怎么让 cmake 输出完整的报错信息，可恶。

我灵机一动，想起来 xrepo 包默认都是静态库，那把 editline 构建成 shared 试一下呢。

果然成功了，和我预想中的没错。分析一下，mysql 源码里是这样写的。

```cmake
LIST(APPEND CMAKE_REQUIRED_LIBRARIES ${EDITLINE_LIBRARY})
```

如果用静态库，可以看到 `EDITLINE_LIBRARY` 只有 `libedit.a`，缺失了它的级联依赖 ncurses ，那么编译肯定报错。

如果用动态库，那么 ncurses.a 的东西已经在 libedit.so 里，所以链接成功！

怎么改呢，加上 ncurses 咯。

```lua
local editline = package:dep("libedit")
if not editline:config("shared") then
    local strings = "\nFIND_PACKAGE(Curses)\nlist(APPEND EDITLINE_LIBRARY ${CURSES_LIBRARIES})\n"
    io.replace("cmake/readline.cmake",
        "MARK_AS_ADVANCED(EDITLINE_INCLUDE_DIR EDITLINE_LIBRARY)",
        "MARK_AS_ADVANCED(EDITLINE_INCLUDE_DIR EDITLINE_LIBRARY)" .. strings,
        {plain = true})
end
```

至此，macosx/linux/windows 上只构建 mysql client，ci 终于都通过了。

> macosx: 什么，居然没在想我的事情。

## 交叉编译

```sh
$ xmake l scripts\test.lua --shallow -vD -a arm64 mysql
```

当想试试不一样的东西，cmake 总是给我当头一棒。

```
CMake Error at cmake/libevent.cmake:181 (MESSAGE):
  LIBEVENT version must be at least 2.1, found unknown error.

  Please use -DWITH_LIBEVENT=bundled
Call Stack (most recent call first):
  CMakeLists.txt:1912 (MYSQL_CHECK_LIBEVENT)
```

而获取版本的手法，只能说很_

```cmake
  SET(TEST_SRC
    "#include <event.h>
     #include <stdio.h>
    int main()
    {
      fprintf(stdout, \"%s\", LIBEVENT_VERSION);
    }
    "
    )
  FILE(WRITE
    "${CMAKE_BINARY_DIR}/find_libevent_version.c"
    "${TEST_SRC}"
    )
  TRY_RUN(TEST_RUN_RESULT COMPILE_TEST_RESULT
    ${CMAKE_BINARY_DIR}
    "${CMAKE_BINARY_DIR}/find_libevent_version.c"
    CMAKE_FLAGS "-DINCLUDE_DIRECTORIES=${LIBEVENT_INCLUDE_DIRS}"
    COMPILE_OUTPUT_VARIABLE OUTPUT
    RUN_OUTPUT_VARIABLE RUN_OUTPUT
    )
```

有 `TRY_RUN` 你还想交叉编译？

无所谓，失败就失败，可以直接改 cmake 硬编码版本号上去。
```lua
if package:is_cross() then
    local libevent_version = package:dep("libevent"):version()
    if not libevent_version then
        version = "2.1.12"
    end
    -- skip try_run
    io.replace("cmake/libevent.cmake",
        [[SET(LIBEVENT_VERSION_STRING "${RUN_OUTPUT}")]],
        format([[SET(LIBEVENT_VERSION_STRING "%s")]], libevent_version), {plain = true})
end
```

除此之外 rapidjson 库也有 `TRY_RUN` ，同上解决掉。

```lua
if package:is_cross() then
    -- skip try_run
    io.replace("cmake/rapidjson.cmake", "IF (NOT HAVE_RAPIDJSON_WITH_STD_REGEX)", "if(FALSE)", {plain = true})
end
```

终于看到熟悉的 ninja 字眼，这代表离成功不远了，但这可是交叉编译！

```
该版本的 runtime_output_directory\uca9dump.exe 与你运行的 Windows 版本不兼容。请查看计算机的系统信息，然后联系软件发布者。
```

看了都头大，这种情况其他包也见过（icu），交叉编译需要 host 版本的工具做各种事情（探测/代码生成）。

先判断这几种情况。

Round 1: mysql 有一堆 deps 这些 tools 依赖么。如果不依赖，可以直接用 xmake 单独构建塞回给 cmake 用。

Round 2: 观察源码，依赖了一部分，比如 openssl，那永远只能用 cmake 去构建这些了。换个思路，xmake 可以给单个 target 设置 host arch，其余都是 target arch，那 cmake 可不可以改呢。

Round 3: 令人绝望的是，可以，但要写大量代码。

https://discourse.cmake.org/t/building-compile-time-tools-when-cross-compiling/601

Ben Boeckel (Kitware)ben.boeckel

> VTK handles it this way:
> 
> Create an option which makes just the tools used on the host during a build (https://gitlab.kitware.com/vtk/vtk/blob/a5f938b2fdfefa522439065e040cb42f65d88444/CMakeLists.txt#L231 83) and install a package with a different namespace than normal builds
> 
> If cross compiling without an emulator, require that host tools package (https://gitlab.kitware.com/vtk/vtk/blob/master/CMake/vtkCrossCompiling.cmake 56)
> 
> If the host tools are found, use them in the add_custom_command call (https://gitlab.kitware.com/vtk/vtk/blob/a5f938b2fdfefa522439065e040cb42f65d88444/CMake/vtkModule.cmake#L3047 45), using CMAKE_CROSSCOMPILING_EMULATOR if available

Craig Scott

> Yes, I’ve used ExternalProject to mix different compilers in the one project (firmware for an embedded device that gets included in a software package for the host platform). The stackoverflow Q&A I linked to mentions this is possible in its question, but was explicitly out of scope for that particular situation. For the question posted here, it could probably be made to work, but you may have a bit of fiddling to do in order to have your main build know where the build tool’s executable will be. Once you put something out into an ExternalProject, you become responsible for telling your main build where all its build artefacts are. In a true super build, you can usually do that by installing to a staging area and telling later ExternalProjects to look there in find_package(), etc. calls using CMAKE_PREFIX_PATH. Not sure this fits the use case here though.

于是我决定开一个新包命名为 `mysql-build-tools`，专门用于构建 host tools 给 mysql 交叉编译用。

完整的交叉编译流程变为：

1. 构建 boost 等依赖的 host 版本。
2. 构建 mysql-build-tools。
3. 构建 boost 等依赖的 target arch 版本。
4. 构建 mysql。

然后根据每次构建的报错信息，总结出要构建的 host tools。

```lua
local tool_list = {
    "uca9dump",
    "comp_sql",
    "comp_err",
    "comp_client_err",
    "libmysql_api_test",
}
```

mysql 会把用到的 tools 放在 `build/runtime_output_directory` 目录里。那么在 cmake 执行前，先 mkdir 然后把构建好的 host tools 拷贝进去。

不愉快的是，ninja 还是把构建了这些 tools。理论上这些 host tools 不会被重新构建，因为 mtime 永远是大于源码时间的。

但现代构建系统除了检测 mtime，还会生成一些 `.d/.dep` 文件来确保增量编译的稳定性。

所以只能用暴力一点的方法，大范围 patch cmake，比如：

```diff
diff --git a/strings/CMakeLists.txt b/strings/CMakeLists.txt
index f4cd85e786..99dbd5f811 100644
--- a/strings/CMakeLists.txt
+++ b/strings/CMakeLists.txt
@@ -59,7 +59,7 @@ SET(STRINGS_SOURCES
   xml.cc
 )
 
-MYSQL_ADD_EXECUTABLE(uca9dump uca9-dump.cc SKIP_INSTALL)
+# MYSQL_ADD_EXECUTABLE(uca9dump uca9-dump.cc SKIP_INSTALL)
 
 MY_CHECK_CXX_COMPILER_WARNING("-Wmissing-profile" HAS_MISSING_PROFILE)
 IF(HAS_MISSING_PROFILE)
@@ -78,7 +78,7 @@ ADD_CUSTOM_COMMAND(OUTPUT ${ZH_HANS_DST_FILE}
                    COMMAND uca9dump ja
                      --in_file=${JA_HANS_SRC_FILE}
                      --out_file=${JA_HANS_DST_FILE}
-                   DEPENDS uca9dump ${ZH_HANS_SRC_FILE} ${JA_HANS_SRC_FILE}
+                   DEPENDS ${ZH_HANS_SRC_FILE} ${JA_HANS_SRC_FILE}
                   )
 
 SET_SOURCE_FILES_PROPERTIES(
```

这里去掉了 mysql 封装的 `MYSQL_ADD_EXECUTABLE`。因为 `DEPENDS` 指定的是 target，但此时没了这个 target，也要删掉。

这时可以把 `mysql-build-tools` 设置为 binary 包，这样 mysql 包 `add_deps("mysql-build-tools")` 后，xmake 会把自己编译的 tools 所在路径加入到 PATH 里，让 ninja 可以成功执行 `uca9dump` 命令。

其他 tools 也同上。

## Server（WIP）
