---
title: "在 Windows 上使用 Xmake 配置 Vulkan 开发环境"
date: 2022-06-20
lastmod: 2022-10-20
draft: false
categories:
    - 计算机图形学
tags:
    - 图形API
---

*也可以是C++小项目的配置*

## 开发环境构建

> vscode+xmake+clang+clangd

如果在配置过程中有问题，可以先看一下文末的**FQA**

### C++编译工具链

- [Visual Studio 2022](https://visualstudio.microsoft.com/vs)
- [clang](https://github.com/llvm/llvm-project/tags)

### 构建系统

[xmake](https://xmake.io)

### Vulkan SDK

[https://www.lunarg.com/vulkan-sdk/](https://www.lunarg.com/vulkan-sdk/)

### 假装IDE的文本编辑器

[Visual Studio Code](https://code.visualstudio.com)

安装插件

- clangd
- XMake

## Getting started

上面列出来的工具下载完成后，新建一个目录，在目录下新建`xmake.lua`，写入下面内容

```lua
set_project("vulkan")

set_arch("x64")
set_warnings("all")
set_languages("c++20")
set_toolchains("clang")

add_rules("mode.debug", "mode.releasedbg", "mode.release", "mode.minsizerel")

add_requires("vulkansdk", "glfw", "glm")

target("main")
    set_default(true)
    set_kind("binary")
    add_files("src/main.cpp")
    add_packages("vulkansdk", "glfw", "glm")
```

依赖的 vulkansdk 在上面已经下载，如果用他的 installer 安装会自动设置环境变量，xmake 会根据环境变量自动探测编译器、vulkansdk 的正确位置，glm 和 glfw 由 xmake 的包管理处理

### 编译

测试代码来自[vulkan tutorial](https://vulkan-tutorial.com/Development_environment)

直接新建一个`main.cpp`，把代码复制下来

一切配置好后，可以测试一下了

```bash
xmake
xmake run
```

出现窗口代表环境配置成功

### Intellisense

xmake会在`.vscode`目录自动生成`compile_commands.json`

所以我们在`.vscode/settings.json`给clangd加上参数

```json
{
    "clangd.arguments": [
        "--compile-commands-dir=.vscode",
        "--header-insertion=never",
        "--completion-style=detailed"
    ]
}
```

## FQA

Q: xmake下载包失败怎么办

A: 查看文档[使用远程包 - xmake](https://xmake.io/#/zh-cn/package/remote_package?id=%e8%bf%9c%e7%a8%8b%e5%8c%85%e4%b8%8b%e8%bd%bd%e4%bc%98%e5%8c%96)



Q: 编译失败怎么办

A: 执行`xmake -v`，查看详细输出信息



Q: 我想用vs写代码怎么办

A: 执行`xmake project -k vsxmake -m "debug,release"`生成vs工程文件