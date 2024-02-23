---
title: "用 vscode 写 UE 代码"
date: 2022-11-25
lastmod: 2022-11-26
draft: false
tags:
    - UE4
    - vscode
---

## 前提

目前来说 Rider 还是最好的 UE IDE，本文只是提供多一种选项来写 UE 代码。

## 环境

- vscode 插件 clangd
- clang

Windows 推荐使用 scoop 下载 clang。
```
scoop install llvm
```

## 部署

1. 用 vscode 打开 UE 项目目录，新建`.vscode`目录。

2. 新建`.vscode/settings.json`文件，写入下面内容。

```json
{
    "clangd.arguments": [
        "--background-index",
        "--compile-commands-dir=.vscode",
        // completion
        "--header-insertion=never",
        "--completion-style=bundled",
        "--function-arg-placeholders=false",
        // effective
        "--pch-storage=memory",
        "-j=16",
        // coding
        "--clang-tidy",
        // misc
        "--log=error"
    ]
}
```

3. 在项目目录新建`.clang-format`文件，谷歌一下 UE clang-format，随便找一个复制下来。这里用来格式化代码。

4. 使用脚本生成反射信息和`compile_commands.json`

> `compile_commands.json`成功生成后，打开 cpp 文件，clangd 就会自动运行。

UE 的 Unreal Build Tool 可以生成`compile_commands.json`，需要 clang 辅助。不过 UBT 写的比较奇葩，在命令行直接`clang -v`有结果，但 UBT 还是找不到，在论坛看了一遍 Linux/Windows 都是这样。

但 Windows 还是能找到 clang 的，不过需要把 LLVM 工具链放在这里。
```
C:/Program Files/LLVM
```
这里建议弄一个目录软链接，或者直接拷贝过来。不会用 mklink 可以看看这篇文章：[比较 Windows 上四种不同的文件（夹）链接方式（NTFS 的硬链接、目录联接、符号链接，和大家熟知的快捷方式）
](https://blog.walterlv.com/post/ntfs-link-comparisons.html)
```powershell
# C:/Program Files/
cmd /c mklink /J LLVM <LLVM_PATH>
```

然后这里需要一个脚本来调用 UBT，可以考虑用 vscode 内置的 tasks，也可也用 python 等脚本语言，假如要用 vsocde tasks：

- 新建文件`.vscode/tasks.json`

假设 UE 目录在 `C:/Program Files/Epic Games/UE_4.27`，新建项目名称为`demo`。
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "type": "shell",
            "label": "Gen Generated Code",
            "group": "none",
            "command": "Engine/Binaries/DotNET/UnrealBuildTool.exe",
            "args": [
                "demoEditor", // <project name>Editor
                "Win64",
                "DebugGame",
                "-SkipBuild",
                "-project=${workspaceFolder}/demo.uproject",
                "-game",
                "-engine"
            ],
            "options": {
                "cwd": "C:/Program Files/Epic Games/UE_4.27"
            }
        },
        {
            "type": "shell",
            "label": "Subtask:GenClangDatabase",
            "group": "none",
            "command": "Engine/Binaries/DotNET/UnrealBuildTool.exe",
            "args": [
                "demoEditor", // <project name>Editor
                "Win64",
                "DebugGame",
                "-SkipBuild",
                "-project=${workspaceFolder}/demo.uproject",
                "-game",
                "-engine",
                "-mode=GenerateClangDatabase"
            ],
            "options": {
                "cwd": "C:/Program Files/Epic Games/UE_4.27"
            }
        },
        {
            "type": "shell",
            "label": "Subtask:MoveCompileCommands",
            "group": "none",
            "command": "move",
            "args": [
                "-Force",
                "compile_commands.json",
                "${workspaceFolder}/.vscode"
            ],
            "options": {
                "cwd": "C:/Program Files/Epic Games/UE_4.27"
            }
        },
        {
            "label": "Gen Compile Commands",
            "group": "none",
            "dependsOn": [
                "Subtask:GenClangDatabase",
                "Subtask:MoveCompileCommands"
            ],
            "dependsOrder": "sequence"
        }
    ]
}
```

## Reference

- [Windows 下使用 Vscode + Clangd 搭建 UE4 开发环境](https://zhuanlan.zhihu.com/p/507625365)
