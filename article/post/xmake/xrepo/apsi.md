---
title: "microsoft APSI 交叉编译"
date: 2024-11-26
lastmod: 2024-11-26
draft: false
tags:
    - C/C++
    - Xmake
---

## 前言

打包中处理交叉编译的小短文。

## 依赖

```lua
add_deps("cmake")
add_deps("microsoft-seal", {configs = {ms_gsl = true, zstd = true, throw_tran = false}})
add_deps("microsoft-kuku", "flatbuffers", "jsoncpp")
```

用 ascii 可视化一下依赖树。

```
microsoft-apsi
├─ microsoft-seal
│  ├─ zstd
│  ├─ microsoft-gsl
│  ├─ hexl (optional)
├─ microsoft-kuku
├─ flatbuffers
├─ jsoncpp
├─ cppzmq (optional)
│  ├─ zeromq
├─ log4cplus (optional)
```

apsi 的 cmake 文件都是用 `find_package` 来查找依赖，所以这块基本不需要打 patch 。

## 交叉编译

从 `cmake/DetectArch.cmake` 文件发现，使用了 `check_cxx_source_runs` 来测试，里面都是一些架构相关的宏。所以很明显，探测架构是不需要去运行程序，只需要编译成功。这里直接替换 cmake 函数，防止触发 `try_run` 。

```lua
io.replace("cmake/DetectArch.cmake", "check_cxx_source_runs", "check_cxx_source_compiles", {plain = true})
```

这里看起来使用了 flatbuffers 的 flatc 进行 codegen 。

```cmake
find_package(Flatbuffers REQUIRED)
if(NOT Flatbuffers_FOUND)
    message(FATAL_ERROR "Flatbuffers: not found")
else()
    message(STATUS "Flatbuffers: found")
    get_target_property(FLATBUFFERS_FLATC_PATH flatbuffers::flatc IMPORTED_LOCATION_RELEASE)
    message(STATUS "flatc path: ${FLATBUFFERS_FLATC_PATH}")
    include(CompileSchemaCXX)
endif()
```

这说明需要构建两份 flatbuffers 。

- target flatbuffers library
- host flatbuffers flatc

xmake 支持多个同名库的不同配置。

```lua
if package:is_cross() then
    package:add("deps", "flatbuffers~binary", {host = true, private = true, kind = "binary"})
end
```

- `host = true` -> 构建 host 版本。
- `private = true` -> 仅在构建包的时候使用，不需要传播给下游。
- `kind = "binary"` -> 告诉 flatbuffers 只需要构建 flatc 。

这样 path 里就有 host 版本的 flatc 了。

不过上面 cmake 找到的 target flatbuffers cmake 文件，里面因为没有 host 版本的 flatc 肯定会报错。

所以我们需要先删掉这一行，然行赋值变量 `FLATBUFFERS_FLATC_PATH` 。

```lua
if package:is_cross() then
    io.replace("CMakeLists.txt", "get_target_property(FLATBUFFERS_FLATC_PATH flatbuffers::flatc IMPORTED_LOCATION_RELEASE)", "", {plain = true})
    table.insert(configs, "-DFLATBUFFERS_FLATC_PATH=flatc")
end
```

> 也可以赋值绝对路径。
