---
title: "使用Synapse自建聊天服务器"
description: "搭建一个私人的im服务器"
date: 2022-01-29
draft: false
tags:
    - 工具
---

我的系统是ArchLinux，所以看着archwiki一路配置比较舒服

其他系统请看[官方文档](https://matrix-org.github.io/synapse/latest/setup/installation.html)

# 从安装到启动

**my.domain.name**替换成自己的域名就行

```bash
    sudo cd /var/lib/synapse
    sudo -u synapse python -m synapse.app.homeserver \
    --server-name my.domain.name \
    --config-path /etc/synapse/homeserver.yaml \
    --generate-config \
    --report-stats=yes
    
    sudo systemctl start synapse.service
    # 服务器至少要有一个用户
    register_new_matrix_user -c /etc/synapse/homeserver.yaml http://127.0.0.1:8008
```

这时候应该就可以用一个matrix client来连接了，这里选择element
