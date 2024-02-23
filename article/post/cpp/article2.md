---
title: "C++ 胡言乱语X2"
date: 2023-02-25
draft: false
tags:
    - C++
---

子标题：理解 std::move 和所有权。

## 前言

关于 std::move 其实也有很多文章了，不过为了给群友解释，再造一次轮子。

## std::move

我们打开 std::move 的实现，发现里面是一个强制类型转换（随便找的代码）。

```cpp
template <typename T>
typename remove_reference<T>::type&& move(T&& arg)
{
    return static_cast<typename remove_reference<T>::type&&>(arg);
}
```

使用：
```cpp
Object A;
Object B = std::move(A);
```

这右值有啥用啊？假设 Object 类有以下构造函数：

```cpp
// 函数1
Object(const Object& object);
// 函数2
Object(Object&& object);
```

如果没有`std::move(A)`这一步，那么B将会调用函数1进行构造，反之调用函数2。

但分开两个构造函数是干什么呢，这里就牵涉到一个资源分配和所有权问题。

## 所有权

假如你是A，你从宠物商店买了一只仓鼠回来（仓鼠挺可爱的），那你就成为了这只仓鼠的主人。

B是你的好朋友，他经常到你家玩。他觉得你的仓鼠很可爱，于是他也想买一只，但是他没有足够的钱。

- 分支路线1：

可是突然有一天，你不想养这只仓鼠了，就想找个人帮你继续养下去。你知道B也想养一只属于自己的仓鼠，但没有钱去买。于是你找来了B，将仓鼠送给了他。

那么B从这天起，就成为了仓鼠的第二任主人了。

- 分支路线2：

有一天B打工赚了许多钱，于是他去问你这只仓鼠是什么品种，然后自己到宠物商店买了一只差不多一样的。

现在又有一只小仓鼠找到了新家了。

---

回到主题，在上面，抽象来讲，买了一只仓鼠，其实就是分配了一个资源，你就拥有了他的使用权（所有权）。

分支路线1中，A把仓鼠送给了B，这就是转移了仓鼠的所有权，主人从A变成了B，对应`Object(Object&& object)`。

分支路线2中，B也买了一只仓鼠，这样两只仓鼠，都有了各自的主人，对应`Object(const Object& object)`。

要知道买一只新仓鼠是要花钱的，所以在某些场景用 std::move 来节省这个**资源**的开销。

但仓鼠毕竟是别人养过的，想要一只**独一无二属于**自己的小仓鼠，那就买一只新的吧，所以就需要申请一份**新的资源**。

## 后记

理解所有权后，就像学数据结构学会了链表。学习新的知识，第一步总是最难的。