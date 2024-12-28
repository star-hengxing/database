---
title: "使用相同的依赖进行交叉编译"
date: 2024-12-21
lastmod: 2024-12-28
draft: false
tags:
    - C/C++
    - Xmake
---

本文使用 protobuf 库作为例子。

# 前言

交叉编译通常需要用到库的工具进行代码生成，然后再进行编译链接。

所以包管理需要构建两份名字相同的，但编译参数不一样的库。

下面看一下三个包管理的用法。

# conan

```python
from conan import ConanFile
from conan.tools.cmake import cmake_layout


class ExampleRecipe(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeDeps", "CMakeToolchain"

    def requirements(self):
        self.requires("protobuf/5.27.0")

    def build_requirements(self):
        self.tool_requires("protobuf/<host_version>")

    def layout(self):
        cmake_layout(self)
```

- https://docs.conan.io/2/examples/graph/tool_requires/using_protobuf.html
- https://conan.io/center/recipes/protobuf

# vcpkg

没在网上找到描述相同依赖的例子，貌似只能这样用。

```json
{
    "name": "protobuf",
    "dependencies": [
        { "name": "protobuf", "host": true }
    ]
}
```

- https://devblogs.microsoft.com/cppblog/vcpkg-host-dependencies
- https://learn.microsoft.com/en-us/vcpkg/users/host-dependencies

# xrepo

需要在库名后加上 `~` 来使用。

```lua
add_requires("protobuf-cpp~host", {host = true, alias = "protoc"})
add_requires("protobuf-cpp")

add_packages("protoc", {links = {}})
add_packages("protobuf-cpp")
```

# 问题

protoc 是作为代码生成的开发工具，交叉编译给非 windows/linux/macos/bsd 平台没什么用，毕竟在很小众的平台写代码并且还使用包管理的概率太小了。所以 protoc 基本只给 host 构建。

但包管理没有很简单的方法禁止 protobuf 去构建 protoc。

> flatbuffers 只需要 `-DFLATBUFFERS_BUILD_SHAREDLIB=OFF` & `-DFLATBUFFERS_BUILD_FLATLIB=OFF` 就能构建出 flatc。

那么在交叉编译的时候，也会构建出 target 平台的 protoc ，导致 cmake/xmake find 的时候会 "不小心" 找到了非 host 版本的 protoc，最终构建失败。

三个包管理都报告了类似的 issue。

- https://github.com/microsoft/vcpkg/issues/41195
- https://github.com/conan-io/cmake-conan/issues/384
- https://github.com/xmake-io/xmake/issues/5399

# 解决

在 xrepo 中，我对 `protoc` 和 `protobuf-cpp` 包进行大改造。

https://github.com/xmake-io/xmake-repo/pull/5881

- 因为 xmake 处理 host 包机制的问题，必须将平台相关的逻辑，从描述域搬去脚本域处理。protobuf 依赖 abseil，那么这两个包都要移动代码。
```lua
-- before
if is_plat("windows", "mingw") then
    add_syslinks("advapi32", "dbghelp", "bcrypt")
elseif is_plat("linux", "bsd") then
    add_syslinks("pthread")
elseif is_plat("macosx") then
    add_frameworks("CoreFoundation")
end
-- after
on_load(function (package)
    if package:is_plat("windows", "mingw", "msys") then
        package:add("syslinks", "advapi32", "dbghelp", "bcrypt")
    elseif package:is_plat("linux", "bsd") then
        package:add("syslinks", "pthread")
    elseif package:is_plat("macosx", "iphoneos") then
        package:add("frameworks", "CoreFoundation")
    end
end)
```

- 调用 protobuf 的 `cmake install` 后，如果当前不是 host 包，就删掉，避免上面的问题。

```lua
if package:is_cross() then
    os.tryrm(package:installdir("bin/*.exe"))
    os.tryrm(package:installdir("bin/protoc"))
end
```

- `protoc` 包直接把 `protobuf-cpp` 作为依赖，并设置包类型为 `binary`，这样 protoc 永远只会构建出 host 版本。

改造成功后，xmake 用户只需要这样使用，无缝支持交叉编译。

```lua
add_requires("protoc", "protobuf-cpp")
-- add_requireconfs("protoc.protobuf-cpp", {override = true, version = "28.0"})
```

# 打包

现在有很多依赖 protobuf 的库应该都是不支持交叉编译的，那么如何改造呢。

包描述首先写上：

```lua
package:add("protobuf-cpp")
if package:is_cross() then
    package:add("deps", "protoc")
end
```

这里的例子是 onnx 库。

https://github.com/onnx/onnx/blob/211157b7ad16d229dc79bd4d5ecc0327e89e369f/CMakeLists.txt#L165-L194

分析库的 cmakelists，发现他从环境变量 path 里找 protoc ，并基于 protoc 的路径来找 protobuf ，那这样永远也支持不了交叉编译。

目前 onnx 是写了一个 python 脚本用 protoc 进行代码生成，那么我们可以修改 传递 protoc 路径的变量。
```patch
+set(ONNX_PROTOC_EXECUTABLE ${Protobuf_PROTOC_EXECUTABLE})
-set(ONNX_PROTOC_EXECUTABLE protoc)
```

这样就能轻松解决问题，因为 xrepo 的 path 里永远只有 host protoc。

如果其他库使用的是 cmake 内置的 codgen 脚本，那么可能需要参考：

https://github.com/protocolbuffers/protobuf/issues/14576#issuecomment-2376921807
