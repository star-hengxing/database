---
title: "Linux配置"
description: "基本配置/图形界面/常用软件"
date: 2022-01-29
lastmod: 2022-05-16
draft: false
categories:
    - Linux
tags:
    - Linux
---

## 基本软件

|工具|名字|
|---|---|
|display manager|lightdm|
|desktop environment|xfce4|
|文本编辑器|vscode/vim/emacs|
|程序启动器|rofi|
|输入法|fcitx5|
|browser|microsoft-edge-dev(AUR)|
|多线程下载|aria2|
|压缩包解压/查看|ark|
|proxy|clash for window(AUR)|
|RSS|fluent-reader|
|shell|zsh|
|PDF|zathura|

## 命令行软件

|描述|名字|
|---|---|
|显示目录大小|ncdu|
|高级版top|gotop(AUR)/htop|
|打印彩色的十六进制|hexyl|
|语法高亮和行号的cat+less|bat|
|统计目录代码量|loc|
|文件浏览器|ranger|
|比tmux更好用的单窗口多终端|zellij|

## 新建用户

```bash
    useradd -m -G wheel username
    passwd username
    ln -s /usr/bin/vim /usr/bin/vi
    visudo
```

找到`# %wheel ALL=(ALL)ALL`取消注释

## 硬件

### 网卡

万物起源先上网，但有些网卡需要手动装驱动(比如我笔记本的博通网卡)

```bash
    sudo pacman -S linux-headers broadcom-wl-dkms
    reboot
    dkms status
```

### 声卡

```bash
    sudo pacman -S alsa-utils pulseaudio-alsa
```

### 蓝牙

```bash
    sudo pacman -S bluez bluez-utils

    /etc/bluetooth/main.conf

    [Policy]
    AutoEnable=true # 开机自启
```

## 联网

启动之前安装的[NetworkManager](https://wiki.archlinux.org/title/NetworkManager)

```bash
    systemctl enable NetworkManager
```

## 图形界面

```bash
    sudo pacman -S xf86-video-intel
    sudo pacman -S xorg
    sudo pacman -S xfce4 xfce4-goodies
    sudo pacman -S lightdm lightdm-gtk-greeter
    sudo systemctl enable lightdm
```

## AUR

```bash
    sudo pacman -S paru 
```

## bash

```bash
    sudo pacman -S zsh
    sudo chsh -s /bin/zsh username
```

## 中文字体/输入法

```bash
    sudo pacman -S fcitx5-im fcitx5-chinese-addons fcitx5-rime
```

## 下载

```bash
    sudo pacman -S aria2
    # web前端(还有很多前端可供挑选)
    paru ariang-allinone
    # copy 大佬的配置
    git clone https://github.com/P3TERX/aria2.conf
    mkdir ~/.aria2
    mv aria2.conf ~/.aria2/
    touch ~/.aria2/aria2.session
```

* 看aria2.conf注释配置路径
* 看[wiki](https://wiki.archlinux.org/title/Aria2)配置开机自启

# Reference
1. [Arch Linux 安装使用教程 - ArchTutorial - Arch Linux Studio ](https://archlinuxstudio.github.io/ArchLinuxTutorial/)
