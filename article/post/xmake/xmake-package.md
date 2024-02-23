---
title: "如何给 Xmake 打包"
date: 2023-08-19
lastmod: 2023-08-25
draft: false
tags:
    - C++
---

先来展示个 cmake 包模板。

```lua
package("xxx")
    set_homepage("https://github.com/xxx/yyy")
    set_description("")
    set_license("")

    add_urls("https://github.com/xxx/yyy/archive/refs/tags/$(version).tar.gz",
             "https://github.com/xxx/yyy.git")

    add_versions("v1.0.0", "sha256")

    add_deps("cmake", "ninja")

    on_install(function (package)
        local configs = {}
        table.insert(configs, "-DCMAKE_BUILD_TYPE=" .. (package:is_debug() and "Debug" or "Release"))
        table.insert(configs, "-DBUILD_SHARED_LIBS=" .. (package:config("shared") and "ON" or "OFF"))
        if package:is_plat("windows") and package:config("shared") then
            table.insert(configs, "-DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON")
        end
        io.replace("CMakeLists.txt", "xxx", "", {plain = true})
        import("package.tools.cmake").install(package, configs, {cmake_generator = "Ninja"})
    end)

    on_test(function (package)
        assert(package:has_cxxfuncs("xxx", {includes = "yyy.h"}))
    end)
```

观察发现，这其实和写 target 差不多，不过 api 的语义不一样而已。

```sh
git clone https://github.com/xmake-io/xmake-repo
# 使用脚本生成模板
xmake l scripts/new.lua github:yyy/xxx
```

在本地测试包。

```
xmake l scripts/test.lua -vD --shallow xxx
```

可以添加 `-p mingw` 或 `-k shared` 等参数来测试不同的平台 和 configs。

测试成功后，可以提交 pr。注意要 push 到 dev 分支才能触发 ci 的检测。

> 其实选错分支也没关系，可以重新选择，然后先 close pr 再 open 来触发 ci。

## API 解读

## 名字

包名一律统一为**小写**，为了适配不同系统环境下，不同包管理管理的系统库查找，统一全平台。

## 外部源

使用了 `add_extsources`， 会主动去查找 apt/pacman 等包管理管理的包。

### version

通常情况下，使用 git tag 作为包的版本号。如果下载 `tar.gz` 压缩包失败，只要 url 中添加了库的 git 地址，xmake 就可以使用 git clone 并根据 tag 号切换。

有些库版本号不是以 x.y.z 的形式来命名，这样 xmake 会解析失败，需要我们转换版本号。

比如 directx 相关的包都是用月份+年份来命名，我们需要把他转换成用点和数字表示的日期。

```lua
local tag =
{
    ["2023.06"] = "jun2023",
}

local version = function (version) return tag[tostring(version)] end

add_versions("2023.06", "sha256")
```

### configs

对应库的构建选项。如果一些内置选项支持不完善，比如 `shared`，就会打上 `readonly`，表示不可修改，只能使用默认配置。

```lua
add_configs("shared", {description = "Build shared library.", default = true, type = "boolean", readonly = true})
```

需要打上 `readonly` 的情况各有不同，比如库根本就不支持，或构建的时候有问题，打包者处理不了。

### on_install

这一步需要调用构建系统对库 配置 -> 构建 -> 安装。

最简单的，直接把 debug/release 和 shared/static 等选项传给构建系统。如果库在 Windows 上没支持动态库，我们可以尝试使用 cmake 的导出符号来支持。

```lua
if package:is_plat("windows") and package:config("shared") then
    table.insert(configs, "-DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON")
end
```

xmake 包默认是不保留例子和测试的，所以需要打包者添加构建选项取消。然而有些库根本没有这些选项，我们可以适当优化，比如使用 `io.replace` 修改 cmakelists，把 `add_subdirectory(test)` 等删掉，或者直接打个 patch 修改。

### on_test

平时用 `has_cxxfuncs` 系列既可以保持简洁，又可以检测到依赖的**静态库**/**动态库**有没有被正常链接上。

```lua
on_test(function (package)
    assert(package:has_cxxfuncs("xxx", {includes = "yyy.h"}))
end)
```

有些 C++ 库只暴露出类接口，只能通过写相关代码进行测试。

```lua
on_test(function (package)
    assert(package:check_cxxsnippets({test = [[
        #include <xxx/yyy.hpp>
        void test() {
            auto var = xxx();
        }
    ]]}, {configs = {languages = "c++17"}}))
end)
```

## 优化库的构建

### 本地测试

因为要保持 xmake 包最小化依赖原则，实际上 cmake 包只使用系统默认的构建系统，而不是 ninja。但打包者依然可以在测试中使用 ninja 加速编译。

### 头文件库

设置 `headeronly` 类型后，build hash 会唯一，避免浪费硬盘。

```lua
set_kind("library", {headeronly = true})
```

有些库可能支持非头文件模式编译，通常使用 `header_only` 来命名 config，然后 `on_load` 和 `on_install` 需要做对应处理。

```lua
add_configs("header_only", {description = "Use header only version.", default = true, type = "boolean"})

on_load(function (package)
    if package:config("header_only") then
        package:set("library", {headeronly = true})
    end
end)

on_install(function (package)
    if package:config("header_only") then
        os.cp("include", package:installdir())
        return
    end

    -- 非头文件模式编译
end)
```

有些库会提供构建系统来安装头文件库，那么就要优先使用构建系统安装头文件，而不是手动拷贝。

### port（使用 xmake 构建）

当一些库没有构建系统，或者库使用的构建系统，在尝试多次但都构建失败，那么需要考虑用 xmake 本身来编译该库，这对打包者来说是一个挑战。

这里先给出模板。

```lua
on_install(function (package)
    io.writefile("xmake.lua", [[
        add_rules("mode.debug", "mode.release")
        set_languages("c++17")
        target("xxx")
            set_kind("$(kind)")
            add_files("src/**.cpp")
            add_headerfiles("include/**.h")
            if is_plat("windows") and is_kind("shared") then
                add_rules("utils.symbols.export_all", {export_classes = true})
            end
    ]])
    import("package.tools.xmake").install(package)
end)
```

有时候 `xmake.lua` 太大，影响包描述文件的简洁性，可以在包目录新建一个 `port/xmake.lua`，然后描述文件这样写：

```lua
on_install(function (package)
    os.cp(path.join(package:scriptdir(), "port", "xmake.lua"), "xmake.lua")
    import("package.tools.xmake").install(package)
end)
```
