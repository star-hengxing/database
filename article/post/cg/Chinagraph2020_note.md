---
title: "Chinagraph2020会前课程 真实感图形渲染科研入门 随手记录"
date: 2022-05-04
draft: false
mathjax: true
categories:
    - 计算机图形学
---

录播：[Chinagraph2020](https://www.bilibili.com/video/BV1my4y1z76s)

## 论文推荐

[真实感图形渲染科研入门笔记（一）：论文推荐](https://zhuanlan.zhihu.com/p/267368385)

## 工具链与参考资料

[真实感图形渲染科研入门笔记（二）：工具链与参考资料](https://zhuanlan.zhihu.com/p/268902385)

## 迈向科研的训练

### 离线

1. 用Intel的Embree写一个光线追踪器
2. 使用多重重要性采样
3. 支持微表面材质
4. 实现一个正确的BDPT

95%做渲染的科研人员都没写对BDPT(太难了)

检验：和PT的结果比较

### 实时

1. 用C++封装OpenGL
2. 支持arcball(能用鼠标拖拽的一个球，里面的物体一起动起来)，写一个VSSM
3. 使用Optix和OpenGL实现RTRT
4. 使用SVGF降噪

## 未来

材质外观的研究才刚刚开始

现在用的基本这两种
1. diffuse + microfacet
2. 迪士尼原则BRDF

尽管实现很简单，但第一种对真实感渲染错的离谱

人脸的渲染也没有好的正向模型
