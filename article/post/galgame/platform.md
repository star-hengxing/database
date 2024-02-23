---
title: "如何在Linux和Windows上优雅地玩galgame"
date: 2022-05-09
lastmod: 2022-05-15
draft: false
categories:
    - Galgame
---

## Windows10

提高游戏分辨率 -> [Magpie](https://github.com/Blinue/Magpie)

统计游戏时长兼启动器 -> [Etupirka](https://github.com/Aixile/Etupirka)

用手柄玩galgame -> [Steam Controller](https://store.steampowered.com/app/353370/Steam_Controller/)

现在你获得了一个很好的体验，启动`Etupirka`，然后选中想玩的galgame，绑定`Magpie`的快捷键到手柄上，对游戏全屏，我一个Quick load，可以继续用手柄摇杆推线咯

## Linux

一个坏消息，大部分黄油开发者根本没想过Linux平台

一个好消息，steam的`Proton`可以帮助我们玩到Windows上的galgame(感谢V社)

首先在Linux上下载steam，然后添加非steam游戏，游戏设置使用Proton，然后你就可以~~启动游戏啦~~

但实际上只有少部分黄油能打开，就算能打开还一定会伴随bug
- 能打开的游戏没见过能播放op
- 传言有些游戏要对应Proton版本才能打开
- 游戏能打开，但bug太致命完全打不了
- 我超，汉化补丁能打开生肉却打不开，但我想全都要怎么办

游戏打不开怎么办，乱试一下吧
1. 游戏路径全ascii且不留空格(游戏目录也算路径)
2. [参考这篇文章](https://blacksand.top/2021/08/25/%E8%AE%A9Galgame%E5%9C%A8ArchLinux%E9%80%9A%E8%BF%87Wine%E6%AD%A3%E7%A1%AE%E8%BF%90%E8%A1%8C)

能用Proton直接打开基本无bug游玩是最好的，如果要折腾很久才能玩我觉得真的没必要，不如用回Windows或者虚拟机(两台以上电脑是Linux用户的最优解)

先列个能打开的黄油名单在这吧，排排坑

|名字|Pronton版本|体验|
|---|---|---|
|放課後シンデレラ|7.0|非常好，没遇到坑|
|はつゆきさくら|7.0|播放序章op闪退了一次，再打开会提示你要不要播放op，能流畅游玩|
|いきなりサキュバス ～いちゃらぶ搾精ライフ～|7.0|没完整打完，暂时无bug|
|白昼夢の青写真|7.0|黑屏bug，如果不是一直渲染的画面就会黑屏，比如显示文字的时候，文字外的全黑|

有群友推荐`lutris`和`proton-ge`，还未研究
