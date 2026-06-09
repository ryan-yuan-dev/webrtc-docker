# audio_view_unittest

## 概述

`audio_view_unittest` 是 `audio_view` 模块（MonoView / InterleavedView / DeinterleavedView）的单元测试文件，使用 Google Test 框架，验证三类音频视图的构造、属性访问、数据存取、声道操作和辅助函数。

## 测试用例

| 测试名 | 验证内容 |
|--------|----------|
| `MonoView` | 构造 MonoView、属性访问（size、NumChannels、SamplesPerChannel、IsMono）、const 版本构造、索引访问 |
| `InterleavedView` | 不同声道数的 InterleavedView 构造、C-style 数组构造、迭代器遍历、const 版本构造与赋值、NumChannels / IsMono / SamplesPerChannel |
| `DeinterleavedView` | 连续 buffer 构造、指针数组构造、声道访问（operator[]）、AsMono()、const 版本构造与赋值、多声道交错内存布局验证 |
| `CopySamples` | 在 InterleavedView 之间拷贝数据，验证目标 buffer 内容与源一致 |
| `ClearSamples` | 单通道 int16/float buffer 清零、指定数量清零 |
| `DeinterleavedViewPointerArray` | 使用 `std::vector<float*>` 和 `float* []` 数组构造 DeinterleavedView，验证各声道指针正确性 |

## 关键验证点

- **视图语义一致性**：`IsMono(mono_view)` 始终返回 true；`IsMono(interleaved_view)` 仅在声道数为 1 时返回 true。
- **内存布局**：DeinterleavedView 中第二声道起始位置在 `&arr[samples_per_channel]`，验证了连续排列假设。
- **CopySamples**：同时对源和目标进行 isInterleaved 的一致性校验。
- **ClearSamples 部分清零**：前一半清零、后一半保持不变的正确性。
