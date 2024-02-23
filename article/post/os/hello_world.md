---
title: "裸机运行Hello world"
date: 2021-10-12
lastmod: 2021-10-29
draft: false
tags:
    - 操作系统
---

## 前置知识

- 编译链接到可执行程序一系列流程
- x86架构的一些寄存器
- elf头
- 下面工具的使用

## 环境配置

os: Linux

可能会用到的工具:
- gcc(编译)
- ld(链接)
- objcopy(提取二进制)
- dd(写入虚拟镜像)
- gdb(调试)
- make(自动化构建)
- qemu(虚拟机)

大部分linux发行版都会自带大部分工具，自行安装最新版本即可

## 基本介绍

目标是实现一个不依赖操作系统就能运行的二进制程序，在虚拟机屏幕显示hello world

计算机启动，按下电源开关通电启动bios，检查硬件，没啥问题的话，bios会加载该储存设备第一个扇区的512字节(MBR)到物理内存0x7C00

如果扇区最后两个字节是0x55和0xAA，那么说明是启动设备，否则bios会跳过该扇区

如果装过系统的话，会发现这就是BIOS+MBR传统启动计算机方式，而现在比较“先进”的方式是UEFI启动

最后bios使用命令jmp 0x7c00跳到我们代码，我们旅程就这样开始了

## 实现

### coding

汇编大体上两种语法，intel和AT&T，这里选择AT&T，如果是用intel语法，可以去找nasm等汇编器编译

附上两个伪指令，表明是16位代码和程序开头在main

	.globl main
    .code16

然后设置段寄存器为零，异或清零是常用的手法。为什么要清零，因为此时cpu在实模式下(real mode)，物理内存寻址是采用 段：偏移，计算方式如下

物理地址 = 段 * 16 + 偏移

如果我们直接设零，那么偏移量直接等于物理地址

	xorw %ax, %ax
	movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss

因为现代操作系统是分页管理内存，段管理内存已经不再使用，但有时候他会以某种方式出现我们眼前

比如：平时写C/C++程序遇到的*Segmentation fault*

如何在屏幕上输出字符串呢，答案是使用bios中断

bios中断没必要深究，当成api使用即可，使用方法就是在指定寄存器赋值，然后使用**int**指令和对应中断号

这里看[0x10中断指令](https://en.wikipedia.org/wiki/INT_10H)的用法

中断返回后，可以看到字符串按照我们的格式输出在屏幕上

### 编译

这里我们使用make来管理编译流程

gcc/ld/objcopy/dd等使用方法参考我的makefile

1. 编译汇编源文件为.o文件
2. 指定程序入口函数和地址，链接成elf文件
3. 将elf文件中代码和数据提取成纯二进制文件

然后使用dd拼接512字节的MBR

1. 生成全为零的512字节文件
2. 开头刻录我们的二进制文件
3. 最后两个字节刻录魔数

这里使用其他工具或python脚本也可以完成

### 运行

	qemu-system-x86_64 -no-shutdown -no-reboot -m 128M -hda <你的镜像>

### debug

加上debug参数的启动命令

	qemu-system-x86_64 -S -s -no-shutdown -no-reboot -m 128M -hda <你的镜像>
	
gdb脚本解读：设置架构-远程链接虚拟机-debug文件-在main函数打断点-显示汇编和寄存器-运行

	set architecture i386:x86-64

   	target remote:1234

   	file build/debug/hello.elf

   	break main
   	layout asm
   	layout regs

   	continue

使用gdb脚本

	gdb -q -x kernel.gdbinit

输入si执行单条汇编指令，观察寄存器变化

# Reference
1. [INT 10H](https://en.wikipedia.org/wiki/INT_10H)
2. [AMD64 Architecture Programmer’s Manual Volume 3: General Purpose and System Instructions](https://developer.amd.com/resources/developer-guides-manuals/)