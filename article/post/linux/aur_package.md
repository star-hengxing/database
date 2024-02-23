---
title: "AUR打包记录"
description: "初次打包上AUR"
date: 2022-03-02T10:03:35+08:00
draft: false
categories:
    - Linux
tags:
    - Linux
---

当发现了一个好软件，但aur上没有人打包，这很难受，所以不如自己来为社区做贡献

这次我打的包是一个appimage，理所当然去参考一些现有的appimage打包PKGBUILD

所以先~~设计再编码~~

## PKGBULID编写

1. 下载最新版本的软件到本地
2. 提取appimage，把软件icon放到/usr/share/icons
3. 制作Desktop Entry，放到/usr/share/applications
4. 最后将软件去掉版本号，安装到常见目录（我选择了放在/opt/appimages）

是不是看起来很简单，但由于不熟悉linux和一些常用工具，一顿操作下来，花了半天才写好PKGBUILD。

首先是学会用sed，因为appimage里自带了一个Desktop Entry，所以要进行修改。

其次就是安装到目录的时候需要给权限目录权限，不然复制不进去。

当上游的包没有checksum的时候，还要自己download到本地生成然后加上PKGBULID。当然makepkg然后给了个便利的命令。
```bash
 # 如果有上一个版本的checksum,先用sed删除再执行该命令
 sed -i "$d" PKGBULID
 makepkg -g >> PKGBULID
```

## 测试

写好PKGBULID，检查能不能用。
```bash
# 检查PKGBUILD格式
namcap PKGBUILD
# 生成包
makepkg -s
# 检查包是否缺少依赖等等
namcap xxx.pkg.tar.zst
```
检查包的时候我弹了许多报错，不知道怎么修。然后我去用namcap检查一下我参考的那个appimage包，好家伙，他的报错跟我一样。既然他没修那我也就算了吧。

然后尝试安装
```bash
# 生成.SRCINFO给aur仓库的页面展示，如果第一次提交没有生成，aur仓库会拒绝你的包
makepkg -i && makepkg --printsrcinfo > .SRCINFO
```

## 上传

如果一切没问题，那就可以用git上传aur了（需要一个aur帐号）。

如果会基本的git操作，下面应该都明白怎么操作。
```bash
# 为aur创建ssh key
touch ~/.ssh/config
# 写入这些
Host aur.archlinux.org
    IdentityFile ~/.ssh/aur
    User aur
# 生成
ssh-keygen -f ~/.ssh/aur
# 首先创建一个aur项目
git clone ssh://aur@aur.archlinux.org/<你的包名字>.git
git add PKGBUILD .SRCINFO
git commit -m "init v1.x.x"
git push
```
成功之后呢，你就可以尝试用`paru`/`yay`来下载了。

## Reference

[Arch Linux 第一次打包就上手](https://junyussh.github.io/p/arch-linux-package-quick-start/)
