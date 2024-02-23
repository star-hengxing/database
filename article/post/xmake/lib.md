---
title: "使用 Xmake 生成静态和动态库"
date: 2023-01-04
lastmod: 2023-01-21
draft: false
tags:
    - C/C++
    - Xmake
---

## 前言

- 当前环境在 Windows，默认了解 C/C++ 编译流程。
- 不一定是最佳实践。

## 静态库

target 下直接考虑用`set_kind("static")`即可。

有一个可以注意的地方，可以使用`set_policy("build.merge_archive", true)`来合并所有静态库。（大概是用在分发二进制的时候？）

## 动态库

考虑到 windows dll 要在函数声明`__declspec(dllexport)`导出接口（也可以用`.def`文件）。

手动给每个符号声明很麻烦，需要 build system 来自动化。

xmake 对此做了支持，只需要在 target 下添加：
```lua
-- C
add_rules("utils.symbols.export_all")
-- C++
add_rules("utils.symbols.export_all", {export_classes = true})
```

就会生成正确 dll 文件了。

如果想要自定义导出符号，使用[utils.symbols.export_list](https://xmake.io/#/zh-cn/manual/custom_rule?id=utilssymbolsexport_list)。

## 直接配置

假设`test`目录下是一个库，把上面静态库和动态库的用法结合起来：
```lua
add_includedirs("include", {public = true})

target("add")
    set_kind("$(kind)")
    add_files("src/add.cpp")

    if is_kind("shared") and is_plat("windows") then
        add_rules("utils.symbols.export_all", {export_classes = true})
    end

target("sub")
    set_kind("$(kind)")
    add_files("src/sub.cpp")

    if is_kind("shared") and is_plat("windows") then
        add_rules("utils.symbols.export_all", {export_classes = true})
    end

target("test")
    set_kind("$(kind)")
    add_files("src/test.cpp")
    add_deps("add", "sub")

    if is_kind("shared") and is_plat("windows") then
        add_rules("utils.symbols.export_all", {export_classes = true})
    elseif is_kind("static") then
        set_policy("build.merge_archive", true)
    end
```

使用不同类型的库只要`xmake f -k shared/static`就行了。

## 使用规则

上面只是临时用法，实际在工程中，我推荐使用规则。下面代码和上面效果是一样的。

```lua
rule("module")
    on_load(function (target)
        if is_mode("debug", "releasedbg") then
            target:set("kind", "shared")
            if is_plat("windows") then
                import("core.project.rule")
                local rule = rule.rule("utils.symbols.export_all")
                target:rule_add(rule)
                target:extraconf_set("rules", "utils.symbols.export_all", {export_classes = true})
            end
        elseif is_mode("release") then
            target:set("kind", "static")
        else
            assert(false, "Unknown build kind")
        end
    end)
rule_end()
```

- 开发时(debug mode)，全编译为动态库，加速链接。
- 发布时(release mode)，全编译为静态库，生成单个可执行程序文件。

使用：

```lua
target("test")
    set_kind("$(kind)")
    add_files("src/test.cpp")
    add_deps("add", "sub")
    add_rules("module")
```
