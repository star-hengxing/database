---
title: "Xmake 常见问题解答"
date: 2023-03-04
lastmod: 2023-08-01
draft: false
tags:
    - C++
    - Xmake
---

**如果在本文没找到解答，可以去 [github](https://github.com/xmake-io/xmake/) 提 issue 和讨论区搜索。**

如果是官方包管理的问题，或者想请求加入一些包，去 [xmake-repo](https://github.com/xmake-io/xmake-repo) 提 issue。

> 提 issue 请附带 log，`xmake -vD`命令可以输出详细的 log 信息。

## 基础

### 避免外网访问

xmake 很多操作需要访问 github（拉取 xmake-repo/build-artifact），而在公司内网开发是不需要这些操作的。

```sh
xmake g --network=private
```

参考：

- https://github.com/xmake-io/xmake/issues/947

### Windows 上 Qt 项目控制台没有输出

使用：

```lua
add_ldflags("/subsystem:console")
```

xmake 的 qt rule 里会检测 ldflags 里有没有`/subsystem`，如果没有就默认`/subsystem:windows`。

### 给单独源文件添加参数

```lua
add_files("test/*.c", "test2/test2.c", {defines = "TEST2", languages = "c99", includedirs = ".", cflags = "-O0"})
-- 强制禁用 cxflags,cflags 等编译选项的自动检测
add_files("src/*.c", {force = {cxflags = "-DTEST", mflags = "-framework xxx"}})
```

### 给指定文件添加 config

```lua
target("test")
    add_files("test/*.cpp", {foo = 1})

    on_config(function (target)
        -- configs = {foo = 1}
        local configs = target:fileconfig("src/main.cpp")
    end)
```

### 找不到 vs 工具链

在 Visual Studio Installer 修改了配置后，清除全局缓存。

```sh
xmake g -c
xmake f -c
```

参考：

- 显示找不到 Microsoft Visual Studio (x64) version
  - https://github.com/xmake-io/xmake/issues/770
  - https://github.com/xmake-io/xmake/discussions/3785
- [xmake can not find visual studio](https://github.com/xmake-io/xmake/issues/2927)
- [XMake无法自动发现MSVC编译工具](https://github.com/xmake-io/xmake/issues/3229)

### 指定 vs 版本

```sh
xmake f --vs=2017 --vs_toolset=14.0 --vs_sdkver=10.0.15063.0
```

### IDE(vscode/vs)不显示头文件

给 target 加上`add_headerfiles("**.h")`

### 终端不支持色彩输出

切换[主题](https://xmake.io/#/zh-cn/theme/builtin_themes)。
```sh
xmake g --theme=plain
```

### 如何在脚本域添加文件

只能在`on_load`添加，并且需要确保路径正确。

因为描述域的`add_files()`和脚本域的`target:add("files")`有一些差异，并不会做路径转换。

后者接口可能会在任何地方使用，所以路径只能用`os.projectdir`或者`os.scriptdir`进行拼接路径。

此外，需要确保该 target 已经应用了一个编译规则，否则不会根据后缀名去添加文件（可能会出现`error: unknown source file: xxx.cpp`）。

比如你在脚本域添加 .cpp 文件，那么首先在描述域添加`add_rules("c++")`。

### 增量配置

假如我们做以下操作：

```sh
xmake f -m debug --test=y
xmake f --test=n
```

你会发现当前`mode`又切换了为默认配置的`release`。

xmake 暂时没有支持增量配置，[这里](https://github.com/xmake-io/xmake/issues/2401)有过相关讨论。

但我们也有解决的方法，使用`SirLynix`写的插件。

```sh
xmake plugin --install https://github.com/SirLynix/xmake-plugins
```

用`xmake config-update`或者`xmake cu`代替原来的`xmake config`或者`xmake f`。

### 在不同脚本域之间传递数据

- `memcache`

```lua
target("foo")
    on_load(function (target)
        import("core.cache.memcache")
        memcache.set("cachename", "key", "value")
    end)

target("bar")
    on_load(function (target)
        import("core.cache.memcache")
        local memcache.get("cachename", "key")
    end)
```

- `target:data()`


```lua
target("foo")
    on_load(function (target)
        target:data_set("key", "value")
    end)

target("bar")
    on_load(function (target)
        import("core.project.project")
        local foo = project.targets()["foo"]
        local value = foo:data("key")
    end)
```

- 单个脚本文件

```lua
target("foo")
    on_load(function (target)
          import("load_module").load_foo(target)
    end)

target("bar")
    on_load(function (target)
          import("load_module").load_bar(target)
    end)
```

`load_module.lua`

```lua
function load_foo(target)
    _g.key = "value"
end

function load_bar(target)
    local value = _g.key
end
```

参考：

- https://github.com/orgs/xmake-io/discussions/3926

## 自动化

### 如何一键编译运行

2.8.3 版本以前：

在 target 下加入以下代码：

```lua
before_run(function (target)
    os.execv("xmake build " .. target:name())
end)

-- xmake run target
```

2.8.3 版本以后：

```sh
$ xmake g --policies=run.autobuild
```

### vs 工程

- 自动更新 sln。

```lua
add_rules("plugin.vsxmake.autoupdate")
```

- 使用`add_filegroups`可以打平嵌套过深的目录树，可读性更高。

### 单元测试

2.8.4 版本后官方支持单元测试，具体例子看：https://github.com/xmake-io/xmake/issues/3381

以前的版本可以考虑这样写：

```lua
rule("module.test")
    on_load(function (target)
        if not has_config("test") then
            target:set("enabled", false)
            return
        end

        target:set("policy", "build.warning", true)
        target:set("rundir", "$(projectdir)")
        target:set("group", "test")
        -- 选择你想要的单元测试库
        target:add("packages", "gtest")
    end)
rule_end()

add_rules("module.test")
-- 假设 test 目录下每个 cpp 文件都有自己的 main 函数
for _, file in ipairs(os.files("test/*.cpp")) do
    local name = path.basename(file)

    target("test." .. name)
        set_kind("binary")
        add_files(file)
    target_end()
end
```

然后我们使用下面命令：

```sh
xmake f -m debug --test=y
xmake build -g test
xmake run -g test
```

如果想一行`xmake test`命令搞定，使用`task`。

```lua
task("test")
    on_run(function ()
        os.exec("xmake f -m debug --test=y")
        os.exec("xmake build -g test")
        os.exec("xmake run -g test")
    end)

    set_menu{}
```

### 自定义检测行为

xmake 在检测各种工具、配置等等信息时都会有缓存，我们可以自定义一个检测行为并对其缓存。

```lua
on_config(function (target)
    import("core.cache.detectcache")
    local has_deprecated_key = "custom.has_deprecated"
    local has_deprecated = detectcache:get(has_deprecated_key)
    if not has_deprecated then
        has_deprecated = target:check_csnippets({
            has_deprecated = [[
            #define TEST __declspec(deprecated)
            int somefunc() { return 0; }
            int main() { return somefunc();}
        ]]
        })
        detectcache:set(has_deprecated_key, has_deprecated)
        detectcache:save()
    end
    -- has_deprecated is now cached
end)
```

## 包管理

### 依赖同一个包多个版本

有依赖包 A 和 B，A 包依赖 1.0.0 版本的 C 包，B 包依赖 1.1.0 版本的 C 包，如果继续编译的话，可能会链接失败，解决方法就是打平依赖，只依赖 C 包同一个版本。

```sh
add_requireconfs("B.C", {version = "1.0.0", override = true})
```

这里把 C 包统一到 1.0.0 版本。

参考

- https://github.com/xmake-io/xmake/issues/3868
- https://github.com/orgs/xmake-io/discussions/2220

### vcpkg 包不会自动处理依赖

暂时不支持，最好去用官方包

参考

- https://github.com/xmake-io/xmake/issues/3634

### 如何调试包源码

xmake 早期是保留源码的，但每次安装都保留源码和编译产物，容易把磁盘用满，所以现在优化了，不再保留。

```sh
# -d 指定源码覆盖安装，本地源码调试包
xrepo install -m debug -d package_sourcedir xxx
```

### 有些远程包为什么没有拉预编译版本

众所周知 c++ 编译器编译出的二进制有 abi 问题，同一个编译器**不同版本**都可能不兼容，所以当预编译库的编译器版本（github ci 编译）和本地编译器版本**不一致**的时候，会拉取源码进行编译。

有些库很大，编译需要很久，可以考虑下面方案：

- 比较推荐通过`set_base("package")`继承包，然后覆盖包的一些设置，跳过 xmake 的检查直接[安装二进制包](https://xmake.io/#/zh-cn/package/remote_package?id=%e5%ae%89%e8%a3%85%e4%ba%8c%e8%bf%9b%e5%88%b6%e5%8c%85)。这里可能需要对 xmake 有一定的基础，不过完成后都是自动化，这是值得的。

- 手动下载预编译包到本地包仓库

假设预编译包目录和`xmake.lua`同一个目录，使用`on_fetch`进行配置。

这里拿 [glfw](https://github.com/glfw/glfw/releases) 作为参考。

我这里下载并解压了`glfw-3.3.8.bin.WIN64.zip`，然后在`xmake.lua`这样写：

```lua
-- 演示操作，不一定正确
package("glfw")
    on_load(function (package)
        -- set package dir
        package:set("installdir", path.join(os.scriptdir(), "glfw-3.3.8.bin.WIN64"))
    end)

    on_fetch(function (package)
        -- add dll
        package:addenv("PATH", package:installdir("lib-vc2022"))

        local result = {}
        if is_plat("windows") then
            result.syslinks =  {"user32", "shell32", "gdi32"}
        end

        result.links = {"glfw3", "glfw3_mt", "glfw3dll"}
        result.includedirs = package:installdir("include")
        result.linkdirs = package:installdir("lib-vc2022")
        return result
    end)
package_end()
```

使用：

```lua
set_runtimes("MD")
add_requires("glfw")

target("test")
    set_kind("binary")
    add_files("*.cpp")
    add_packages("glfw")
```

## 其他

### xmake 源码怎么看

有一篇老文章可以看看 -> [xmake 源码架构剖析](https://tboox.org/cn/2017/09/28/xmake-sourcecode-arch/)

### 定制 api

参考一下这个 pr 是怎么写的：[Add set_encodings api to set source/target encoding](https://github.com/xmake-io/xmake/pull/4019)
