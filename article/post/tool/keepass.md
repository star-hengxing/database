---
title: "使用KeePass作为密码管理器"
date: 2022-06-27
draft: false
tags:
    - 工具
---

最近超星学习通数据泄露大家应该都知道吧，全国上下学生很多都依赖这么一个中心化的网课平台。而且学习通可能还是**明文存储密码**，这下坏事了，直接撞库

> 撞库攻击是网络犯罪分子试图使用一组帐密同时访问多个帐户

我很久以前就知道有密码管理器的存在，但我是懒鬼，所以没弄过。这次事件提醒了我，还是别偷懒了（

## Getting started

KeePass是什么呢

> KeePass is an encrypted password database format. It is an alternative to online password managers and is supported on all major platforms.

我这里推荐使用跨平台的**KeePassXC**客户端，原始KeePass客户端实在太丑陋了

下载客户端后，新建数据库需要一个**主密码**，这个密码需要你记忆

我们先来看一个图，来自[xkcd](https://xkcd.com/936/)
![密码强度](https://xkcd.in/resources/compiled_cn/d4a068052cf9c7255c0b4c4643ac0b5b.jpg)

那如何根据上图思路创建一个好密码呢，这里可以看一下[diceware](https://theworld.com/~reinhold/diceware.html)的方法

这个网站根据diceware方法提供[在线生成随机英语单词](https://diceware.dmuth.org/)

如果想要生成随机中文词语，可以在此网页找到
[使用diceware构造好的密码](https://pincong.rocks/article/5582)

创建好数据库后，保存在本地随便一个目录，然后我们去**KeePassXC**设置面板开启浏览器集成，下载对应浏览器插件

> 浏览器插件启动后需要连接**KeePassXC**客户端

在网站登录页面，如果数据库里没有对应网站url或者已存在，会提示你为该网站`新建/更新`账号密码。如果没有提示，可以手动使用插件，或者直接在**KeePassXC**客户端手动录入

**KeePassXC**里随手就可以生成一个密码，无论是大小写字母数字还是各种特殊符号。如果想使用密码，`Ctrl-C`会自动复制到你剪切板上，然后在10秒后清除

如果手机也要密码管理，安卓客户端可以在**f-droid**上下载**keepassdx**

## 同步

所有信息都在keepass创建的数据库里，这里可以使用一些文件传输软件进行备份同步，或者存github也没啥问题