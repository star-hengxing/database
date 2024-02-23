---
title: "编译器优化"
date: 2022-01-29
draft: false
categories:
    - 编译原理
tags:
    - 编译原理
---

在书中2.14节 [1]，看到一个循环遍历的编译器优化，书中给出了用指针和for循环遍历的C代码和对应汇编代码

```C
clear1(int array[], int size)
{
    int i;
    for (int i = 0; i < size; i += 1)
        array[i] = 0;
}

clear2(int* array, int size)
{
    int *p;
    for (p = &array[0]; p < &array[size]; p = p + 1)
        *p = 0;
}
// 书中并无clear3代码
clear3(int* array, int size)
{
    const int *end = &array[size]; // 避免在循环里重复计算
    for (int* p = &array[0]; p < end; p++)
        *p = 0;
}
```

ps: int array[]和int* array在编译器看来都一样；&array[0]和array一样(数组名就是地址)

clear1代码，每次都要根据数组下标进行偏移计算，int是4字节，下标乘于4偏移，整数x4可以优化成左移2位

如果使用指针，循环里的指令就可以减少(不需要根据下标计算偏移量，直接对指针偏移)

用指针实现，虽然效率快，但可读性差，所以这个繁重的工作应该交给编译器

# Reference
1. 计算机组成与设计：硬件软件接口 第五版