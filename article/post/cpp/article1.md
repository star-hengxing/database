---
title: "C++ 胡言乱语X1"
date: 2022-09-19
draft: false
tags:
    - C++
---

## 某些 STL 容器

在刷 leetcode，其中某道题中的代码片段是这样的

```C++
string res;
res.resize(size - i);
// res.reserve(size - i);

for (int j = 0; i < size; i += 1, j += 1)
{
    res[j] = arr[i] + '0';
    // res.push_back(arr[i] + '0');
}
```

没注释的代码比注释的快了几ms，原因如下

因为容器一开始是空的，不需要考虑拷贝原来的元素
1. resize 重新分配内存并且默认初始化，size 改变（大概开销 malloc + memset）
2. reserve 重新分配了内存，不初始化，size 不变
3. push_back 需要检查 size 有没有大于 capacity，多了分支的开销

然而这里代码也不是最快的，思考一下，这里 resize 还多了一个 memset 的开销，所以最优解应该是，用自己写的 vector（逃

不知道是历史原因还是标准委员会根本没考虑到，应该加多几个函数来表示需不需要初始化

## 改造容器

这里先看一个别人家的 vector：[Less](https://github.com/cmazakas/less/)

看一下某个代码片段
```C++
struct default_init_t {};
inline constexpr default_init_t default_init;

struct with_capacity_t {};
inline constexpr with_capacity_t with_capacity;

vector(default_init_t, size_type const size)
{
 this->construct(size, size, [](auto p, auto) { new (p, placement_tag) T; });
}

vector(size_type size)
{
 this->construct(size, size,
                 [](auto p, auto) { new (p, placement_tag) T(); });
}

vector(with_capacity_t, size_type const capacity)
{
 this->construct(0u, capacity, [](auto, auto) {});
}

vector(size_type size, T const& value)
{
 this->construct(size, size,
                 [&](auto p, auto) { new (p, placement_tag) T(value); });
}
```

思考🤔，直接把一个结构体类型作为参数？算了直接去 c++ 群问一下

哦，原来这个叫`tag dispatch`，才发现这语法在（MSVC STL）到处都是，感觉不如多写个 make 系列函数，而不是重载构造函数

我觉得更好的实践应该是：

```C++
// 分配内存，size 改变，默认初始化
static vector<T> make_default_init(std::size_t size, const T& val = T{});
// 分配内存，size 改变，不进行初始化
static vector<T> make_default_without_init(std::size_t size);
// 分配内存，size 不变，不进行初始化
static vector<T> make_with_capacity(std::size_t size);
// 重新分配内存，size 改变，不进行初始化
void resize_without_init(std::size_t size);
```

---

这个库还有个设计是，抛弃 std::allocator，使用自定义 new 和 delete

std::allocator 这玩意设计有误，扔掉很正常，至于为什么，看[这个](https://www.zhihu.com/question/50997867/answer/2212678027)

## 自增运算符

在最上面的代码，里面自增1都是使用`+=`，这是好的代码风格

有时候你会看见这种代码：`++array[index++]`

前缀/后缀自增运算符赶紧死一死，后出世的语言基本都没有`++`这个语法了

更让我觉得恶心的是，群友在 AMD 的笔试说考`i+++++i`这种题，就算是外企我也想开喷：中国本土化了这是，真接“谭教授”的地气啊

别说能考你 体系结构/操作系统/编译器 的知识，首先有一个大前提就是，[ub](https://en.cppreference.com/w/cpp/language/ub) 不能拿来做题目