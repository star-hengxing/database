---
title: "使用命令行工具下载在线视频"
date: 2022-01-29
draft: false
tags:
    - 工具
---

## yt-dlp

一个命令行下载youtube视频软件，目前来说就他下载速度还行，其他同类工具被限速了

TL;DR

下载一个视频
```bash
    yt-dlp URL
```

不下载，查看视频下载的信息(选择画质)

```bash
    yt-dlp -F URL

    [BiliBili] 12Q4y1S73g: Downloading webpage
    [BiliBili] 12Q4y1S73g: Downloading video info page
    [info] Available formats for 12Q4y1S73g:
    format code  extension  resolution note
    0            flv        unknown    
    1            flv        unknown    
    2            flv        unknown    295.77MiB (best)
```

## 下载bilibili视频

Bilibili Evolved + aria2 下载视频

Bilibili Evolved提供了几种视频下载方式，我这里选择aria2

启动aria2后，在插件里选择aria2 rpc就可以自动下载视频了