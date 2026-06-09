# function_view_unittest

## 概述

`function_view_unittest.cc` 是对 `api/function_view.h` 中 `FunctionView<T>` 类的单元测试文件。`FunctionView` 是 WebRTC 中一种轻量级的非拥有函数包装器，类似 `absl::FunctionRef`，用于在不分配内存的情况下传递可调用对象。

## 测试范围

- 默认构造（空 FunctionView）
- 从自由函数构造
- 从 lambda 表达式构造
- 从 `std::function` 构造
- 空检查（`operator bool`）
- 调用语义
- 参数传递和返回值
- 与 `absl::AnyInvocable` 的交互
- 生命周期安全性（仅引用，不持有所指对象）
- 移动语义
