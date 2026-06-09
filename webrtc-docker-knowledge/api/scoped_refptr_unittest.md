# scoped_refptr_unittest

## 概述

`scoped_refptr_unittest.cc` 是对 `api/scoped_refptr.h` 中 `scoped_refptr<T>` 智能指针类的单元测试文件。`scoped_refptr` 是 WebRTC 中用于引用计数对象管理的智能指针，类似 `std::shared_ptr`，但基于侵入式引用计数（要求 T 实现 AddRef/Release 方法）。

## 测试范围

- 默认构造（空指针）
- 从原始指针构造
- `scoped_refptr` 的拷贝和赋值
- 引用计数正确性（AddRef/Release 调用次数）
- `get()` / `operator->` / `operator*` 解引用
- `operator bool` 空检查
- `reset()` 重置
- 移动语义
- 类型转换（派生类到基类）
- 线程安全考量
- `scoped_refptr` 与弱引用的交互
