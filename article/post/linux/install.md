---
title: "记录安装arch的过程"
description: "虚拟机和物理机都装了一次"
date: 2021-08-02
draft: false
categories:
    - Linux
tags:
    - Linux
---

## 配置
* 虚拟机: Oracle VM VirtualBox
* 笔记本：UEFI启动
* 镜像: [官网](https://archlinux.org/download/)

## 前提
* 了解UEFI还是BIOS启动，不同的启动方式对应不同的步骤
* 基本的linux命令行操作和知识
* 足够耐心
* 善用archwiki

## 安装

### 联网
wifi配置麻烦，强烈建议网线或者手机usb联网

```bash
    ip link
```

然后ping查看联网是否成功

```bash
    ping baidu.com
```

### 更新系统时间

```bash
    timedatectl set-ntp true
    timedatectl status # 检查服务状态
```

### 硬盘分区
硬盘分区工具有很多，推荐小白使用`cfdisk`

查看硬盘用`lsblk`

在分区前，需了解swap(分区)，区别linux根分区和windows盘符的概念

如果是UEFI启动，需要分一个EFI区，而BIOS则不用

分区步骤大概就是：new->分大小->改类型->保存->格式化->挂载

**EFI分区和正常分区格式化工具不一样**

**根分区需要首先挂载**

swap区看需求分(格式化和挂载是单独命令使用)

### 添加国内镜像加速

```bash
    vim /etc/pacman.d/mirrorlist
    # 添加
    Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
    Server = https://mirrors.zju.edu.cn/archlinux/$repo/os/$arch
```

### 安装基本包

```bash
    pacstrap /mnt base linux linux-firmware
```

在此步骤可以考虑把常用软件装了(vim/networkmanager/sudo)

### 配置Fstab

```bash
    genfstab -U /mnt >> /mnt/etc/fstab
    cat /mnt/etc/fstab # 检查
```

### change root

切换到自己系统

```bash
    arch-chroot /mnt
```

### 设置时区

```bash
    # Asia和Shanghai按需替换
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc
```

###  设置Locale

```bash
    # 把需要用的注释取消
    vim /etc/locale.gen
    # 当前使用的locale
    echo LANG=en_US.UTF-8 >> /etc/locale.conf
    # 初始化
    locale-gen
```

### 设置root密码

```bash
    passwd # 密码不回显
```

### 网络配置

```bash
    # myhostname替换自己主机名
    echo myhostname >> /etc/hostname
    vim /etc/hosts

    添加  
    127.0.0.1	localhost  
    ::1		    localhost  
    127.0.1.1	myhostname.localdomain	myhostname # 主机名.本地域名 主机名
```

### 安装引导程序

* grub
* [不使用grub启动](https://zhuanlan.zhihu.com/p/113615452)

ps:用这个方法前，假如你是intel-cpu，需要先安装intel-ucode

```bash
    bootctl install
    # 添加
    vim /boot/loader/loader.conf
    default arch
    timeout 4
    # 添加
    vim /boot/loader/entries/arch.conf
    title   Arch Linux
    linux   /vmlinuz-linux
    initrd  /intel-ucode.img
    initrd  /initramfs-linux.img
    options root=根分区路径 rw # 例如/dev/sda2
```

### 重新启动

```bash
    exit
    poweroff/reboot
```

拔掉u盘，等待弹出tty终端，要求输入账户密码登录

因为我是UEFI引导，所以笔记本需要更改启动方式为UEFI，而不使用BIOS，

# Reference
1. [以官方Wiki的方式安装ArchLinux](https://www.viseator.com/2017/05/17/arch_install/)