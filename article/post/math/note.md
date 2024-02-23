---
title: "数学速查表"
date: 2022-09-04
lastmod: 2022-09-04
draft: true
mathjax: true
tags:
    - 数学
---

## 点乘

$$
\vec{A} \cdot \vec{B} = \lVert A \rVert \lVert B \rVert \cos \theta
$$

如果两个向量已经**归一化**，那么点乘结果直接是 $\cos \theta$，因为向量模长均为1

## 旋转

### 二维

即已知向量 $\vec{OA} : (x_{1},y_{1})$ 和旋转角度 $\theta$，求旋转后向量 $\vec{OB} : (x_{2},y_{2})$

设 $\vec{OA}$ 的长度为 r，$\vec{OA}$ 和 $\vec{OB}$ 与 x 轴的夹角分别为 $\alpha$ 和 $\beta$，$\beta = \alpha + \theta$

则 $\vec{OA}$ 和 $\vec{OB}$ 的极坐标形式分别为：

$$
\vec{OA}(r\cos \alpha, r\sin \alpha) \\
\vec{OB}(r\cos \beta,r\sin \beta)
$$

$
\begin{cases}
r\cos \beta &= r\cos (\alpha+\theta) &= r(cos \alpha cos \theta -sin \alpha sin \theta) &= rcos \alpha cos \theta - rsin \alpha sin \theta \\
r\sin \beta &= r\sin(\alpha+\theta) &= r(sin\alpha cos \theta +cos \alpha sin \theta) &= rsin \alpha cos \theta + rcos\alpha sin \theta
\end{cases}
$

将
$
\begin{cases}
x_{1} &= r\cos\alpha \\
y_{1} &= r\sin\alpha \\
x_{2} &= r\cos\beta \\
y_{2} &= r\sin\beta \end{cases}
$
代入上式，则
$
\begin{cases}
x_{2} &= x_{1}cos\theta - y_{1}sin\theta \\
y_{2} &= x_{1}sin\theta + y_{1}cos\theta
\end{cases}
$