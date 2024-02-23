---
title: "并行前缀和"
date: 2022-11-18
draft: true
tags:
    - CUDA
---

应用：在连续无序序列内，取某个范围内的和。

## CPU

### Serial

串行的算法非常简单，代码看一眼就能懂。

```C++
template <typename T>
auto serial_scan(T* output, const T* input, usize size)
{
    output[0] = input[0];

    for (auto i : range(1, size))
    {
        output[i] = output[i - 1] + input[i];
    }
}
```

### Parallel

串行算法每一步都依赖上一步，不可能直接并行，所以需要换一个并行算法。

这里分三步：

1. 分块求前缀和

假如有连续序列 {1, 2, 3, 4, 5, 6}，分块，求前缀和。

{1, 2, 3, 4, 5, 6} -> {1, 2, 3}，{4, 5, 6}

{1, 2, 3}，{4, 5, 6}  
{1, `3`, `6`}，{4, `9`, `15`}

2. 将所有块**最后一个元素**组成一组新的序列，求前缀和。

{1, 3, `6`}，{4, 9, `15`} -> {6, 15} -> {6, `21`}

1. 除了第一块，对块进行遍历，每个元素加上前一个块的**最后一个元素**（当前块的**最后一个元素**不需要操作）

{1, 3, 6}，{4, 9, 21}  
{1, 3, 6}，{4 + `6`, 9 + `6`, 21}  
{1, 3, 6}，{`10`, `15`, 21}

结果：

{1, 3, 6, 10, 15, 21}

---

实际上编写代码的时候有很多细节，比如分块怎么做，因为是在 CPU 上并行，所以就直接拿核心数分块，这也是常见的做法。

考虑数据量不是2的幂的时候，避免越界操作。

```C++
const auto thread_size = omp_get_num_procs();
auto per = size / thread_size;
if (thread_size * per < size)
{
    per += 1;
}
```

如果只想测试算法正确性，可以注释 openmp 的语句。

完整算法代码：
```C++
template <typename T>
auto parallel_scan(T* output, const T* input, usize size)
{
    const auto thread_size = omp_get_num_procs();
    auto per = size / thread_size;
    if (thread_size * per < size)
    {
        per += 1;
    }

#pragma omp parallel for num_threads(thread_size)
    // for (auto i : range(thread_size))
    for (int i = 0; i < thread_size; i += 1)
    {
        const auto start = i * per;
        auto end = (i + 1) * per;
        if (end > size)
            end = size;

        output[start] = input[start];
        for (auto j : range(start + 1, end))
        {
            output[j] = output[j - 1] + input[j];
        }
    }

    for (auto i : range(2, thread_size))
    {
        output[i * per - 1] += output[(i - 1) * per - 1];
    }
    output[size - 1] += output[(thread_size - 1) * per - 1];

#pragma omp parallel for num_threads(thread_size - 1)
    // for (auto i : range(1, thread_size))
    for (int i = 1; i < thread_size; i += 1)
    {
        const auto start = i * per;
        auto end = (i + 1) * per;
        if (end > size - 1)
            end = size;

        const auto n = output[i * per - 1];
        for (auto j : range(start, end - 1))
        {
            output[j] += n;
        }
    }
}
```

## GPU

这里使用 CUDA 进行 GPGPU 编程。
