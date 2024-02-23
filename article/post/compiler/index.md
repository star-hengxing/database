---
title: "从代码到程序"
date: 2022-05-29
draft: false
categories:
    - 编译原理
tags:
    - 编译原理
---

随手记录的一些编译原理笔记。

---

现代编译器分为前后端，为了进一步降低复杂度(模块化)，前端的流程通常是：
```
词法分析 -> 语法分析 -> 语义分析
```

上一步的输出是下一步的输入。

## 词法分析

常见的应用有正则表达式。

先定义一个映射， tokens = map(字符串)

这个`token`是啥呢，比如说我有下面这个算式：
```
1 + 2 * ３
```
解析后：

|值|类型|
|---|---|
|１|整数|
|+|加号|
|2|整数|
|*|乘号|
|3|整数|

我们暂时不知道有什么用，但现在我们解决了字符串里的**空格**，如果字符串里有奇怪的字符，比如`#`啥的，也可以报错。

怎么解析其实也是个大问题，通常用**自动机**解决这个问题。

## 语法分析

把词法分析输出的一堆token，组合成句子，检查句子的语法，最后生成**抽象语法树(AST)**

AST用处广泛，比如：

- 编辑器错误提示
- 代码格式化
- 代码高亮
- 代码自动补全