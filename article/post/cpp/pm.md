---
title: "漫谈 C/C++ 包管理"
date: 2024-03-29
draft: false
tags:
    - C++
---

在 r/cpp 一篇[帖子](https://www.reddit.com/r/cpp/comments/16ifo5e/which_package_manager_are_you_using)里，投票选择用什么包管理。出乎意料，但又情理之中：不用包管理的人占大多数。

但既然都是写代码的，相信没人不喜欢自动化吧，难道很喜欢手动拉取源码编译吗。

本文主要面向开源项目，像类似于公司项目，依赖基本上是固定或定制（魔改源码），有完善的自动化脚本，不在此讨论列表。

# 什么是包管理

## 系统包管理 ≠ C/C++ 包管理

> Windows 上 scoop/winget 不算系统包管理，因为打包的库很少。

众所周知，我们用的是 native 语言。那么问题来了，不同的编译参数都会影响最终编译二进制的结果。

而系统包管理的包，编译参数是固定的，下载包都是拉取的预编译二进制。当然也有一些发行版，都是用源码分发软件，但你也不一定能随意定制自己想要的包。

1. 如果想静态链接所有依赖库，不好意思，发行版打包基本都是动态库。

2. 选择版本？大包可能可以，比如 arch 打包的 openjdk，不过也只能选几个出名的版本罢了，但大部分包肯定没这个待遇。

3. 想看崩溃的堆栈？现在有一些发行版确实考虑分发调试信息，但既然是调试了，能直接看到源码不更好吗。

> 有时候写个小玩具验证一下，用系统包管理也可，毕竟是预编译二进制。

## git submodule 只是下载依赖的工具

和 cmake 的 fetch content 一样，自己写一个 sh/bat 脚本来下载依赖也差不多。

而且 git submodule 也有机率用出 bug，比如 eastl 的 [submodule clone](https://github.com/electronicarts/EASTL/issues/410) 永远是失败的，需要手动去目录一个个 clone。

# 为什么需要包管理

## 自动化，爽

## 避免来自依赖库的污染

众所周知，cmake 除了用 find_package 引入依赖，就是 `add_subdirectory` 了。但他有个很大的缺点，会引入依赖库的各种逻辑，比如 `enable_testing`。

所以引入依赖库，最好先编译安装到指定目录，只留下 bin/lib/include，lib 目录下有 .pc/.cmake 等文件来让构建系统获取信息。

## 依赖分析

依赖数量多起来后，就很容易出现循环（菱形）依赖。

这是很常见的现象，而包管理要做的就是报错，然后由用户来选择是否打平依赖。

如果手动去处理这些事情，就会出现这种情况：

- [杂谈：一个 C++ Header-only 版本冲突的案例分析](https://zhuanlan.zhihu.com/p/684965383)
- [assimp](https://github.com/assimp/assimp/blob/feb861f17bf937fd42e0591b3347b95009033eec/code/Common/StbCommon.h) 库使用宏来重命名依赖库 stb 的 api，避免符号冲突。


## 定制包的构建

大部分开发者遇到的常见需求：

- 允许使用系统库进行构建，而不是拉取源码构建
- 编译成**动态**/**静态**库
- **动态**/**静态**链接 c/c++ runtime
- 启用异常/rtti/lto/pic 等功能
- asan（全部代码都得用 asan 编译，否则可能会出现"假阳性"）
- 使用 ninja 作为构建后端，而不是 makefile/msbuild
- 构建 debug 版本包，并保留源码
- C++20 模块包（目前只有 xmake 支持）

以上需求已经满足大部分开源社区的需求了，如果需要进一步定制：

- 传递**编译**/**链接**选项给包
- 指定包版本，比如 master/dev 分支，或者指定某次 commit hash
- **同时使用**同一个包的不同版本，不同的编译选项
- 在 Windows 上，使用 mingw 构建 c 包，然后给 msvc 调用
- 自建包仓库

## 避免造轮子

大部分包拉下来后，很少有直接能成功构建安装的，基本都需要 patch。如果上游包管理已经打好了这个包，那你就不需要去找哪里有 bug 并手动 patch 了。

## 鉴权机制

这是一种比较少见情况，基本只会出现在公司项目。因为有权限机制，代码是不能共享给全部员工的，所以只能以预编译二进制的形式来参与到项目里。那么下载代码的时候，需要根据权限来选择源码或预编译二进制。

# 如何使用包管理

简单对比一下三大包管理：vcpkg/conan/xrepo

## 指定版本

- vcpkg
  - [Tutorial: Install a specific version of a package](https://learn.microsoft.com/en-us/vcpkg/consume/lock-package-versions)

改个版本号，怎么还要看一篇这么长文章？

- conan

```
[requires]
zlib/1.2.11

[tool_requires]
cmake/3.22.6

[generators]
CMakeDeps
CMakeToolchain
```

- xmake

```lua
add_requires("tbox 1.6.*", "libpng ~1.16", "zlib master")
```

xmake/conan 都是一步到位。

## 使用预编译二进制

闭源库，系统包基本都是这个类型。

- vcpkg
  - [Using system package manager dependencies with vcpkg](https://devblogs.microsoft.com/cppblog/using-system-package-manager-dependencies-with-vcpkg)

vcpkg 调用 cmake 的 find_package 去找包，但这个 api，众所周知很**不稳定**。

- conan
  - [How to specify system lib dependency in conanfile.txt / conanfile.py](https://github.com/conan-io/conan/issues/8044)

看起来只能手写包描述。

- xmake

在有系统包管理的 host，默认会先查找系统包获取信息，如果找不到才拉取源码构建。

而预编译二进制，也需要手写[包描述](https://zhuanlan.zhihu.com/p/651108523)。

## 动态/静态库

- vcpkg
  - [How to set vcpkg static for every platform?](https://stackoverflow.com/questions/70807164/how-to-set-vcpkg-static-for-every-platform)
  - [Make Linux dynamic linkage a first class citizen](https://github.com/microsoft/vcpkg/discussions/19127)
  - [Vcpkg updates: Static linking is now available](https://devblogs.microsoft.com/cppblog/vcpkg-updates-static-linking-is-now-available/)

想让全平台统一静态库，还要设置三元组？看起来很麻烦。

- conan

```
[requires]
tool_a/1.0@myuser/stable

[generators]
cmake

[options]
tool_a:shared=True

[imports]
bin, *.dll -> ./bin # Copies all dll files from packages bin folder to my "bin" folder
lib, *.dylib* -> ./bin # Copies all dylib files from packages lib folder to my "bin" folder
lib, *.so* -> ./bin # Copies all so files from packages lib folder to my "bin" folder
```

看起来很简洁。

- xmake

全平台默认构建静态库，想要使用动态库就要声明：

```lua
add_requires("zlib", {configs = {shared = true}})
```

## 调包失败

C/C++ 项目也是众所周知的难构建，即便你有几十年编程经验，但面对构建，免不了踩一堆坑。

但很多刚接触包管理的人，想调几个包，然而构建失败了，就觉得，你这玩意太垃圾了，然后就不用了。

包管理的维护者不是神，无法预知到每一个 corner case，只能查看编译失败的 ci，一遍遍地打 patch 使其通过。

你能做到的就是，提个 issue，把构建失败的 log 和你的开发配置等信息都留下，然后考虑使用另一个包管理或者手写**包描述**。
