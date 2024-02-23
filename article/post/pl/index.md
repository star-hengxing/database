---
title: "多态"
date: 2022-07-25
lastmod: 2022-09-11
draft: false
categories:
    - 编程语言
tags:
    - C++
---

## 起因

在实现我的[离线渲染器](https://github.com/star-hengxing/cpu_offline_renderer/)中，用到了大量oop（其实就是基类然后继承）

我有一个`Shape`基类，里面接口全声明为标准的纯虚函数接口
```C++
virtual TYPE FUNCTION() const = 0;
```
当你继承这个类后，继承类必须实现这个接口，不然编译报错

一开始还没有写实现，但类已经继承了，没办法，在接口开个洞（真难看啊
```C++
virtual TYPE FUNCTION() const {}
```
于是我基于 C++20 标准库的[source_location](https://en.cppreference.com/w/cpp/utility/source_location)写了一个
```C++
[[noreturn]]
inline void unimplemented(const std::source_location location = std::source_location::current())
{
    std::cerr << '\n'
              << '['  << location.file_name()
              << ':'  << location.line()
              << "] " << location.function_name()
              << " unimplemented!\n";
    exit(-1);
}
```
还没有实现接口的时候留下`unimplemented`，然后运行时报错
> `source_location`暂时只有clang不支持（clang对C++20支持太慢了

---

网上冲浪时看到[有人说](https://www.zhihu.com/question/491602524/answer/2166170176)，接口虚函数实现动态多态是一种糟糕实践，优雅的做法是`Existential Type`，在C++社区称为`sean parent polymorphism`

详细可以看这个视频

[John Bandela “Polymorphism != Virtual: Easy, Flexible Runtime Polymorphism Without Inheritance”](https://www.youtube.com/watch?v=PSxo85L2lC0)

[reddit上的关于该视频的讨论](https://www.reddit.com/r/cpp/comments/dguo3h/john_bandela_polymorphism_virtual_easy_flexible/)

## 什么是多态

### 特定多态

[Ad hoc polymorphism](https://en.wikipedia.org/wiki/Ad_hoc_polymorphism)

函数重载，当然运算符重载也一样

### 参数化多态

[Parametric polymorphism](https://en.wikipedia.org/wiki/Parametric_polymorphism)

类似 C++ 的模板，也可以称为泛型

### 子类型多态

[Subtyping](https://en.wikipedia.org/wiki/Subtyping)

平时编程用的最多的，继承基类，调用相同符号的方法

## Existential Type

中文语境下叫**类型擦除/隐藏类型实现**（机翻直译叫存在类型）

看一段 [C++ 代码](https://github.com/IFeelBloated/Type-System-Zoo/blob/master/existential%20type.cxx)
```C++
#include <functional>
#include <vector>
#include <iostream>

// type Messenger = ∃ a. { x: a, Print: a -> string -> ⊥ }
struct Messenger {
    using QuantificationBound = auto(std::string_view)->void;
    std::function<QuantificationBound> f = {};

    Messenger() = default;
    Messenger(auto x) {
        f = [=](auto msg) { x.Print(msg); };
    }

    auto Print(auto msg) const {
        f(msg);
    }
};

struct A {
    auto Print(auto msg) const {
        std::cout << "A says " << msg << std::endl;
    }
};

struct B {
    auto Print(auto msg) const {
        std::cout << "B says " << msg << std::endl;
    }
};

auto main()->int {
    auto x = std::vector<Messenger>{ A{}, B{} };
    for (auto y : x)
        y.Print("hi");
}
```

我觉得有点像上面所说的子类型

在代码中，用`std::function`封装了真正的调用函数，而不需要考虑**具体类型**。`std::function`除了保存函数状态，还有运行时多态。但在不同 stl 的实现，有些是直接用 virtual，有些手动用指针打虚表。虽然看起来底层实现一样，不过好处就是，不需要给类函数加上 virtual，这算是一种**解耦**

但用`std::function`实现其实有一些缺陷，比如将 lambda 函数赋值给它的时候，lambda capture 的变量太多会**动态分配内存**。比较推荐的是用 template

## Reference

1. [Existential type 是什么？](https://www.zhihu.com/question/455347112)
2. [多态都不知道，谈什么对象](https://zhuanlan.zhihu.com/p/165514192)
3. [关于std function和lambda function的性能调试](https://zhuanlan.zhihu.com/p/370563773)