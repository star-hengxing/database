---
title: "AppImage的使用"
date: 2022-01-29
lastmod: 2021-02-15
draft: false
categories:
    - Linux
tags:
    - Linux
---

## Run

```bash
    cd /path/to/AppImage
    chmod +x xxx.AppImage
    ./xxx.AppImage
```

## Extra icon

```bash
    ./xxx.AppImage --appimage-extract
```

## Desktop Entry

For example:

```bash
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=xxx
    Comment=A cross platform comic client.
    Exec=/home/<user>/Desktop/AppImages/xxx.AppImage
    Icon=/home/<user>/Desktop/AppImages/icons/xxx.png
    Terminal=false
    tags=Game
    X-AppImage-Version=1.0.0

    # Copy the content to xxx.desktop
    mkdir -p ~/.local/share/applications
    touch ~/.local/share/applications/xxx.desktop
```
