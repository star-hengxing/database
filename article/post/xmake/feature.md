---
title: "Xmake 插件介绍"
date: 2024-03-05
draft: false
---

本文只会讲一些比较实用的插件，其余插件请看[文档](https://xmake.io/#/zh-cn/plugin/builtin_plugins)。

# 生成工程文件

除了 cmake，其他构建系统（构建后端）支持力度一般，不保证能构建成功。

如果 ide 不支持 xmake 而支持 cmake，可以生成 cmakelists 来使用。

```sh
$ xmake project -k cmakelists
$ xmake project -k makefile
$ xmake project -k ninja
```

> 当然你也可以参考这些文件来学习 cmake/makefile/ninja 怎么写。

xmake 有两种生成 Visual Studio 工程文件的方式。

```sh
$ xmake project -k vsxmake -m "debug,release"
$ xmake project -k vs2022 -m "debug,release"
```

前者依然使用 xmake 构建，但可以用 vs 作为编辑器和调试器。后者则是生成 msbuild 文件，该方式已经不再维护。

# 运行 lua 脚本

查找系统包和 hash 文件。

```sh
$ xmake l find_package pkgconfig::xxx
$ xmake l find_package pacman::xxx
$ xmake l find_package brew::xxx
$ xmake l hash.sha256 xxx
```

有些比较大的项目可能会提供 setup.lua 脚本。

```sh
$ xmake l setup.lua
```

这是一种好的实践。因为 xmake 内部库种类丰富，完全可以不用写 sh/bat 来跨平台。

# 定位配置信息

我们可以看到 target 的 cxflags/ldflags/includedirs 等配置信息在哪个 xmake.lua:行。

```sh
$ xmake show -t <target>
```


# 自动编译运行

```sh
$ xmake f --policies=run.autobuild
$ xmake watch
```

使用该插件，当写好代码，保存文件，就会自动触发编译运行，比手动 `gcc main.cpp -o main && ./main` 舒服多了。

# 调试 xmake.lua

xmake 即使用了 lua，但大部分配置还是基于字符串，很容易出现 typo 导致构建失败，于是提供了该插件。

```sh
$ xmake check
```

# 宏

某种意义上的 `CMakePresets.json`。