---
title: "如何写 Xmake 包描述"
date: 2023-08-19
lastmod: 2024-12-14
draft: false
tags:
    - C++
---

无论你是否将包提交至官方包管理，本文都可以作为编写包描述的参考。


先来展示个 cmake 包模板。

```lua
package("xxx")
    set_homepage("https://github.com/xxx/yyy")
    set_description("")
    set_license("")

    add_urls("https://github.com/xxx/yyy/archive/refs/tags/$(version).tar.gz",
             "https://github.com/xxx/yyy.git")

    add_versions("v1.0.0", "sha256")

    add_defines("Hello")

    add_cxflags("-DWorld")

    if is_plat("linux") then
        add_syslinks("pthread")
    elseif is_plat("windows") then
        add_syslinks("user32")
    end

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

### 名字

包名一律统一为**小写**，为了适配不同系统环境下，不同包管理管理的系统库查找，统一全平台。

### 外部源

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

如果一些包没有 release 包，可以选择使用 commit 日期作为版本号，sha256 替换为 commit hash。

```lua
add_versions("2024.01.01", "commit hash")
```

### configs

对应库的构建选项。如果一些内置选项支持不完善，比如 `shared`，就会打上 `readonly`，表示不可修改，只能使用默认配置。

```lua
add_configs("shared", {description = "Build shared library.", default = true, type = "boolean", readonly = true})
```

需要打上 `readonly` 的情况各有不同，比如库根本就不支持，或构建的时候有问题，打包者处理不了。

### 需要继承的编译配置

```lua
add_defines("Hello")

add_cxflags("/utf-8")

if is_plat("linux") then
    add_syslinks("pthread")
elseif is_plat("windows") then
    add_syslinks("user32")
end
```

当 target add_package 后，这些配置都会被自动加上。

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

平时用 `has_cxxfuncs` 系列既可以保持简洁，又可以检测到符号有没有链接上。

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

## 预编译二进制（需要本地查找的库）

直接拷贝即可。

```lua
package("precompiled_binary")
    add_urls("https://github.com/xxx/yyy/archive/refs/tags/$(version).7z")

    add_versions("1.0", "sha256")

    on_install(function (package)
        os.cp("*.h", package:installdir("include"))
        os.cp("*.lib", package:installdir("lib"))
        os.trycp("*.so", package:installdir("lib"))
        os.trycp("*.dll", package:installdir("bin"))
    end)

    on_test(function (package)
        assert(package:has_cxxfuncs("xxx", {includes = "yyy.h"}))
    end)
```

如果想引用本地的二进制。

```lua
package("precompiled_binary")
    on_load(function (package)
        package:set("installdir", path.join(os.scriptdir(), "precompiled_binary_dir"))
    end)

    on_fetch(function (package)
        local result = {}
        if is_plat("windows") then
            result.linkdirs = package:installdir("lib-windows")
            package:addenv("PATH", package:installdir("bin"))
        elseif is_plat("linux") then
            package:addenv("LD_LIBRARY_PATH", package:installdir("lib-linux"))
            result.linkdirs = package:installdir("lib-linux")
        elseif is_plat("macosx") then
            package:addenv("DYLD_LIBRARY_PATH", package:installdir("lib-macos"))
            result.linkdirs = package:installdir("lib-macos")
        else
            package:addenv("LD_LIBRARY_PATH", package:installdir("lib-linux"))
            result.linkdirs = package:installdir("lib-linux")
        end

        result.links = {"xxx", "yyy"}
        result.includedirs = package:installdir("include")
        return result
    end)

    on_test(function (package)
        assert(package:has_cxxfuncs("xxx", {includes = "yyy.h"}))
    end)
```

## 优化库的构建

### 本地测试

因为要保持 xmake 包最小化依赖原则，实际上 cmake 包只使用系统默认的构建系统，而不是 ninja。但打包者依然可以在测试中使用 ninja 加速编译，我们可以使用 policy 来启用。

> xmake 3.0 版本将会默认使用 ninja 进行构建

```sh
$ xmake g --policies=package.cmake_generator.ninja
```

或者在包描述写：

```lua
-- add_deps("ninja")

import("package.tools.cmake").install(package, configs, {cmake_generator = "Nnija"})
```

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

## 实战

这里拿一位新手打包写的包描述进行 code review。

```lua
package("reflex")
    set_description("The reflex package")

    add_urls("https://github.com/Genivia/RE-flex/archive/refs/tags/v$(version).tar.gz","https://github.com/Genivia/RE-flex.git")
    add_versions("3.5.1", "e08ed24a6799a6976f6e32312be1ee059b4b6b55f8af3b433a3016d63250c0e4")
    add_versions("4.3.0", "1658c1be9fa95bf948a657d75d2cef0df81b614bc6052284935774d4d8551d95")

    add_includedirs("include")

    on_load(function (package)
        package:addenv("PATH", "bin")
    end)

    on_install(function (package)
        io.writefile("xmake.lua",[[
set_languages("cxx11")

target("ReflexLib")
    set_kind("shared")
    add_includedirs("include")
    add_headerfiles("include/reflex/*.h", {prefixdir = "reflex"})
    add_files("lib/*.cpp")
    add_files("unicode/*.cpp")
    add_vectorexts("all")
target_end()

target("ReflexLibStatic")
    set_kind("static")
    add_includedirs("include")
    add_headerfiles("include/reflex/*.h", {prefixdir = "reflex"})
    add_files("lib/*.cpp")
    add_files("unicode/*.cpp")
    add_vectorexts("all")
target_end()

target("Reflex")
    set_kind("binary")
    add_includedirs("include")
    add_files("src/*.cpp")
    add_deps("ReflexLibStatic")
    add_vectorexts("all")
target_end()
        ]])
        local configs = {}
        import("package.tools.xmake").install(package, configs)
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <reflex/matcher.h>
            void test()
            {
                reflex::Matcher matcher("\w+","114 514 1919 810");
            }
        ]]}, {configs = {languages = "cxx11"}}))
    end)
