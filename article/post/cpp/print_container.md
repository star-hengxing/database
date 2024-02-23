---
title: "一个函数打印STL容器"
date: 2022-01-11
draft: false
tags:
    - C++
---

满足range这个concept就可以使用该函数

```C++
    #include <iostream>
    #include <numeric>
    #include <ranges>
    #include <vector>
    #include <array>

    template <std::ranges::range T>
    void println(const T& args)
    {
        for(const auto& v : args)
        {
            std::cout << v << ' ';
        }
        std::cout << '\n';
    }

    template <std::ranges::range... Ts>
    void print(Ts... args)
    {
        (println(args), ...);
    }

    int main()
    {
        std::array<int, 10> arr;
        std::iota(arr.begin(), arr.end(), 0);

        std::vector<int> vec(10);
        std::iota(vec.begin(), vec.end(), -10);

        print(arr, vec);
    }
```

输出

    0 1 2 3 4 5 6 7 8 9
    -10 -9 -8 -7 -6 -5 -4 -3 -2 -1
