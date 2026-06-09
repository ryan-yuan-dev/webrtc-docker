# array_view_unittest

## 概述

`array_view_unittest.cc` 是对 `api/array_view.h` 中 `ArrayView<T>` 类的单元测试文件。`ArrayView` 是 WebRTC 中一种轻量级的非拥有视图类型，类似 `absl::Span`，用于在不传输所有权的情况下传递数组或连续内存的子区间。

## 测试范围

- 默认构造（空 view）
- 从 `std::vector`、`std::array`、C 风格数组构造
- `subview` / `subview` 获取子区间
- `data()`、`size()`、`empty()`、`begin()` / `end()` 迭代器
- `operator[]` 下标访问
- 常量性和可变性
- 从 `rtc::Buffer`、`CopyOnWriteBuffer` 等 WebRTC 特有类型构造
- 与 `std::vector` 的隐式转换
- 类型擦除（如 `ArrayView<int>` 转换为 `ArrayView<const int>`）