package_end()
```

一看开头，就知道没有用脚本（`xmake l scripts/new.lua Genivia/RE-flex`）生成模板。

```lua
add_urls("https://github.com/Genivia/RE-flex/archive/refs/tags/v$(version).tar.gz","https://github.com/Genivia/RE-flex.git")
    add_versions("3.5.1", "e08ed24a6799a6976f6e32312be1ee059b4b6b55f8af3b433a3016d63250c0e4")
    add_versions("4.3.0", "1658c1be9fa95bf948a657d75d2cef0df81b614bc6052284935774d4d8551d95")
```

- `add_urls` 正常情况下不需要加 `v`，放在 `add_versions("v4.3.0"` 就行。
- 因为资源所限（没有 conan 那么多 ci 一次性测试多个版本），xmake-repo ci 只会测试最新版本，所以先提交 `add_versions("3.5.1"`，等 ci 通过后，再提交新的版本。

```lua
add_includedirs("include")

on_load(function (package)
    package:addenv("PATH", "bin")
end)
```

- `add_includedirs("include")` 多余的，xmake 会默认添加 `package:installdir("include")`。
- `package:addenv("PATH", "bin")` 放在 `on_install` 结尾就行，没必要用 `on_load`。

```lua
    on_install(function (package)
        io.writefile("xmake.lua",[[
set_languages("cxx11")

target("ReflexLib")
    set_kind("shared")
    add_includedirs("include")
    add_headerfiles("include/reflex/*.h", {prefixdir = "reflex"})
    add_files("lib/*.cpp")
    add_files("unicode/*.cpp")
    add_vectorexts("all")
target_end()

target("ReflexLibStatic")
    set_kind("static")
    add_includedirs("include")
    add_headerfiles("include/reflex/*.h", {prefixdir = "reflex"})
    add_files("lib/*.cpp")
    add_files("unicode/*.cpp")
    add_vectorexts("all")
target_end()

target("Reflex")
    set_kind("binary")
    add_includedirs("include")
    add_files("src/*.cpp")
    add_deps("ReflexLibStatic")
    add_vectorexts("all")
target_end()
        ]])
        local configs = {}
        import("package.tools.xmake").install(package, configs)
    end)
```

这里有一个很大的问题，因为 xmake 自带包管理，所以我们根本没必要照抄 cmake 同时构建动态和静态库，所以这里应该只留一个 lib target。

很多库没有考虑 Windows 上的动态库导出（开源社区日常嫌弃 Windows），所以我们要手动加上，一般情况下，都能正常导出符号（正常写代码不推荐用）。

```lua
if is_plat("windows") and is_kind("shared") then
    add_rules("utils.symbols.export_all", {export_classes = true})
end
```

另外还有些重复配置，可以移到全局域里，更优雅。

改良后：

```lua
package("re-flex")
    set_homepage("https://www.genivia.com/doc/reflex/html")
    set_description("A high-performance C++ regex library and lexical analyzer generator with Unicode support. Extends Flex++ with Unicode support, indent/dedent anchors, lazy quantifiers, functions for lex and syntax error reporting and more. Seamlessly integrates with Bison and other parsers.")
    set_license("BSD-3-Clause")

    add_urls("https://github.com/Genivia/RE-flex/archive/refs/tags/$(version).tar.gz",
             "https://github.com/Genivia/RE-flex.git")

    add_versions("v4.3.0", "1658c1be9fa95bf948a657d75d2cef0df81b614bc6052284935774d4d8551d95")

    on_install(function (package)
        io.writefile("xmake.lua",[[
            add_rules("mode.debug", "mode.release")
            set_languages("cxx11")
            add_includedirs("include")
            set_encodings("utf-8")
            add_vectorexts("all")

            target("re-flex")
                set_kind("$(kind)")
                add_headerfiles("include/reflex/*.h", {prefixdir = "reflex"})
                add_files("lib/*.cpp")
                add_files("unicode/*.cpp")
                if is_plat("windows") and is_kind("shared") then
                    add_rules("utils.symbols.export_all", {export_classes = true})
                end

            target("reflex")
                set_kind("binary")
                add_files("src/*.cpp")
                add_deps("re-flex")
        ]])
        import("package.tools.xmake").install(package, configs)
        package:addenv("PATH", "bin")
    end)

    on_test(function (package)
        assert(package:check_cxxsnippets({test = [[
            #include <reflex/matcher.h>
            void test() {
                reflex::Matcher matcher("\w+","114 514 1919 810");
            }
        ]]}, {configs = {languages = "cxx11"}}))
    end)
```
