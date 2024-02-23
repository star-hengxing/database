---
title: "Xmake 新手教程"
date: 2023-06-30
lastmod: 2023-08-21
draft: false
tags:
    - C++
    - Xmake
---

构建系统的文档好像都有一个老毛病，就是不太适合新手去阅读（官方教程过于简短）。一些人认为文档写得很混乱，cmake/xmake/meson 都是如此，因此有了这个教程。

> 新手，是指了解 c/c++ 基础的编译链接，并不是对计算机科学（用过至少一门编程语言）一无所知的萌新。

这里还有两份教程可以互相参考。

- [A Tour of xmake 一份非官方的xmake教程](https://www.zhihu.com/column/c_1537535487199281152)
- [xmake从入门到精通1：安装和更新](https://tboox.org/cn/2019/11/09/quickstart-1-installation)

如果想看类似于 meson 的 [How do I do X in Meson?](https://mesonbuild.com/howtox.html) 和 [Frequently Asked Questions](https://mesonbuild.com/FAQ.html)，请看另一篇文章： [Xmake 常见问题解答](https://zhuanlan.zhihu.com/p/611388172)。

xmake 的官方交流群，可以查看[文档](https://xmake.io/#/zh-cn/about/contact)自行添加。

## 安装

这部分[文档](https://xmake.io/#/zh-cn/guide/installation)写得很清楚，在各自的平台用对应的包管理安装即可，另外使用 Windows 系统的读者需要注意两点：

- 自行下载压缩包然后解压到某个目录，确保该目录没有其他东西。

> 曾有人解压到了软件目录，里面有其他软件，然后卸载 xmake 的时候，把其他软件也删了。

- 想通过源码的方式编译安装，需要提前装好一个 xmake，因为 xmake 源码由 c + lua 组成，c 源码需要 xmake 自己编译，也就是"自举"。

打开命令行，输入`xmake --version`验证一下是否正确安装。

## Hello world

这里先介绍怎么编译一个 hello world 工程。

打开命令行，输入`xmake create hello`，用 xmake 生成自带的 hello world 模板。

```sh
$ xmake create hello
create hello ...
  [+]: src/main.cpp
  [+]: xmake.lua
  [+]: .gitignore
create ok!
```

假如你已经安装好了 c/c++ 编译器（msvc/gcc/clang），我们可以直接编译运行，并看到打印出了 hello world。

```sh
$ cd hello
$ xmake
$ xmake run
hello world!
```

> 在 Windows 上，请不要在 git 自带的终端上执行 xmake 命令，可以选择使用 cmd 或 powershell，或者在执行 xmake 命令前，先指定目标平台：`xmake f -p windows`。

在 Linux 上，xmake 默认编译器是 gcc ，Windows 则是 msvc。clang 在两个平台都可以使用，我们可以在命令行切换工具链进行编译。

```sh
$ xmake f --toolchain=clang
$ xmake
$ xmake run
hello world!
```

## 编码

现在最基本的编译已经完成了，但我们怎么写代码呢？这里介绍几个常用的文本编辑器。

### Visual Studio

下面命令会生成 sln 工程，点开后和平时使用 vs 写代码一样。

```sh
xmake project -k vsxmake -m "debug,release"
```

### Visual Studio Code

vscode 是 xmake 支持度最高（vscode 插件比较好开发）的编辑器，只需要安装 xmake 插件，然后挑选一个你喜欢的 intellisense 插件即可。

假如你使用 clangd + codelldb（clangd 是语法提示/补全工具，codelldb 是调试工具），因为 xmake 插件默认在 .vscode 目录下生成 compile_commands.json，那么只要在`.vscode/settings.json`写下：

```json
{
    "clangd.arguments": [
        "--compile-commands-dir=.vscode",
    ],

    "xmake.debugConfigType": "codelldb",
}
```

这时候点开 src/main.cpp 文件，clangd 会自动运行，vscode 算是配置完成了，是不是很简单。

如果想用 cpptools（微软的 c++ 插件），请参考[文档](https://xmake.io/#/zh-cn/plugin/more_plugins)

官方演示视频：

- https://www.bilibili.com/video/BV1sF411E7DA
- https://www.youtube.com/watch?v=yAYYuXmPXPc

### Clion

目前来说，clion 的 xmake 插件是不可用状态，只能靠生成 cmakelists 来支持 clion。

```sh
xmake project -k cmakelists
```

### 其他

没介绍的文本编辑器请看[文档](https://xmake.io/#/zh-cn/plugin/builtin_plugins)。此外，一个小众的国产 c/c++ 编辑器 [edx](https://gitee.com/scu319hy/edx) 也支持了 xmake，可以玩玩。

## Hello world 模板解析

部署了开发环境，回顾一下刚刚的生成的 xmake.lua。

```lua
add_rules("mode.debug", "mode.release")

target("hello")
    set_kind("binary")
    add_files("src/*.cpp")
```

工程需要至少一种构建类型（build type），常见的有 debug/release，可以通过`xmake f -m <build type>`切换构建类型。

`add_rules("mode.debug", "mode.release")`使用了 xmake 内置的编译参数，也就是说，xmake 帮我们写好了这些代码。

```lua
if is_mode("debug") then
    set_symbols("debug")
    set_optimize("none")
elseif is_mode("release") then
    set_symbols("hidden")
    set_optimize("fastest")
    set_strip("all")
    add_cxflags("-DNDEBUG")
end
```

通过判断构建类型，设置了不同的参数。

- symbols -> 设置生成符号信息，这样才可以调试我们的程序，hidden 表示符号不可见。
- optimize -> 优化等级（等级越高，程序运行越快），none 表示不需要优化。
- strip -> 去掉符号，all 表示链接的时候，strip 掉所有符号，包括调试符号。
- cxflags -> 给 c/c++ 添加编译选项，`-DNDEBUG`就是塞了一个`NDEBUG`宏

除了构建类型，工程还需要至少一个构建目标（target），`target("hello")`代表新建一个目标，并命名为 hello。后面所有的设置，都只会对这个目标生效。目标类型可以是静态库（static），也可以是动态库（shared），当然最常见的是可执行程序（binary），对应上面的 xmake.lua 就是`set_kind("binary")`。

> 除了上面这三种类型，[set_kind](https://xmake.io/#/zh-cn/manual/project_target?id=targetset_kind) 还支持 phony/object/headeronly 类型。

add_files 是一个很强大的接口，这里只简单介绍，详细可以去看[文档](https://xmake.io/#/zh-cn/manual/project_target?id=targetadd_files)。

`*`是通配符，可以根据文件后缀匹配一批符合要求的文件。

- `*` -> 在目录内添加文件。假如 src 目录下有 hello.cpp 和 world.cpp 文件，`add_files("src/*.cpp")`只会把 hello.cpp 和 world.cpp 添加进去。

```sh
- src
  - hello.cpp
  - world.cpp
- xmake.lua
- main.cpp
```

- `**` -> 递归目录添加文件。假如 src 目录下有 hello.cpp，src 目录下还有一个 tmp 目录，里面有一个 world.cpp 文件，`add_files("src/**.cpp")`还是只会把 hello.cpp 和 world.cpp 添加进去。

```sh
- src
  - hello.cpp
  - tmp
    - world.cpp
- xmake.lua
- main.cpp
```

## 命令行解析

在上面我们用到了许多命令，比如`xmake f -m debug`，其实完整命令如下：

```sh
xmake config --mode=debug
```

一个工程需要先配置（config）后构建（build），在**新**工程中，直接执行`xmake`命令，代表使用**默认配置**直接构建。

`xmake --help`可以输出 xmake 的命令行操作。

```sh
xmake v2.7.9+HEAD.c87922676, A cross-platform build utility based on Lua
Copyright (C) 2015-present Ruki Wang, tboox.org, xmake.io
                         _
    __  ___ __  __  __ _| | ______
    \ \/ / |  \/  |/ _  | |/ / __ \
     >  <  | \__/ | /_| |   <  ___/
    /_/\_\_|_|  |_|\__ \|_|\_\____|
                         by ruki, xmake.io

    👉  Manual: https://xmake.io/#/getting_started
    🙏  Donate: https://xmake.io/#/sponsor


Usage: $xmake [task] [options] [target]

Build targets if no given tasks.

Actions:
    b, build             Build targets if no given tasks.
    u, uninstall         Uninstall the project binary files.
    i, install           Package and install the target binary files.
    q, require           Install and update required packages.
    p, package           Package target.
    c, clean             Remove all binary and temporary files.
    f, config            Configure the project.
       service           Start service for remote or distributed compilation and etc.
       update            Update and uninstall the xmake program.
    r, run               Run the project target.
       create            Create a new project.
    g, global            Configure the global options for xmake.

...
```

在 Actions 中，最常用的是`config/build/run`。输入`xmake config --help`，则会打印子选项更多操作。

> 本文大多数命令使用简写。

### 通用操作

- `-h|--help` -> 帮助信息。
- `-v|--verbose` -> 输出更多的信息。在构建时使用这个命令，可以看到 xmake 调用编译器的每一步。
- `-D|--diagnosis` -> 通常用于调试 xmake 本身。

> 这些简写通常可以合并在一起操作，比如`xmake -vD`。

### action 常用操作

- `xmake f -c` -> 清除当前 xmake 工程的缓存。当你遇到了无法解决的问题，可以先来一发这个命令。
- `xmake f -p mingw` -> 指定构建目标平台。在 Windows 系统上默认平台是 `windows`，想要在 mingw/msys2 平台编译，需要手动切换。
- `xmake f -P ../projectdir -o ../build` -> 把工作目录和构建目录放在其他地方。保持源码目录整洁，适合洁癖。

```sh
- build (generated)
- workdir
  - .xmake (generated)
- projectdir
  - src 
  - xmake.lua
```

- `xmake build -r` -> 重新编译整个工程，`xmake build -r target`则是重新编译指定 target。
- `xmake build -j4` -> xmake 默认多线程（根据 cpu 核心数）编译跑满 CPU 所有核心，`-j4`调整并行编译任务数，。

> 当工程 config 后，`xmake -r`和`xmake -j4`和上面是完全等价的。

- `xmake run -d target` -> 启动调试器调试指定 target。

## 包管理

xmake 的包管理十分强大，除了自动下载依赖库源码编译安装，还可以使用其他包管理的库。

包可以分类为系统库和非系统库，系统库是最稳定的，但基本是版本固定的预编译二进制，不太灵活。而非系统库直接拉取源码编译，可以最大化自定义操作（比如调整编译参数、只启用包的某个组件等）。

### 使用

修改一下 hello world 模板。这里使用了一个比较知名的库（已经加入了 c++20 标准库）。

```lua
add_rules("mode.debug", "mode.release")

add_requires("fmt")

target("hello")
    set_kind("binary")
    add_files("src/*.cpp")
    add_packages("fmt")
```

引入 fmt 库就这么简单，只需要`add_requires`和`add_packages`。然后执行：

```sh
xmake f -y
xmake
```

> 如果不使用`-y`，那么下载依赖的时候需要手动确认。

依赖下载在 config 阶段，只有正确编译测试包才算成功安装。如果想知道下载编译安装的全过程，可以使用`xmake f -vD`。

> 由于不可描述原因，源码可能会下载失败，请根据[文档](https://xmake.io/#/zh-cn/package/remote_package?id=%e8%ae%be%e7%bd%ae%e4%bb%a3%e7%90%86)为 xmake 挂上代理。

### 系统库

系统库通常都是从系统官方包管理（apt/pacman/homebrew）下载的包。默认情况下 xmake 会先去找系统库，如果没有才下载远程包，基本上只有在非 Windows 平台才需要考虑是否使用系统库，我们也可以通过`add_requires`传入参数强制 xmake 使用系统库。

```lua
add_requires("zlib", {system = true})
```

我们也可以直接指定想用的系统包。

```lua
add_requires("brew::zlib", {alias = "zlib"})
add_requires("pacman::zlib", {alias = "zlib"})
add_requires("pkgconfig::zlib", {alias = "zlib"})
-- 第三方包管理
add_requires("vcpkg::zlib", {alias = "zlib"})
add_requires("conan::zlib", {alias = "zlib"})
```

> 设置了 alias，我们只需要`add_packages("zlib")`而不是`add_packages("brew::zlib")`。

在 Windows 平台，有些库需要使用它的预编译二进制进行开发，如 cuda/vulkansdk/qt。执行`xmake f -h`，可以看到 qt 和 cuda 是可配置选项，可以直接用`xmake f --qt=`或者`xmake f --cuda=`指定 sdk 目录。

但选项中没有 vulkansdk，因为 cuda/qt 是 c++ 大生态的一部分，xmake 内部都对此做了支持。这种情况下，执行`xrepo search vulkansdk`查找包。如果搜索结果显示有这个包，那就和上面引入 fmt 库操作一样。

> `xrepo search <package>` 基于包名和包描述模糊搜索，如果想用的包搜不到，大概率是 xmake 官方还没有支持这个库，可以尝试提 pull request 贡献或者 feature request 的 issue。

如果显示安装`vulkansdk`失败，可以去提 issue 或者自行排除错误。因为 Windows 平台上的系统包通常都是基于环境变量和注册表来查找 sdk 目录，然后提取头文件和库目录。这些环境变量和注册表时在官方安装器安装时设置的，如果下载的是便携版（压缩包解压开箱即用），那么需要自己去设置环境变量等操作。

> xrepo 是 xmake 包管理的名字，类似于 meson 的 wrap。如果你查看 xrepo 的脚本，发现实质上还是调用 xmake。

### 非系统库（远程依赖）

[xmake-repo](https://github.com/xmake-io/xmake-repo) 是 xmake 的官方包管理仓库，上面存放的是各种包的编译脚本。

- 大多数包是从 github 上下载，其他包管理也是这么做。
- 大多数包都是下载源码**本地**编译安装，小部分是下载预编译二进制。如果在 config 阶段卡住了，那基本上都是卡在编译阶段。
- 需要编译的包，大多数是用库自己的构建系统（cmake/meson/makefile）来进行构建，然后把 bin/lib/include 安装到 xmake 指定的位置，这像是包了一层胶水。如果库构建失败，xmake-repo 的打包者则会尝试使用 xmake 来构建此库。
- 包的存放路径可以执行`xmake show`查看`packagedir`，基本上都是按这种规范存放：

```
- f
  - fmt
    - version
      - hash
        - bin -> .dll/.exe
        - lib -> .lib/.a
        - include -> .h/.hpp
```

- 可以通过改变 xmake 的[环境变量](https://xmake.io/#/zh-cn/guide/configuration?id=%e7%8e%af%e5%a2%83%e5%8f%98%e9%87%8f)来切换包的存放路径。

xmake 支持改变包的编译配置。比如包默认是静态库，我们可以传入 configs 使其编译成动态库。

```lua
add_requires("zlib", {configs = {shared = true}})
```

我们还可以传入 debug/pic/lto/vs_runtime 等 configs，这些都是 xmake **内置**的 configs。

而在 c/c++ 生态中，每个包都会有自己的编译选项。fmt 是一个头文件库，他支持**非头文件**的方式编译，那么可以传入对应 configs 来编译成动态库。

```lua
add_requires("fmt", {configs = {header_only = false, shared = true}})
```

正因为包可以用不同 configs 来编译，所以 xmake 会对这些 configs 生成唯一 hash，这也是为什么同一个包同一个版本，还会有多个编译产物。

想了解对应包更多的 configs 选项，执行`xrepo info <package>`。

### 其他

xmake 的包管理还有许多功能，比如指定包的[不同版本](https://xmake.io/#/zh-cn/package/remote_package?id=%e8%af%ad%e4%b9%89%e7%89%88%e6%9c%ac%e8%ae%be%e7%bd%ae)，版本可以精确到 git tag/branch/commit，还有适合内部开发的[自建包仓库](https://xmake.io/#/zh-cn/package/remote_package?id=%e4%bd%bf%e7%94%a8%e8%87%aa%e5%bb%ba%e7%a7%81%e6%9c%89%e5%8c%85%e4%bb%93%e5%ba%93)，更多功能可以看这篇文章：[Xmake 和 C/C++ 包管理](https://zhuanlan.zhihu.com/p/479977993)。

## 编写 xmake.lua

在介绍完一些基础的操作后，本文开始讲解各种基础用法。

### 规范

xmake.lua 基于 lua 编程语言，所有语句必须符合 lua 的语法。

正如其他构建系统一样，文档上各种 api 其实就是 xmake 自定义的 dsl(Domain-specific language)，方便用户使用。虽然有很多人讨厌 lua，但实际上，我们有 80% 的时间在使用 xmake 的 dsl 写描述文件，20% 的时间才可能用到 lua 进行编程。

如果有 xmake 的 dsl 不能完成的操作，我们完全可以退化到用 lua 来完成，对比使用其他构建系统的 dsl 进行编程，lua 写起来不至于那么讨厌了。

xmake 的 api 基于官方指定的[命名规范](https://xmake.io/#/zh-cn/manual/specification)，非常容易理解，比如接口末尾有`s`代表可以传入至少两个参数。

### 作用域

假设我们的工程目录长这样：

```
- demo
  - include
    - base.hpp
  - src
    - base
      - base.cpp
    - sandbox
      - main.cpp
  - xmake.lua
```

编写对应的 xmake.lua。

```lua
add_rules("mode.debug", "mode.release")

add_requires("fmt")
add_includedirs("include")

target("base")
    set_kind("static")
    add_files("src/base/*.cpp")

target("sandbox")
    set_kind("binary")
    add_files("src/sandbox/*.cpp")
    add_packages("fmt")
```

相比 hello world 模板，我们使用了`add_includedirs`来添加头文件的**目录**，并声明了两个 target，其中一个 target 类型是静态库，另一个是可执行程序。

在 base.cpp 编码的时候，你会发现引用不了 fmt 头文件，上面讲过：

> 声明新目标后，后面所有的设置都只会对这个目标生效。

在这里修正一下：声明新目标后，我们就进入了该目标的描述域，所有的设置只会对这个 target 生效。

那在 target 之外就是全局作用域了。

把`add_packages("fmt")`放在`add_requires("fmt")`语句后面，也就是放到全局作用域，为所有 target 都添加了 fmt 的依赖，就能在任何 cpp 文件引用 fmt 头文件了。

```lua
add_requires("fmt")
-- 在全局作用域设置
add_packages("fmt")
add_includedirs("include")
```

`add_rules`和`add_includedirs`这些接口同理，所以所有 target 都享受到了同样的配置，都能引用 base.hpp 这个头文件。

### 多级配置

修改一下工程。

```
- demo
  - include
    - base.hpp
  - src
    - base
      - base.cpp
      - xmake.lua
    - sandbox
      - main.cpp
      - xmake.lua
  - xmake.lua
```

编写对应的 xmake.lua。

- `demo/xmake.lua`

```lua
add_rules("mode.debug", "mode.release")

add_requires("fmt")
add_includedirs("include")

includes("src/base", "src/sandbox")
```

- `demo/src/base/xmake.lua`

```lua
target("base")
    set_kind("static")
    add_files("*.cpp")
```

- `demo/src/sandbox/xmake.lua`

```lua
add_packages("fmt")

target("sandbox")
    set_kind("binary")
    add_files("*.cpp")
```

我们使用了一个新接口`includes`，这个接口可以添加 xmake 的 lua 脚本，也可以添加 xmake 的子配置文件（文件名必须为`xmake.lua`）。同时我们写了两个 xmake.lua，这样就可以模块化描述工程。因为`add_files`是基于配置文件的**位置**来转换文件路径，所以直接用`*.cpp`匹配当前 xmake.lua 目录内的文件。

在 base.cpp 编码的时候，你会发现又引用不了 fmt 头文件。这是因为`add_packages("fmt")`只配置了`demo/src/sandbox/xmake.lua`内的 target，也就是说，只是个**局部配置**。

但 base 和 sandbox 依然享受到了`add_rules("mode.debug", "mode.release")`和`add_includedirs("include")`的配置，这是因为两个**子配置文件**继承了**根配置文件**的配置。

> 由于作用域的限定，子配置文件只能继承了根配置文件中全局作用域里的配置。

这类似于一颗多叉树，根节点的配置可以传播给叶节点，但叶节点的配置只能自己用或者继续向下传播，无法向上传播。

```
        xmake.lua
      /           \
base/xmake.lua  sandbox/xmake.lua
```

### 目标依赖

保持工程目录，修改 xmake.lua。

- `demo/xmake.lua`

```lua
add_rules("mode.debug", "mode.release")

includes("src/base", "src/sandbox")
```

- `demo/src/base/xmake.lua`

```lua
target("base")
    set_kind("static")
    add_includedirs("include", {public = true})
    add_files("*.cpp")
```

- `demo/src/sandbox/xmake.lua`

```lua
target("sandbox")
    set_kind("binary")
    add_files("*.cpp")
    add_deps("base")
```

我们使用`add_deps`显示指定依赖的 target，这样在构建工程会先构建 base 然后构建 sandbox。

注意，不同 target 内部的 c/c++ 文件还是并行编译的，即使他们有依赖关系。因为 c/c++ 编译流程为：

```
预处理 -> 中间对象 -> 链接
```

所以 target 只有在链接的时候才会有依赖关系（如果有特殊情况，target 不能参与并行编译，为该 target 设置`set_policy("build.across_targets_in_parallel", false)`）。

target 设置的编译链接相关的 api，还会有一个属性（private/interface/public）。

api **默认** private 属性，也就是说设置的配置仅供**自己**使用。interface 反过来，只能给下游**依赖**了自己的 target 使用。

而`public == private + interface`，自己和下游依赖**都能用**。

因为 base 的`add_includedirs`设置了`public = true`，所以 base 和 sandbox 内的 cpp 文件，都可以引用来自 base 的头文件 base.hpp。

### 脚本域

上面讲了那么多，基本上可以应付一些小型项目了。如果有更复杂的需求，就需要到**脚本域**里干活（也就是说，平时都是在**描述域**干活）。

因为 xmake 的特性，描述域的代码需要被扫描多次，而脚本域的代码只会被执行一次。执行`xmake f -c`，可以看见 world 只被打印一次。

```lua
print("hello")

target("test")
    on_load(function (target)
        print("world")
    end)
```

> print 是 xmake 最~~强大~~的调试手段。

在描述域，我们使用 xmake api 添加了各种配置，但有一些 api 只能在脚本域运行，比如在脚本域获取描述域中（任何 add/set api）设置的配置和执行 `ls` 命令。

```lua
target("test")
    add_cxflags("-O3")
    add_defines("Win32")

    on_load(function (target)
        print(target:get("cxflags"))
        print(target:get("defines"))
        os.vrun("ls")
    end)
```

如果在描述域使用 `os.vrun` 会直接报错，只有少部分接口（例如 `print`）才能在描述域和全局作用域使用。

`on_load`只是编写脚本域代码的其中一处，我们还可以在下面每一步编写对应脚本。

```
on_load -> after_load -> on_config -> before_build -> on_build -> after_build
```

- on_config 在`xmake config`执行后，`before_build`执行前的时候运行。
- 如果是 c/c++ 程序，还可以在`[before|on|after]_link`编写脚本。
- 自定义`on_[build|link]`会覆盖 xmake 内置的脚本。

不同构建阶段的脚本基本上可以满足各种定制化需求。

### 规则

规则是 xmake 最强大的工具之一，你可以做到：

- 给不同 target 应用不同的构建参数。

和`add_rules("mode.debug", "mode.release")`一样定制编译参数。

```lua
rule("module")
    on_load(function (target)
        if target:name() == "main" then
            target:add("packages", "fmt")
        end

        local is_test = target:extraconf("rules", "module", "test")
        if is_test then
            target:add("cxflags", "-fsanitize=address")
            target:add("ldflags", "-fsanitize=address")
        end
    end)

target("main")
    add_rules("module")

target("test")
    add_rules("module", {test = true})
```

我们可以通过判断 target 名字是否添加 fmt 包，也可以直接传入配置来判断是该 target 是否需要启用 asan，非常灵活。

- 构建非 c/c++ 编译产物，比如使用 typst 生成 pdf，只需要下面几十行代码。

工程目录。

```
- src
  - resume-zh.typ
- xmake.lua
```

`xmake.lua`

```lua
rule("typst")
    set_extensions(".typ")

    on_load(function (target)
        -- 设置输出文件目录
        target:set("targetdir", path.join("build", "pdf"))
    end)

    on_build_file(function (target, sourcefile, opt)
        -- 导入模块
        import("lib.detect.find_tool")
        import("core.project.depend")
        import("utils.progress")
        -- 创建输出文件目录
        os.mkdir(target:targetdir())
        -- 找到编译器
        local typst = assert(find_tool("typst", {version = true}), "typst not found")
        -- 拼接输出文件路径
        local targetfile = path.join(target:targetdir(), path.basename(sourcefile) .. ".pdf")
        -- 一个封装好的函数，当源文件修改就会重新构建
        depend.on_changed(function ()
            os.vrunv(typst.program, {"compile", sourcefile, targetfile})
            progress.show(opt.progress, "${color.build.object}compiling %s", sourcefile)
        end, {files = sourcefile})
    end)

target("resume")
    set_kind("object")
    add_rules("typst")
    add_files("src/resume-zh.typ")
```

和平常一样执行`xmake`，就可以得到我们的 pdf 文件。

```
[ 33%]: compiling src/resume-zh.typ
[100%]: build ok, spent 0.281s
```

如果没找到编译器，assert 会失败，需要参考[文档](https://xmake.io/#/zh-cn/manual/extension_modules?id=detectfind_tool)进一步学习`find_tool`的用法。

### 调试

获取 xmake 和 xmake-repo 最新版。

```sh
xmake update -s dev
xrepo update-repo
```

清理全局/工程缓存。

```sh
xmake g -c
xmake f -c
```

上面是最基础的调试手段，下面介绍一些需要人工辅助的方法。

- `print`大法。

`print`无论在配置文件哪里都可以使用，`cprint`还可以输出有颜色的 log。除此之外还可以使用`assert`和`raise`。

- 输出调用各种工具操作，编译的详细参数，如果出错还会打印 xmake 的栈回溯。

```sh
xmake -vD
```

> 如果要给 xmake 提 issue 报 bug，请务必使用该命令生成 log 提交上去。

- 可以显示指定 target 配置信息，可以看到各种配置来源于哪个配置文件和具体的行数。

```sh
xmake show -t <target>
```

- 检查工程配置和代码。

```sh
$ xmake check
# 调用 clang-tidy 检测代码
$ xmake check clang.tidy
```

因为 xmake 基本上都是依靠字符串传递各种配置，如果打错参数名（typo）就会导致`xmake config`失败。这个 xmake 插件能检测到 typo （基于 Levenshtein Distance 算法），也能检测各种通过`add_xxx`接口添加的文件/目录，是否匹配文件成功。

> xmake 还有很多有用的插件，多多尝试使用。

## 可能的最佳实践

一个完整的项目，目录结构可能长这样：

```
- src
- xmake
  - rule
    - module.lua
  - option.lua
  - package.lua
  - xmake.lua
- test
  - xmake.lua
  - test1.cpp
  - test2.cpp
- xmake.lua
```

对应的部分配置：

`xmake.lua`

```lua
set_project("name")

set_version("0.0.1")

set_xmakever("2.7.9")

set_warnings("all")
set_languages("c++20")

set_allowedplats("windows", "linux", "macosx")

includes("test", "src", "xmake")
```

`xmake/xmake.lua`

```lua
includes("option.lua")
includes("package.lua")
includes("rule/module.lua")
```

`xmake/option.lua`

```lua
option("test", {default = false, showmenu = true, description = "Enable test"})
option("feature", {default = false, showmenu = true, description = "Enable feature"})
```

可以把构建选项集中在一起（选项在`xmake config`的时候传递`--test=[y/n]`启用或关闭）。

`xmake/package.lua`

```lua
add_requires("fmt")

if has_config("test") then
    add_requires("gtest")
end
```

gtest 库只有在 test 选项启用后才会安装。

### 单元测试

xmake 官方不支持单元测试，[相关讨论](https://github.com/xmake-io/xmake/issues/3381)。

可以参考下面这个单元测试模板。

`xmake/rule/module.lua`

```lua
rule("module.test")
    on_load(function (target)
        -- 没有开启 test 选项，就关闭 target
        if not has_config("test") then
            target:set("enabled", false)
            return
        end
        -- 运行目录修改为根目录
        target:set("rundir", os.projectdir())
        -- 添加测试组
        target:set("group", "test")
        -- 选择你想要的单元测试库
        target:add("packages", "gtest")
    end)
```

`test/xmake.lua`

```lua
add_rules("module.test")
-- 假设 test 目录下每个 cpp 文件都有自己的 main 函数
for _, file in ipairs(os.files("*.cpp")) do
    local name = path.basename(file)

    target("test." .. name)
        set_kind("binary")
        add_files(file)
    target_end()
end
```

首先写了一个名叫`module.test`的 rule，这是给测试 target 添加编译参数。然后使用`os.files`收集文件，遍历目录获取指定文件并生成 target。

然后我们执行命令开启 test 选项并指定 test 组编译运行：

```sh
xmake f -m debug --test=y
xmake build -g test
xmake run -g test
```

如果想一行`xmake test`命令搞定，可以使用[task](https://xmake.io/#/zh-cn/manual/plugin_task)。

```lua
task("test")
    on_run(function ()
        os.exec("xmake f -m debug --test=y")
        os.exec("xmake build -g test")
        os.exec("xmake run -g test")
    end)

    set_menu{}
```

### 库

假如你要写一个库，给别人调用或者自己使用。

因为 xmake 没有类似 c++ namespace 的特性，可能 target/rule/option... 与自己的定义的名字发生冲突。而 xmake 有自己的包管理，只要贡献到 xmake-repo 别人就能使用，所以不推荐使用`includes`集成库。

- include

需要安装的头文件，使用`add_headerfiles`。

```lua
-- 保留头文件目录结构
add_headerfiles("include/(**.h)")
-- 丢弃文件目录结构，所有头文件都放在 include 目录
add_headerfiles("include/**.h")
```

- lib

基于 [build.merge_archive](https://xmake.io/#/zh-cn/guide/project_examples?id=%e5%90%88%e5%b9%b6%e9%9d%99%e6%80%81%e5%ba%93)，对某个 target 使用`set_policy("build.merge_archive", true)`，可以自动合并依赖的所有静态库。这样在发布的时候可以只安装一个静态库。

- bin

在 Windows 上编译动态库，但又不想自己导出符号，可以使用`add_rules("utils.symbols.export_all")`自动导出所有符号（如果是 c++ 库还要给该规则传递参数`{export_classes = true}`）。


- 如果需要安装其他文件，比如文档，使用`add_installfiles("doc/*.md", {prefixdir = "share/doc"})`。
- 导出该库给其他构建系统交互。

```lua
add_rules("utils.install.cmake_importfiles")
add_rules("utils.install.pkgconfig_importfiles")
```

- 想把这个库提交到 xmake-repo 上，还需要写对应的包描述脚本，这里只能参考[文档](https://xmake.io/#/zh-cn/package/remote_package?id=%e6%b7%bb%e5%8a%a0%e5%8c%85%e5%88%b0%e4%bb%93%e5%ba%93)和 xmake-repo 上其他包。

### 软件

如果要发布一个软件，基本上都要重写`on_install`脚本。

- 因为不需要安装头文件，配置`add_headerfiles("src/xxx.h", {install = false})`。因为`add_headerfiles`这个接口不止用来安装头文件，还可以用作 ide 的工程目录显示（也就是说，如果不使用`add_headerfiles`，ide 工程目录只会显示源文件）。
- xmake 内部封装了常用的[压缩工具](https://xmake.io/#/zh-cn/manual/extension_modules?id=utilsarchive)，在`on_install`最后一步可以把所有文件打包成压缩包。

如果想用 upx 压缩也很简单。

```lua
rule("module.program")
    after_build(function (target)
        -- 判断是否使用 upx
        local enabled = target:extraconf("rules", "module.program", "upx")
        if not enabled or target:kind() ~= "binary" then
            return
        end
        local upx = assert(import("lib.detect.find_tool")("upx"), "upx not found!")
        -- 生成在 build 目录里
        local file = path.join("build", path.filename(target:targetfile()))

        os.tryrm(file)
        os.vrunv(upx.program, {target:targetfile(), "-o", file})
    end)
```

使用：

```lua
target("main")
    set_kind("binary")
    add_rules("module.program", {upx = true})
    add_files("*.cpp")
```

我们可以进一步优化这个 rule。

```lua
rule("module.program")
    on_load(function (target)
        target:set("kind", "binary")
    end)

    after_build(function (target)
        local enabled = target:extraconf("rules", "module.program", "upx")
        if (not enabled) or (not is_mode("release")) then
            return
        end

        import("core.project.depend")
        import("lib.detect.find_tool")

        local targetfile = target:targetfile()
        depend.on_changed(function ()
            local file = path.join("build", path.filename(targetfile))
            local upx = assert(find_tool("upx"), "upx not found!")

            os.tryrm(file)
            os.vrunv(upx.program, {targetfile, "-o", file})
        end, {files = targetfile})
    end)

target("main")
    add_rules("module.program", {upx = true})
    add_files("*.cpp")
```

在 target 的描述域中，`set_kind`也不需要写了。通过 `depend.on_changed` 接口，判断依赖文件的修改时间，避免每次重新构建。
