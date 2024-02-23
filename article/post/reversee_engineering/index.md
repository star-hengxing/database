---
title: "逆向工程"
date: 2022-01-29
draft: false
tags:
    - 逆向工程
---

自学怎么说呢，我也在摸索，不过我认为先做一下CSAPP的bomb lab比较好

## bomb lab
`逆向汇编破解程序`

这个作业怎么下载还有工具自己找吧，都很容易获取

可能要用到的东西
- gdb
- x86指令文档

我研究的时候是边做边学，打断点，单步看汇编，不懂的指令/寄存器现场查

## tools

- 强大的工具
    - ghidra
    - ida
    - gdb
- 十六进制编辑器
    - bless
- 十六进制查看
    - hexyl(跨平台/终端彩色输出)
- 解包
    - arc_unpacker
    - crass

# Reference
1. [逆向工程入门简述](https://jay-dh.github.io/blog/reverse-engineering-summary)
2. [汇编语言简述(逆向工程)](https://jay-dh.github.io/blog/reverse-engineering-asm)